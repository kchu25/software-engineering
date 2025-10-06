@def title = "Soft-thresholding operator with [0,1] constraint"
@def published = "12 March 2024"
@def tags = ["optimization"]

### Proximal gradient descent
I often forget how to derive proximal gradient descent. So here we go.

Proximal gradient descent is for solving the problem of this form:


$$\min_{\zbm} f(\zbm)+g(\zbm)$$

where $f$ is a differentiable but $g$ is not.
The idea of proximal operator is to do a quadratic approximation of $f$ at some point $\xbm$ and solve that with $g$. We replace the hessian $\nabla^2 f$ by $\frac{1}{\eta}I$. We want to solve:
$$ \begin{align*}
    &\argmin_{\zbm}\, f(\xbm)+\nabla f(\xbm)^T(\zbm-\xbm)+\frac{1}{2\eta}\|\zbm-\xbm\|^2_2 + g(\zbm)\\
    =&\argmin_{\zbm}\, \frac{1}{2\eta}\|\zbm-(\xbm-\eta\nabla f(\xbm))\|^2_2 + g(\zbm)
   \end{align*}
$$

The proximal operator $\text{prox}_{g,\eta}(\zbm)$ is defined as the following:
$$
\text{prox}_{g,\eta}(\xbm) = \argmin_{\zbm} \frac{1}{2\eta}\|\zbm - \xbm\|^2_2 + g(\zbm)
$$
And proximal gradient descent is done by choosing an initial point $\xbm^{(0)}$ and execute the following iterative procedure:
$$
\xbm^{(k)} = \text{prox}_{g,\eta^k}(\xbm^{(k-1)}-\eta^k\nabla f(\xbm^{(k-1)})),\quad k=1,2,3...
$$

There are many theoretical properties to show that this basically behaves like gradient descent. I'd skip that for now.

### Soft-thresholding operator with [0,1] constraint

The problem I'm interested in is 
$$\min_{\zbm} f(\zbm)+g(\zbm)$$
where $f(\zbm)=\frac{1}{2}\|\Abm\zbm-\bbm\|^2_2$ and $g(\zbm)=\lambda\|\zbm\|_1+\Pi(\zbm)$. Here $\Pi$ is an indicator function on $[0,1]^n$ hypercube that returns $\infty$ if any $(z_1,...,z_n)$ falls outside of it.

One can see that the proximal operator for this is

$$\zbm^{k+1}=\text{prox}_{g,\eta^k}(\zbm^k-\Abm^T(\Abm\zbm^k-\bbm))$$
and the problem is 
$$\begin{align*}
\text{prox}_{g,\eta}(\xbm)&=\argmin_{\zbm}\, \lambda\|\zbm\|_1+\Pi(\zbm) + \frac{1}{2\eta}\|\zbm-\xbm\|^2_2 \\
    &=\argmin_{\zbm\in [0,1]^n}\, \lambda\|\zbm\|_1+ \frac{1}{2\eta}\|\zbm-\xbm\|^2_2
\end{align*}
$$
since this is a separable problem, we can focus on the individual components:
$$
\text{prox}_{g,\eta}(x_i) = \argmin_{z_i\in [0,1]} \lambda z_i + \frac{1}{2\eta}(z_i-x_i)^2
$$
and hence the solution to this proximal operator problem is
$$
\min\{\,\max \{0,\, x_i-\eta\lambda\, \},\, 1\}
$$
for each component $x_i$.
