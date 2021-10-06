"""
ArithmeticBlocks
"""

export MathFunctionBlock

mutable struct MathFunctionBlock <: AbstractArithmeticBlock
    inport::Vector{InPort}
    outport::Vector{OutPort}
    op::Symbol

    function MathFunctionBlock(op::Symbol)
        @createblock new(Vector{InPort}(), Vector{OutPort}(), op) 1 1
    end
end


"""
IO
"""

function Base.show(io::IO, blk::MathFunctionBlock)
    println(io, "MathFunctionBlock($(blk.op))")
end

"""
to expr
"""

function _toexpr(blk::MathFunctionBlock)
    if blk.op == :reciprocal
        Expr(:call, :/, 1, _toexpr(blk.inport[1]))
    elseif blk.op == :square
        Expr(:call, :^, _toexpr(blk.inport[1]), 2)
    end
end
