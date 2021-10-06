"""
Out Block
"""

export OutBlock

mutable struct OutBlock <: AbstractBlock
    inport::Vector{InPort}
    outport::Vector{OutPort}

    function OutBlock()
        @createblock new(Vector{InPort}(), Vector{OutPort}()) 1 1
    end
end

"""
IO
"""

function Base.show(io::IO, blk::OutBlock)
    println(io, "OutBlock()")
end

"""
to expr
"""

function _toexpr(blk::OutBlock)
    _toexpr(blk.inport[1])
end
