"""
ArithmeticBlocks
"""

export DivisionBlock

mutable struct DivisionBlock <: AbstractArithmeticBlock
    inport::Vector{InPort}
    outport::Vector{OutPort}

    function DivisionBlock()
        @createblock new(Vector{InPort}(), Vector{OutPort}()) 2 1
    end
end


"""
IO
"""

function Base.show(io::IO, blk::DivisionBlock)
    println(io, "DivisionBlock()")
end

"""
to expr
"""

function _toexpr(blk::DivisionBlock)
    Expr(:call, :/, _toexpr(blk.inport[1]), _toexpr(blk.inport[2]))
end
