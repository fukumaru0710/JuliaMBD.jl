"""
FunctionBlocks
"""

export RampBlock

mutable struct RampBlock <: AbstractFunctionBlock
    inport::Vector{InPort}
    outport::Vector{OutPort}
    slope::AbstractSignalLine
    starttime::AbstractSignalLine
    initialoutput::AbstractSignalLine

    function RampBlock(::Type{Tv} = Float64; slope = 0, starttime = 0, initialoutput = 0) where Tv
        @createblock new(Vector{InPort}(), Vector{OutPort}(),
            signal(slope, Tv),
            signal(starttime, Tv),
            signal(initialoutput, Tv)
            ) 0 1
    end
end


"""
IO
"""

function Base.show(io::IO, blk::RampBlock)
    println(io, "Ramp()")
end

"""
to expr
"""

function _toexpr(blk::RampBlock)
    slope = _toexpr(blk.slope)
    starttime = _toexpr(blk.starttime)
    initialoutput = _toexpr(blk.initialoutput)
    :((t < $starttime) ? $initialoutput : $initialoutput + ($slope * (t - $starttime)))
end

