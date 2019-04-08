import LinearAlgebra: det, logdet, diagm, Diagonal, diag

const ∇ScalarDiag = Diagonal{<:∇Scalar}

@explicit_intercepts diag Tuple{∇AbstractMatrix}
function ∇(
    ::typeof(diag),
    ::Type{Arg{1}},
    p,
    y::∇AbstractVector,
    ȳ::∇AbstractVector,
    x::∇AbstractMatrix,
)
    x̄ = zeroslike(x)
    x̄[diagind(x̄)] = ȳ
    return x̄
end
function ∇(
    x̄::∇AbstractMatrix,
    ::typeof(diag),
    ::Type{Arg{1}},
    p,
    y::∇AbstractVector,
    ȳ::∇AbstractVector,
    x::∇AbstractMatrix,
)
    x̄_diag = view(x̄, diagind(x̄))
    x̄_diag .+= ȳ
    return x̄
end

@explicit_intercepts diag Tuple{∇AbstractMatrix, Integer} [true, false]
function ∇(
    ::typeof(diag),
    ::Type{Arg{1}},
    p,
    y::∇AbstractVector,
    ȳ::∇AbstractVector,
    x::∇AbstractMatrix,
    k::Integer,
)
    x̄ = zeroslike(x)
    x̄[diagind(x̄, k)] = ȳ
    return x̄
end
function ∇(
    x̄::∇AbstractMatrix,
    ::typeof(diag),
    ::Type{Arg{1}},
    p,
    y::∇AbstractVector,
    ȳ::∇AbstractVector,
    x::∇AbstractMatrix,
    k::Integer,
)
    x̄_diag = view(x̄, diagind(x̄, k))
    x̄_diag .+= ȳ
    return x̄
end

@explicit_intercepts Diagonal Tuple{∇AbstractVector}
function ∇(
    ::Type{Diagonal},
    ::Type{Arg{1}},
    p,
    Y::∇ScalarDiag,
    Ȳ::∇AbstractMatrix,
    x::∇AbstractVector,
)
    return copyto!(similar(x), diag(Ȳ))
end
function ∇(
    x̄::∇AbstractVector,
    ::Type{Diagonal},
    ::Type{Arg{1}},
    p,
    Y::∇ScalarDiag,
    Ȳ::∇AbstractMatrix,
    x::∇AbstractVector,
)
    return broadcast!(+, x̄, x̄, diag(Ȳ))
end

@explicit_intercepts Diagonal Tuple{∇AbstractMatrix}
function ∇(
    ::Type{Diagonal},
    ::Type{Arg{1}},
    p,
    Y::∇ScalarDiag,
    Ȳ::∇ScalarDiag,
    X::∇AbstractMatrix,
)
    X̄ = zeroslike(X)
    copyto!(view(X̄, diagind(X)), Ȳ.diag)
    return X̄
end
function ∇(
    X̄::∇AbstractMatrix,
    ::Type{Diagonal},
    ::Type{Arg{1}},
    p,
    Y::∇ScalarDiag,
    Ȳ::∇ScalarDiag,
    X::∇AbstractMatrix,
)
    X̄_diag = view(X̄, diagind(X̄))
    broadcast!(+, X̄_diag, X̄_diag, Ȳ.diag)
    return X̄
end

@explicit_intercepts det Tuple{Diagonal{<:∇Scalar}}
∇(::typeof(det), ::Type{Arg{1}}, p, y::∇Scalar, ȳ::∇Scalar, X::∇ScalarDiag) =
    Diagonal(ȳ .* y ./ X.diag)
function ∇(
    X̄::∇ScalarDiag,
    ::typeof(det),
    ::Type{Arg{1}},
    p,
    y::∇Scalar,
    ȳ::∇Scalar,
    X::∇ScalarDiag,
)
    broadcast!((x̄, x, y, ȳ)->x̄ + ȳ * y / x, X̄.diag, X̄.diag, X.diag, y, ȳ)
    return X̄
end

@explicit_intercepts logdet Tuple{Diagonal{<:∇Scalar}}
∇(::typeof(logdet), ::Type{Arg{1}}, p, y::∇Scalar, ȳ::∇Scalar, X::∇ScalarDiag) =
    Diagonal(ȳ ./ X.diag)
function ∇(
    X̄::∇ScalarDiag,
    ::typeof(logdet),
    ::Type{Arg{1}},
    p,
    y::∇Scalar,
    ȳ::∇Scalar,
    X::∇ScalarDiag,
)
    broadcast!((x̄, x, ȳ)->x̄ + ȳ / x, X̄.diag, X̄.diag, X.diag, ȳ)
    return X̄
end

# NOTE: diagm can't go through the @explicit_intercepts machinery directly because as of
# Julia 0.7, its methods are not sufficiently straightforward; we need to dispatch on one
# of the parameters in the parametric type of diagm's one argument. However, we can cheat
# a little bit and use an internal helper function _diagm that has simple methods that
# dispatch to diagm when no arguments are Nodes, and we'll extend diagm to dispatch to
# _diagm when it receives arguments that are nodes. _diagm can go through the intercepts
# machinery, so it knows how to deal.

_diagm(x::∇AbstractVector, k::Integer=0) = diagm(k => x)
LinearAlgebra.diagm(x::Pair{<:Integer, <:Node{<:∇AbstractVector}}) = _diagm(last(x), first(x))

@explicit_intercepts _diagm Tuple{∇AbstractVector}
function ∇(
    ::typeof(_diagm),
    ::Type{Arg{1}},
    p,
    Y::∇AbstractMatrix,
    Ȳ::∇AbstractMatrix,
    x::∇AbstractVector,
)
    return copyto!(similar(x), view(Ȳ, diagind(Ȳ)))
end
function ∇(
    x̄::∇AbstractVector,
    ::typeof(_diagm),
    ::Type{Arg{1}},
    p,
    Y::∇AbstractMatrix,
    Ȳ::∇AbstractMatrix,
    x::∇AbstractVector,
)
    return broadcast!(+, x̄, x̄, view(Ȳ, diagind(Ȳ)))
end
@explicit_intercepts _diagm Tuple{∇AbstractVector, Integer} [true, false]
function ∇(
    ::typeof(_diagm),
    ::Type{Arg{1}},
    p,
    Y::∇AbstractMatrix,
    Ȳ::∇AbstractMatrix,
    x::∇AbstractVector,
    k::Integer,
)
    return copyto!(similar(x), view(Ȳ, diagind(Ȳ, k)))
end
function ∇(
    x̄::∇AbstractVector,
    ::typeof(_diagm),
    ::Type{Arg{1}},
    p,
    Y::∇AbstractMatrix,
    Ȳ::∇AbstractMatrix,
    x::∇AbstractVector,
    k::Integer,
)
    return broadcast!(+, x̄, x̄, view(Ȳ, diagind(Ȳ, k)))
end
