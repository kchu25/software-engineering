@def title = "Transformer Architecture in Flux.jl"
@def published = "7 October 2025"
@def tags = ["neural-nets", "julia"]

# Transformer Architecture in Flux.jl

**Note:** This implementation is fully compatible with Flux.jl's automatic differentiation and training utilities. All custom structs use `Flux.@layer` to make their parameters trainable, and the code uses Flux-native operations throughout.

## Setup and Imports

```julia
using Flux
using Flux: glorot_uniform
using LinearAlgebra
```

We're using Flux for the neural network layers, and LinearAlgebra for matrix operations in the attention mechanism.

---

## Multi-Head Attention Layer

```julia
struct MultiHeadAttention
    num_heads::Int
    head_dim::Int
    W_q::Dense
    W_k::Dense
    W_v::Dense
    W_o::Dense
    dropout::Dropout
end

Flux.@layer MultiHeadAttention

function MultiHeadAttention(d_model::Int, num_heads::Int; dropout=0.1)
    @assert d_model % num_heads == 0 "d_model must be divisible by num_heads"
    head_dim = d_model ÷ num_heads
    
    MultiHeadAttention(
        num_heads,
        head_dim,
        Dense(d_model, d_model),
        Dense(d_model, d_model),
        Dense(d_model, d_model),
        Dense(d_model, d_model),
        Dropout(dropout)
    )
end
```

This is the heart of the transformer - the multi-head attention mechanism. We split the model dimension into multiple heads, each learning different attention patterns. The four dense layers project our input into queries (Q), keys (K), values (V), and then combine the multi-head outputs back together.

---

## Attention Forward Pass

```julia
function (mha::MultiHeadAttention)(x)
    # x: (d_model, L, batch)
    d_model, L, batch = size(x)
    
    # Linear projections
    Q = mha.W_q(x)  # (d_model, L, batch)
    K = mha.W_k(x)
    V = mha.W_v(x)
    
    # Reshape for multi-head: (head_dim, num_heads, L, batch)
    Q = reshape(Q, mha.head_dim, mha.num_heads, L, batch)
    K = reshape(K, mha.head_dim, mha.num_heads, L, batch)
    V = reshape(V, mha.head_dim, mha.num_heads, L, batch)
    
    # Scaled dot-product attention
    # scores: (L, L, num_heads, batch)
    scores = batched_mul(permutedims(Q, (3, 1, 2, 4)), 
                         permutedims(K, (1, 3, 2, 4)))
    scores = scores ./ sqrt(Float32(mha.head_dim))
    
    attn_weights = softmax(scores, dims=1)
    attn_weights = mha.dropout(attn_weights)
    
    # Apply attention to values
    # output: (head_dim, L, num_heads, batch)
    output = batched_mul(permutedims(V, (1, 3, 2, 4)), 
                         permutedims(attn_weights, (2, 1, 3, 4)))
    
    # Concatenate heads and project
    output = reshape(output, d_model, L, batch)
    output = mha.W_o(output)
    
    return output
end
```

Here's where the magic happens. We compute attention scores between all positions in the sequence (how much each amino acid should "attend to" every other amino acid), then use those scores to create a weighted combination of the values. The division by sqrt(head_dim) prevents the dot products from getting too large, which would make gradients unstable.

**Note on permutedims - the math:** We want to compute attention scores as Q·Kᵀ for each head in each batch. Starting with:
- Q has shape (head_dim, num_heads, L, batch)
- K has shape (head_dim, num_heads, L, batch)

For the attention computation Q·Kᵀ, we need to compute the dot product between every pair of positions. Mathematically, we want:

scores[i,j] = Σ_d Q[d,h,i,b] × K[d,h,j,b]

This gives us an (L×L) matrix where scores[i,j] tells us how much position i attends to position j.

So we rearrange:
- `permutedims(Q, (3,1,2,4))` → (L, head_dim, num_heads, batch)
- `permutedims(K, (1,3,2,4))` → (head_dim, L, num_heads, batch)

Now `batched_mul` gives us (L, L, num_heads, batch), where for each head and batch, we have an L×L attention matrix. The permutations essentially set up the matrix multiply so the head_dim gets contracted (summed over), leaving us with position-to-position scores.

**Good news:** `permutedims` is fully differentiable and Flux-compatible - gradients flow through it just fine during backpropagation!

---

## Feed-Forward Network

```julia
function FeedForward(d_model::Int, d_ff::Int; dropout=0.1)
    Chain(
        Dense(d_model, d_ff, gelu),
        Dropout(dropout),
        Dense(d_ff, d_model)
    )
end
```

This is a simple two-layer MLP that processes each position independently. It expands the representation to a higher dimension (d_ff), applies a non-linearity, then projects back down. Think of it as giving the model more capacity to transform the representations after attention has mixed information between positions.

---

## Transformer Block Structure

```julia
struct TransformerBlock
    attention::MultiHeadAttention
    norm1::LayerNorm
    ffn::Chain
    norm2::LayerNorm
    dropout::Dropout
end

Flux.@layer TransformerBlock

function TransformerBlock(d_model::Int, num_heads::Int, d_ff::Int; dropout=0.1)
    TransformerBlock(
        MultiHeadAttention(d_model, num_heads, dropout=dropout),
        LayerNorm(d_model),
        FeedForward(d_model, d_ff, dropout=dropout),
        LayerNorm(d_model),
        Dropout(dropout)
    )
end
```

A transformer block packages everything together: attention, feed-forward network, layer norms, and dropout. This is the basic repeating unit we'll stack multiple times. Each block has two sub-layers (attention and FFN) with their own normalization.

---

## Transformer Block Forward Pass

```julia
function (block::TransformerBlock)(x)
    # x: (d_model, L, batch)
    
    # Self-attention with residual
    attn_out = block.attention(x)
    x = x .+ block.dropout(attn_out)
    x = block.norm1(x)
    
    # Feed-forward with residual
    ffn_out = block.ffn(x)
    x = x .+ block.dropout(ffn_out)
    x = block.norm2(x)
    
    return x
end
```

The residual connections (adding the input back to the output) are crucial - they let gradients flow directly through the network and make deep transformers trainable. We use "post-norm" architecture here where normalization happens after the residual addition, which tends to be more stable.

---

## Full Model Structure

```julia
struct ProteinTransformer
    embedding::Dense
    pos_encoding::Array{Float32, 2}
    encoder_blocks::Vector{TransformerBlock}
    pool::Symbol  # :mean or :cls
    head::Chain
end

Flux.@layer ProteinTransformer (embedding, encoder_blocks, head)

function ProteinTransformer(;
    vocab_size=20,
    max_len=512,
    d_model=128,
    num_heads=8,
    d_ff=512,
    num_layers=6,
    dropout=0.1,
    pool=:mean
)
    # Embedding layer
    embedding = Dense(vocab_size, d_model)
    
    # Positional encoding (fixed sinusoidal)
    pos_encoding = make_positional_encoding(max_len, d_model)
    
    # Stack of transformer blocks
    encoder_blocks = [TransformerBlock(d_model, num_heads, d_ff, dropout=dropout) 
                      for _ in 1:num_layers]
    
    # Prediction head
    head = Chain(
        Dense(d_model, d_model ÷ 2, relu),
        Dropout(dropout),
        Dense(d_model ÷ 2, 1)
    )
    
    ProteinTransformer(embedding, pos_encoding, encoder_blocks, pool, head)
end
```

This ties everything together. We start with an embedding to project our 20-dimensional one-hot vectors into a richer representation space. The positional encodings are fixed (not learned), giving the model information about where each amino acid is in the sequence. Then we stack our transformer blocks and add a simple prediction head at the end to output a scalar.

**Hyperparameter guide:**
- `vocab_size=20`: The 20 standard amino acids (A, C, D, E, F, G, H, I, K, L, M, N, P, Q, R, S, T, V, W, Y)
- `max_len=512`: Maximum sequence length we can handle - proteins are typically 100-500 residues, so 512 gives headroom
- `d_model=128`: The internal representation dimension - bigger captures more complex patterns but needs more data. 128-256 is typical for proteins
- `num_heads=8`: Number of parallel attention mechanisms - each head can learn different types of relationships (hydrophobic contacts, secondary structure, etc.)
- `d_ff=512`: Feed-forward hidden dimension - usually 2-4× the d_model. Gives the model capacity to transform representations
- `num_layers=6`: Depth of the network - see the layer count note below
- `dropout=0.1`: Regularization to prevent overfitting - randomly zeros 10% of activations during training

**Note on layer count:** How many layers should you use? It really depends on your data and task complexity. For protein sequences:
- **2-4 layers**: Good starting point for smaller datasets or simpler tasks (like predicting secondary structure)
- **6-8 layers**: Sweet spot for most protein property prediction tasks with moderate datasets
- **12+ layers**: Only if you have lots of data (100k+ sequences) and computational resources - diminishing returns kick in

Start with 4-6 layers and monitor validation performance. More layers ≠ better if you're overfitting or running out of data diversity.

---

## Positional Encoding

```julia
function make_positional_encoding(max_len::Int, d_model::Int)
    pe = zeros(Float32, d_model, max_len)
    position = Float32.(0:max_len-1)
    
    for i in 1:2:d_model
        div_term = exp((i-1) * -log(10000.0f0) / d_model)
        pe[i, :] = sin.(position .* div_term)
        if i + 1 <= d_model
            pe[i+1, :] = cos.(position .* div_term)
        end
    end
    
    return pe
end
```

Transformers have no built-in notion of sequence order, so we add these sinusoidal patterns to give each position a unique signature. The alternating sin/cos waves at different frequencies create a smooth encoding where nearby positions have similar representations. It's like giving each position in your protein sequence a unique coordinate in representation space.

---

## Model Forward Pass

```julia
function (model::ProteinTransformer)(x)
    # x: (20, L, batch) - one-hot encoded amino acids
    
    # Embed
    x = model.embedding(x)  # (d_model, L, batch)
    
    # Add positional encoding
    _, L, batch = size(x)
    pos_enc = model.pos_encoding[:, 1:L]
    x = x .+ reshape(pos_enc, size(pos_enc, 1), size(pos_enc, 2), 1)
    
    # Pass through transformer blocks
    for block in model.encoder_blocks
        x = block(x)
    end
    
    # Pool sequence dimension
    if model.pool == :mean
        x = mean(x, dims=2)  # (d_model, 1, batch)
    else  # :cls token (use first position)
        x = x[:, 1:1, :]
    end
    
    x = dropdims(x, dims=2)  # (d_model, batch)
    
    # Prediction head
    x = model.head(x)  # (1, batch)
    
    return dropdims(x, dims=1)  # (batch,)
end
```

The full forward pass: embed the amino acids, add positional information, run through all transformer layers, pool the sequence down to a single vector (using mean pooling to aggregate information from all positions), and finally predict a scalar. Each sequence of any length gets compressed into a single prediction.

---

## Example Usage

```julia
# Create the model
model = ProteinTransformer(
    vocab_size=20,
    max_len=512,
    d_model=128,
    num_heads=8,
    d_ff=512,
    num_layers=6,
    dropout=0.1,
    pool=:mean
)

# Example input: batch of 4 sequences, each length 50
x = Flux.onehotbatch(rand(1:20, 50, 4), 1:20)  # (20, 50, 4)
y = model(x)  # (4,) - scalar output for each sequence

# Training setup
loss(x, y_true) = Flux.mse(model(x), y_true)
opt = Adam(1e-4)
```

Here's how you'd actually use it. Create a model with your desired architecture, feed it batches of one-hot encoded sequences, and it spits out scalar predictions. The loss function here is mean squared error, which works great for regression tasks like predicting protein stability or binding affinity.