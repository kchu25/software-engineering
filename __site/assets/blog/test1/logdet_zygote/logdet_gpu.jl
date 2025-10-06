# This file was generated, do not modify it. # hide
using CUDA
CUDA.allowscalar(false)
@show gradient(f, cu(XᵀX))[1]