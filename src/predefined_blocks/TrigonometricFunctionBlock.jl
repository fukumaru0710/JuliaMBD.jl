"""
ArithmeticBlocks
"""

export TrigonometricFunctionBlock

mutable struct TrigonometricFunctionBlock <: AbstractArithmeticBlock
    inport::Vector{InPort}
    outport::Vector{OutPort}
    op::Symbol

    function TrigonometricFunctionBlock(op::Symbol)
        @createblock new(Vector{InPort}(), Vector{OutPort}(), op) 1 1
    end
end


"""
IO
"""

function Base.show(io::IO, blk::TrigonometricFunctionBlock)
    println(io, "TrigonometricFunctionBlock($(blk.op))")
end

"""
to expr
"""

function _toexpr(blk::TrigonometricFunctionBlock)
        Expr(:call, blk.op, _toexpr(blk.inport[1]))
end
