"""
In Block
"""

export InBlock

mutable struct InBlock <: AbstractBlock
    inport::Vector{InPort}
    outport::Vector{OutPort}

    function InBlock()
        @createblock new(Vector{InPort}(), Vector{OutPort}()) 1 1
    end
end

"""
IO
"""

function Base.show(io::IO, blk::InBlock)
    println(io, "InBlock()")
end

"""
to expr
"""

function _toexpr(blk::InBlock)
    _toexpr(blk.inport[1])
end
