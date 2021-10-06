"""
ArithmeticBlocks
"""

export AddBlock

mutable struct AddBlock <: AbstractArithmeticBlock
    inport::Vector{InPort}
    outport::Vector{OutPort}
    op::Vector{Symbol}

    function AddBlock(op::Vector{Symbol})
        @createblock new(Vector{InPort}(), Vector{OutPort}(), op) length(op) 1
    end
end


"""
IO
"""

function Base.show(io::IO, blk::AddBlock)
    println(io, "AddBlock($(blk.op))")
end

"""
to expr
"""

function _toexpr(blk::AddBlock)
    args = [Expr(:call, x[1], _toexpr(x[2])) for x = zip(blk.op, blk.inport)]
    Expr(:call, :+, args...)
end
