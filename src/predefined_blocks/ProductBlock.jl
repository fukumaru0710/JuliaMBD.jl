"""
ArithmeticBlocks
"""

export ProductBlock

mutable struct ProductBlock <: AbstractArithmeticBlock
    inport::Vector{InPort}
    outport::Vector{OutPort}

    function ProductBlock()
        @createblock new(Vector{InPort}(), Vector{OutPort}()) 2 1
    end
end


"""
IO
"""

function Base.show(io::IO, blk::ProductBlock)
    println(io, "ProductBlock()")
end

"""
to expr
"""

function _toexpr(blk::ProductBlock)
    Expr(:call, :*, _toexpr(blk.inport[1]), _toexpr(blk.inport[2]))
end
