"""
ArithmeticBlocks
"""

export SubBlock

mutable struct SubBlock <: AbstractArithmeticBlock
    inport::Vector{InPort}
    outport::Vector{OutPort}

    function SubBlock()
        @createblock new(Vector{InPort}(), Vector{OutPort}()) 2 1
    end
end


"""
IO
"""

function Base.show(io::IO, blk::SubBlock)
    println(io, "SubBlock()")
end

"""
to expr
"""

function _toexpr(blk::SubBlock)
    Expr(:call, :-, _toexpr(blk.inport[1]), _toexpr(blk.inport[2]))
end
