
struct Terminator end

mutable struct InPort <: AbstractPort
    line::Union{AbstractSignalLine,Terminator}
    blk::AbstractBlock
    InPort() = new(Terminator())
end

mutable struct OutPort <: AbstractPort
#     line::Union{AbstractSignalLine,Terminator}
    blk::AbstractBlock
    OutPort() = new() #, Terminator())
end

"""
IO
"""

function Base.show(io::IO, port::InPort)
    println(io, "InPort()")
end

function Base.show(io::IO, port::OutPort)
    println(io, "OutPort()")
end

"""
Add ports
"""

function _addport!(blk::AbstractBlock, port::InPort)
    port.blk = blk
    push!(blk.inport, port)
    nothing
end

function _addport!(blk::AbstractBlock, port::OutPort)
    port.blk = blk
    push!(blk.outport, port)
    nothing
end

macro createblock(expr, innum, outnum)
    ex = quote
        b = $(expr)
        for t = 1:$innum
            _addport!(b, InPort())
        end
        for t = 1:$outnum
            _addport!(b, OutPort())
        end
        b
    end
    esc(ex)
end

"""
toexpr

This is used to make the expression.
The expression is used for making both system equation and output equation.
"""

function _toexpr(port::Terminator)
    :terminator
end

function _toexpr(port::InPort)
    _toexpr(port.line)
end

function _toexpr(port::Vector{InPort})
    _toexpr(port[1].line)
end

function _toexpr(port::OutPort)
    _toexpr(port.blk)
end

function _toexpr(port::Vector{OutPort})
    _toexpr(port[1].blk)
end
