import Base

export signal

struct SignalLineValue{Tv} <: AbstractSignalLine{Tv}
    value::Tv
end

struct SignalLineSymbol{Tv} <: AbstractSignalLine{Tv}
    value::Symbol
end

struct SignalLinePort{Tv} <: AbstractSignalLine{Tv}
    port::OutPort
end

struct SignalLineVector{Tv} <: AbstractSignalLine{Tv}
    vec::Vector{Tv}
end

function signal(x::Symbol, ::Type{Tv} = Float64) where Tv
    SignalLineSymbol{Tv}(x)
end

function signal(x::Number, ::Type{Tv} = Float64) where Tv
    SignalLineValue{Tv}(x)
end

function signal(x::OutPort, ::Type{Tv} = Float64) where Tv
    SignalLinePort{Tv}(x)
end

function signal(x::Vector{OutPort}, ::Type{Tv} = Float64) where Tv
    SignalLinePort{Tv}(x[1])
end

function signal(x::InPort, ::Type{Tv} = Float64) where Tv
    signal(x.blk, Tv)
end

function signal(x::Vector{InPort}, ::Type{Tv} = Float64) where Tv
    signal(x[1].blk, Tv)
end

function signal(x::AbstractBlock, ::Type{Tv} = Float64) where Tv
    signal(x.outport[1], Tv)
end

function signal(x::AbstractSignalLine{Tv}, ::Type{Tv} = Float64) where Tv
    x
end

struct SignalLineOperation{OP,Tv,N} <: AbstractSignalLine{Tv}
    op::Symbol
    args::NTuple{N,AbstractSignalLine{Tv}}
end

function SignalLineOperation{OP,Tv,N}(op::Symbol, args::Vararg{AbstractSignalLine{Tv},N}) where {OP,Tv,N}
    SignalLineOperation{OP,Tv,N}(op, args)
end

for op in [:+, :-, :*, :/, :^, :exp, :log, :sin, :cos, :tan]
    qop = Expr(:quote, op)
    @eval function Base.$op(args::Vararg{AbstractSignalLine{Tv},N}) where {Tv,N}
        SignalLineOperation{Val{$qop},Tv,N}($qop, args...)
    end
end

"""
for number
"""

for op in [:+, :-, :*, :/, :^]
    qop = Expr(:quote, op)
    @eval function Base.$op(x::Number, y::AbstractSignalLine{Tv}) where {Tv}
        SignalLineOperation{Val{$qop},Tv,2}($qop, SignalLineValue{Tv}(x), y)
    end
end

for op in [:+, :-, :*, :/, :^]
    qop = Expr(:quote, op)
    @eval function Base.$op(x::AbstractSignalLine{Tv}, y::Number) where {Tv}
        SignalLineOperation{Val{$qop},Tv,2}($qop, x, SignalLineValue{Tv}(y))
    end
end

"""
to expr
"""

function _toexpr(line::SignalLineOperation{OP,Tv,N}) where {OP,Tv,N}
    args = [_toexpr(x) for x = line.args]
    Expr(:call, line.op, args...)
end

function _toexpr(line::SignalLineValue{Tv}) where Tv
    convert(Tv, line.value)
end

# function _toexpr(signal::Number)
#     signal
# end

function _toexpr(line::SignalLineSymbol{Tv}) where Tv
    :(convert($Tv, $(line.value)))
end

function _toexpr(line::SignalLinePort{Tv}) where Tv
    _toexpr(line.port)
end

"""
macro
"""

# macro line_str(x, type = :Float64)
#     :(SignalLineSymbol{$type}($:x))
# end

# function _replace_signal(::Type{Tv}, expr::Expr) where Tv
#     if Meta.isexpr(expr, :call)
#         args = [_replace_signal(Tv, x) for x = expr.args[2:end]]
#         Expr(expr.head, expr.args[1], args...)
#     else
#         args = [_replace_signal(Tv, x) for x = expr.args]
#         Expr(expr.head, args...)
#     end
# end

# function _replace_signal(::Type{Tv}, expr::Symbol) where Tv
#     :(SignalSymbol{$Tv}($(Expr(:quote, expr))))
# end

# function _replace_signal(::Type{Tv}, expr::Number) where Tv
#     :(Signal{$Tv}($expr))
# end