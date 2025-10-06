@def title = "Differentiate the log-determinant of a matrix on GPU using Zygote.jl"
@def published = "19 May 2023"
@def tags = ["machine-learning", "automatic-differentiation", "julia", "linear-algebra"]


## Differentiate the log-determinant of a matrix on GPU using Zygote.jl
### Log-determinant in a computational graph

Does the computation of log-determinant of a matrix ever occur in the computational graph of a neural network?

Surprisingly, it does. This arises in the context of Sparse Variational Gaussian Process (SVGP).

In SVGP, our goal is to maximize a quantity known as the evidence lower bound (ELBO). The ELBO comprises of two terms, which basically says:
$$ \begin{align*}
    \text{ELBO} = \text{expected log likelihood term} - \text{KL divergence term}
    \end{align*}
$$

One could check, e.g. [Wei Yi's excellent tutorial](https://towardsdatascience.com/sparse-and-variational-gaussian-process-what-to-do-when-data-is-large-2d3959f430e7) or James Hensman's [Gaussian Process for big data](https://arxiv.org/pdf/1309.6835.pdf) for the derivation of ELBO for SVGP. In short, the KL divergence term in ELBO is expressed as:

$$ \begin{align*}
    \text{KL divergence term in ELBO} = {\color{grey}\frac{1}{2}\bigg[}\log\frac{1}{\det\Sigma} + {\color{grey}n + \mu\top\mu + \text{trace}(\Sigma)\bigg]}
    \end{align*}
$$

($\mu$ and $\Sigma$ are mean and covariance of a variational distribution, and they are part of the model parameters in SVGP) In this context, we will disregard the grey terms as they are easily handled by Zygote.

### Differentiate the log-determinant of a matrix using Zygote.jl

When $\Sigma$ is stored in CPU memory, the term $\log\det\Sigma$ involving the (positive definite) matrix $\Sigma$ works fine with Zygote.

```
using Zygote
X = randn(3,3); XᵀX = X'X
f(x) = logdet(x)
@show gradient(f, XᵀX)[1]
```
This gives:
```
(gradient(f, XᵀX))[1] = [0.8429186329377117 -0.4507909324777994 -0.7811665008998808; -0.45079093247779933 0.48173303692414393 0.47267755816965557; -0.7811665008998809 0.4726775581696556 1.261152638854635]
```

But interestingly, it does not work at all when $\Sigma$ is stored in GPU memory.

```julia:./logdet_gpu.jl
using CUDA
CUDA.allowscalar(false)
@show gradient(f, cu(XᵀX))[1]
```
This will return:

`
Error: Scalar indexing is disallowed.
`


Let's try to get around this, using the [Cholesky decomposition to calculate the log determinant](https://blogs.sas.com/content/iml/2012/10/31/compute-the-log-determinant-of-a-matrix.html) of $\Sigma$:


```
cholesky_log_det(X) = begin
    C = cholesky(X)
    return 2*sum(log.(diag(C.L)))
end
@show gradient(cholesky_log_det, cu(XᵀX))[1]
```
But this again gives:

`
Error: Scalar indexing is disallowed.
`

### Customized adjoint to the rescue

It turns out that [the derivative of the log-determinant of a matrix has a very simple formula](https://statisticaloddsandends.wordpress.com/2018/05/24/derivative-of-log-det-x/), i.e., for an invertible matrix $Z$, we have that 

$$ \begin{align*}
    (\log\det Z)' = Z⁻ᵀ
    \end{align*}
$$
Using this handy fact, let's go ahead and [make a customized adjoint](https://fluxml.ai/Zygote.jl/stable/adjoints/):

```
using Zygote: @adjoint

function log_determinant(Q::CuMatrix)
    A = cholesky(Q)
    return 2*sum(log.(diag(A.L)))
end

@adjoint function log_determinant(Q::CuMatrix)
    # Q positive definite so Q = LLᵀ by cholesky and thus Q⁻¹ = L⁻ᵀL⁻¹
    # numerically stable way to invert a covariance matrix: https://mathoverflow.net/questions/9001/inverting-a-covariance-matrix-numerically-stable
    A = cholesky(Q)
    L_inv = inv(A.L)
    A_inv = L_inv'L_inv  
    return 2*sum(log.(diag(A.L))), △ -> (△ * A_inv', )
end

@show gradient(log_determinant, cu(XᵀX))[1]
```
And now we have:
```
(gradient(log_determinant, cu(XᵀX)))[1] = Float32[0.8429185 -0.4507908 -0.78116626; -0.4507908 0.48173293 0.4726774; -0.78116626 0.4726774 1.2611524]
```

This works. A quick check with the CPU version's result shows that our adjoint is returning the correct gradient of the log determinant of $\Sigma$.

A side note: You may have noticed the line `L_inv = inv(A.L)`. Indeed, the inversion of a triangular matrix `A.L` still has quadratic time complexity, which is pretty darn slow for big matricies. Fortunately, in SVGP, the matrix $\Sigma$, i.e. the input matrix `Q` above is defined using what's called the "inducing points", which makes `Q` small. And because the inducing points is part of the model parameter of SVGP, you actually get to control the size of $\Sigma$.

An adjoint example is [here](https://discourse.julialang.org/t/zygote-meaning-of-adjoint-add-a-b-add-a-b/36707/4) by Pbellive.

Note: This post is done on Zygote version 0.6.61 and Julia version 1.9.

----------------
update: 4/4/2024

The following code using `ChainRulesCore` produces the same result.

```
function log_determinant(Q::CuMatrix)
    A = cholesky(Q)
    return 2*sum(log.(diag(A.L)))
end

function ChainRulesCore.rrule(::typeof(log_determinant), Q::CuMatrix)
    A = cholesky(Q)
    L_inv = inv(A.L)
    A_inv = L_inv' * L_inv
    function log_determinant_pullback(R̄)
        f̄ = NoTangent()
        Q̄ = R̄ * A_inv'
        return f̄, Q̄
    end
    return 2*sum(log.(diag(A.L))), log_determinant_pullback
end
```
