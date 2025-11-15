@def title = "Loss Functions for Log-Scale Regression"
@def published = "4 November 2025"
@def tags = ["neural-nets", "julia"]


# Loss Functions for Log-Scale Regression

When dealing with data that spans multiple orders of magnitude, choosing the right loss function is crucial. Let's break down your options and when to use each.

## The Standard Approach: Transform Then MSE

**What most people do:**
```julia
y_log = log.(y)
# Fit your model to y_log
log_pred = predict(model, X)
y_pred = exp.(log_pred)  # Transform back
```

**What you're actually optimizing:**
$$L = \mathbb{E}[(\log(\hat{y}) - \log(y))^2] = \text{MSLE (Mean Squared Log Error)}$$

### Pros:
✅ Simple - just transform targets before training
✅ Multiplicative errors (10% off at 10 same as 10% off at 1000)
✅ Works with any model (linear regression, neural nets, trees, etc.)
✅ Automatically handles heteroscedasticity

### Cons:
❌ **Biased predictions** when transformed back (systematically underestimates)
❌ Requires strictly positive values
❌ Hypersensitive to near-zero values
❌ Model learns to predict **median** not mean

### The Bias Problem

Due to Jensen's inequality, $\mathbb{E}[e^X] > e^{\mathbb{E}[X]}$.

If residuals in log-space have variance $\sigma^2$, you need to correct:
$$\hat{y}_{\text{unbiased}} = \exp(\hat{y}_{\log} + \frac{\sigma^2}{2})$$

**Example:**
```julia
using Statistics

# Calculate residual variance on validation set
residuals = y_log_true .- y_log_pred
sigma_squared = var(residuals)

# Correct bias when transforming back
y_pred = exp.(log_pred .+ sigma_squared / 2)
```

Most people skip this and their predictions are too low!

## Alternative 1: Direct MSLE (No Transform)

**Keep targets in original scale, use custom loss:**
```julia
# Custom loss function
function msle_loss(y_pred, y_true)
    return mean((log.(y_pred) .- log.(y_true)).^2)
end

# For Flux.jl
using Flux
loss(x, y) = Flux.Losses.msle(model(x), y)

# Or manual implementation
function msle_loss(ŷ, y)
    log_diff = log.(ŷ) .- log.(y)
    return mean(log_diff.^2)
end
```

**What you're optimizing:**
$$L = \mathbb{E}[(\log(\hat{y}) - \log(y))^2]$$

Same as before, but no manual transformation needed!

### Pros:
✅ No need to transform targets manually
✅ No inverse transform needed
✅ Can apply bias correction during training
✅ Predictions are directly in original scale

### Cons:
❌ Still has bias issue
❌ Requires custom loss implementation
❌ Gradients can be unstable if $\hat{y}$ gets close to zero
❌ Need to clip predictions: $\hat{y} > \epsilon$ to avoid log(0)

### Gradient Behavior:
$$\frac{\partial L}{\partial \hat{y}} = \frac{2(\log(\hat{y}) - \log(y))}{\hat{y}}$$

Notice that $\frac{1}{\hat{y}}$ term - if prediction is small, gradient explodes! Need to be careful.

## Alternative 2: RMSLE (Root Mean Squared Log Error)

Just the square root of MSLE:
$L = \sqrt{\mathbb{E}[(\log(\hat{y}) - \log(y))^2]}$

```julia
function rmsle_loss(y_pred, y_true)
    return sqrt(mean((log.(y_pred .+ 1) .- log.(y_true .+ 1)).^2))
end
```

Note the `+1` to handle zeros! This makes it technically:
$$L = \sqrt{\mathbb{E}[(\log(\hat{y}+1) - \log(y+1))^2]}$$

### Pros:
✅ Same scale as log(y), easier to interpret
✅ The +1 offset handles zeros
✅ Popular in Kaggle competitions

### Cons:
❌ Still has all the MSLE issues
❌ The +1 is arbitrary
❌ Square root in loss can slow convergence

## Alternative 3: Mean Absolute Log Error (MALE)

Use L1 instead of L2 in log-space:
$L = \mathbb{E}[|\log(\hat{y}) - \log(y)|]$

```julia
function male_loss(y_pred, y_true)
    return mean(abs.(log.(y_pred) .- log.(y_true)))
end
```

### Pros:
✅ More robust to outliers than MSLE
✅ Predicts **median** explicitly (no pretense of predicting mean)
✅ No bias correction needed (for median estimation)
✅ Simpler gradients

### Cons:
❌ If you want mean predictions, this is wrong objective
❌ L1 gradients don't go to zero (can be jumpy)
❌ Still sensitive near zero

### Gradient:
$$\frac{\partial L}{\partial \hat{y}} = \frac{\text{sign}(\log(\hat{y}) - \log(y))}{\hat{y}}$$

Constant magnitude (±1/ŷ), just changes sign. Can be more stable than L2.

## Alternative 4: Weighted MSE in Original Space

**Don't transform at all, just weight the loss based on what you care about:**

### Option A: Optimize Relative/Percentage Errors (weights = 1/y²)
```julia
# Makes relative errors equal across all scales
function relative_mse(y_pred, y_true; epsilon=1e-6)
    weights = 1.0 ./ (y_true .+ epsilon).^2
    return mean(weights .* (y_pred .- y_true).^2)
end

# Or more directly:
function relative_mse(y_pred, y_true; epsilon=1e-6)
    return mean(((y_pred .- y_true) ./ (y_true .+ epsilon)).^2)
end
```

This optimizes **percentage error squared**:
$L = \mathbb{E}\left[\frac{(\hat{y} - y)^2}{y^2}\right] = \mathbb{E}\left[\left(\frac{\hat{y} - y}{y}\right)^2\right]$

**Effect:** 10% error at y=10 has same loss as 10% error at y=1000
- Error of 1 at y=10 → loss = (1/10)² = 0.01
- Error of 100 at y=1000 → loss = (100/1000)² = 0.01

⚠️ **This makes small values MORE important in absolute terms!** A weight of 1/y² means smaller y → larger weight.

### Option B: Prioritize Large Values (weights = yᵖ)
```julia
# Makes large values MORE important
function large_value_mse(y_pred, y_true; power=1, epsilon=1e-6)
    weights = (y_true .+ epsilon).^power
    return mean(weights .* (y_pred .- y_true).^2)
end
```

With `power=1`:
$L = \mathbb{E}[y \cdot (\hat{y} - y)^2]$

**Effect:** Errors on large values dominate the loss
- Error of 1 at y=10 → loss = 10 × 1² = 10
- Error of 1 at y=1000 → loss = 1000 × 1² = 1000

The large value contributes **100x more** to the loss!

With `power=2`, it's even more extreme (10,000x difference).

### Which Weighting Should You Use?

| Your Goal | Use This Weighting | Formula |
|-----------|-------------------|---------|
| **Relative errors matter** (10% at any scale is equally bad) | `weights = 1/y²` | Percentage errors |
| **Large absolute values matter more** | `weights = y` or `y²` | Large value focus |
| **Uniform treatment** | `weights = 1` | Plain MSE |

### Pros:
✅ No transformation needed at all
✅ **No bias issues** - predictions are naturally unbiased
✅ Interpretable: can optimize for relative errors OR large value focus
✅ Works with any model
✅ Direct control over what matters

### Cons:
❌ Can blow up if $y \approx 0$ with 1/y² weighting (need epsilon)
❌ Requires custom loss function
❌ Need to decide on weighting scheme (relative vs absolute focus)

### Relationship to MSLE:
For **relative errors** (weights = 1/y²), small errors satisfy:
$\left(\frac{\hat{y} - y}{y}\right)^2 \approx \left(\frac{\hat{y}}{y} - 1\right)^2 \approx (\log(\hat{y}) - \log(y))^2$

So for small relative errors, relative MSE ≈ MSLE! But:
- Relative MSE has **no bias issues**
- MSLE needs bias correction when transforming back
- For large errors, they diverge

## Alternative 5: Huber Loss in Log Space

Combines L2 (MSLE) for small errors with L1 (MALE) for large errors:
$L = \begin{cases}
\frac{1}{2}(\log(\hat{y}) - \log(y))^2 & \text{if } |\log(\hat{y}) - \log(y)| \leq \delta \\
\delta \cdot (|\log(\hat{y}) - \log(y)| - \frac{\delta}{2}) & \text{otherwise}
\end{cases}$

```julia
function log_huber_loss(y_pred, y_true; delta=1.0)
    log_diff = log.(y_pred) .- log.(y_true)
    abs_diff = abs.(log_diff)
    quadratic = 0.5 .* log_diff.^2
    linear = delta .* (abs_diff .- 0.5 * delta)
    return mean(ifelse.(abs_diff .<= delta, quadratic, linear))
end
```

### Pros:
✅ Robust to outliers (doesn't penalize huge errors as much)
✅ Still smooth around zero (better optimization than L1)
✅ Tunable threshold δ

### Cons:
❌ Another hyperparameter to tune (δ)
❌ Still has bias issues from log transform

## Alternative 6: Quantile Regression

Instead of predicting the mean or median, predict a specific quantile:
$L = \mathbb{E}[\rho_\tau(\log(y) - \log(\hat{y}))]$

where $\rho_\tau(u) = u(\tau - \mathbb{1}_{u < 0})$ is the quantile loss.

```julia
function quantile_log_loss(y_pred, y_true; tau=0.5)
    log_diff = log.(y_true) .- log.(y_pred)
    return mean(ifelse.(log_diff .> 0, 
                        tau .* log_diff,
                        (tau - 1) .* log_diff))
end

# For training multiple quantiles:
function train_quantile_models(X, y, quantiles=[0.25, 0.5, 0.75])
    models = Dict()
    for tau in quantiles
        loss(ŷ, y) = quantile_log_loss(ŷ, y; tau=tau)
        # Train your model with this loss
        models[tau] = trained_model
    end
    return models
end
```

Set $\tau = 0.5$ for median, $\tau = 0.75$ for upper quartile, etc.

### Pros:
✅ Gives you prediction intervals, not just point estimates
✅ Can focus on underestimation risk (τ > 0.5) or overestimation (τ < 0.5)
✅ Very robust

### Cons:
❌ More complex
❌ Need to train separate models for different quantiles
❌ Harder to interpret than mean predictions

## Alternative 7: Poisson Deviance Loss

If your data is count-like (non-negative integers or positive reals), consider:
$L = \mathbb{E}[y \log(y/\hat{y}) + (\hat{y} - y)]$

This is the negative log-likelihood for Poisson distribution.

```julia
function poisson_deviance(y_pred, y_true)
    return mean(y_true .* log.(y_true ./ y_pred) .+ (y_pred .- y_true))
end

# More stable version that handles zeros:
function poisson_deviance_stable(y_pred, y_true; epsilon=1e-10)
    y_pred = max.(y_pred, epsilon)  # Clip predictions
    # When y_true = 0, the y*log(y/ŷ) term is 0
    log_term = ifelse.(y_true .> 0, 
                       y_true .* log.(y_true ./ y_pred),
                       0.0)
    return mean(log_term .+ (y_pred .- y_true))
end
```

### Pros:
✅ Natural for count data
✅ Handles zeros properly
✅ Well-studied statistical properties
✅ Predictions are naturally unbiased

### Cons:
❌ Only appropriate for count/rate data
❌ Assumes Poisson variance structure (variance = mean)

## Comparison Table

| Loss Function | Bias? | Handles Zeros? | Sensitivity Near Zero | Prioritizes Large Values? | Good For |
|--------------|-------|----------------|----------------------|---------------------------|----------|
| **MSLE (transform)** | ⚠️ Yes, needs correction | ❌ No | 🔥 Very high | ❌ No, relative errors | Quick & dirty, multiplicative data |
| **Direct MSLE** | ⚠️ Yes | ❌ No | 🔥 Very high | ❌ No, relative errors | Custom training loop |
| **MALE** | ✅ No (for median) | ❌ No | 🔥 High | ❌ No | Robust outliers, median prediction |
| **Relative MSE (1/y²)** | ✅ No | ⚠️ Need epsilon | 🔥 High (small values matter more!) | ❌ No, percentage errors | **Relative/percentage error optimization** |
| **Large Value MSE (yᵖ)** | ✅ No | ✅ Yes | Low (large values matter more!) | ✅ Yes! | **When large values are what matters** |
| **Huber (log)** | ⚠️ Yes | ❌ No | 🔥 High | ❌ No | Outlier-robust MSLE |
| **Quantile** | ✅ No | ❌ No | 🔥 High | ❌ No | Uncertainty estimates |
| **Poisson** | ✅ No | ✅ Yes | Medium | ⚠️ Somewhat | Count data specifically |

## My Recommendations

### For optimizing relative/percentage errors: Relative MSE
```julia
function relative_mse_loss(y_pred, y_true; epsilon=1e-6)
    weights = 1.0 ./ (y_true .+ epsilon).^2
    return mean(weights .* (y_pred .- y_true).^2)
end

# Or more directly:
function relative_mse_loss(y_pred, y_true; epsilon=1e-6)
    return mean(((y_pred .- y_true) ./ (y_true .+ epsilon)).^2)
end
```

**Why:**
- No transformation headaches
- No bias issues  
- Optimizes relative errors (10% error equally bad at any scale)
- Clean gradients

**⚠️ Important:** This makes small values MORE important in absolute terms! It's optimizing percentage errors, not prioritizing large values.

### For prioritizing large values: Large Value MSE
```julia
function large_value_mse(y_pred, y_true; power=1, epsilon=1e-6)
    weights = (y_true .+ epsilon).^power
    return mean(weights .* (y_pred .- y_true).^2)
end
```

**Why:**
- No transformations
- No bias issues
- Errors on large values contribute much more to loss
- Power parameter controls how much you prioritize large values

**Use when:** You genuinely care more about getting 1000 → 1001 right than 1 → 2.

### If you must use log transform: Apply bias correction
```julia
using Statistics

# During training
y_log = log.(y)
# ... train your model on y_log ...

# At inference
log_pred = predict(model, X)
residuals = y_log_val .- predict(model, X_val)
sigma_squared = var(residuals)
y_pred = exp.(log_pred .+ sigma_squared / 2)  # ← Don't forget this!
```

**Why:** Without correction, you're predicting the geometric mean (median in log space), which systematically underestimates large values.

### For production systems: Quantile regression
```julia
# Train 3 models: 25th, 50th, 75th percentile
quantiles = [0.25, 0.5, 0.75]
models = Dict()

for tau in quantiles
    loss(ŷ, y) = quantile_log_loss(ŷ, y; tau=tau)
    models[tau] = train_model(X, y, loss)
end

# Now you have uncertainty bounds!
y_lower = predict(models[0.25], X_test)
y_median = predict(models[0.5], X_test)
y_upper = predict(models[0.75], X_test)
```

Especially valuable when large predictions have high stakes.

## The Real Question: What Are You Optimizing For?

The "right" loss depends on your actual business/scientific goal:

| Your Goal | Use This Loss | Why |
|-----------|---------------|-----|
| Minimize **relative/percentage errors** equally across all scales | Relative MSE (weights = 1/y²) or MSLE | 10% error at 10 = 10% error at 1000 |
| Minimize **absolute errors** uniformly | Plain MSE (no transform!) | All errors weighted equally |
| **Large values matter more** in absolute terms | Large Value MSE (weights = yᵖ) | Error of 1 at y=1000 matters more than error of 1 at y=10 |
| Predict **median** (robust to outliers) | MALE or quantile (τ=0.5) | Median is more robust |
| Predict **mean** unbiased | Large Value MSE or MSLE with correction | Avoid systematic bias |
| **Underestimation is worse** than overestimation | Quantile (τ > 0.5) or asymmetric loss | Penalize low predictions more |
| **Overestimation is worse** | Quantile (τ < 0.5) or asymmetric loss | Penalize high predictions more |
| Need **prediction intervals** | Quantile regression (multiple τ) | Get uncertainty bounds |
| Data is **counts/rates** | Poisson deviance | Natural for count data |

**Key Insight:** 
- **Relative MSE (1/y²)**: Treats percentage errors equally → small values get MORE weight in absolute terms
- **Large Value MSE (yᵖ)**: Large values get MORE weight → absolute errors on large values dominate
- **Plain MSE**: Uniform weighting → absolute errors treated equally
- **Log transform**: Like relative MSE but with bias issues

**Bottom line:** If you care about predicting large quantities accurately in absolute terms, use **Large Value MSE with power=1 or 2**, NOT relative MSE or log transforms!