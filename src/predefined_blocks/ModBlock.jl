"""
Mod block
"""

export ModBlock

mutable struct ModBlock <: AbstractBlock
    inport::Vector{InPort}
    outport::Vector{OutPort}

    function ModBlock() where Tv
        @createblock new(Vector{InPort}(), Vector{OutPort}()) 2 1
    end
end


"""
IO
"""

function Base.show(io::IO, blk::ModBlock)
    println(io, "Mod()")
end

"""
to expr
"""

function _toexpr(blk::ModBlock)
    Expr(:call, :%, _toexpr(blk.inport[1]), _toexpr(blk.inport[2]))
end

