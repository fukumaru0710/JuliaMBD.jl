"""
Gain block
"""

export GainBlock

mutable struct GainBlock <: AbstractBlock
    inport::Vector{InPort}
    outport::Vector{OutPort}
    gain::AbstractSignalLine

    function GainBlock(gain, ::Type{Tv} = Float64) where Tv
        @createblock new(Vector{InPort}(), Vector{OutPort}(), signal(gain, Tv)) 1 1
    end
end


"""
IO
"""

function Base.show(io::IO, blk::GainBlock)
    println(io, "Gain($(blk.gain))")
end

"""
to expr
"""

function _toexpr(blk::GainBlock)
    Expr(:call, :*, _toexpr(blk.gain), _toexpr(blk.inport[1]))
end

