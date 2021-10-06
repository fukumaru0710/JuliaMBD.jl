"""
FunctionBlocks
"""

export PulseGeneratorBlock

mutable struct PulseGeneratorBlock <: AbstractFunctionBlock
    inport::Vector{InPort}
    outport::Vector{OutPort}
    amplitude::AbstractSignalLine
    period::AbstractSignalLine
    pulsewidth::AbstractSignalLine
    phasedelay::AbstractSignalLine

    function PulseGeneratorBlock(::Type{Tv} = Float64; amplitude=1, period=10, pulsewidth=5, phasedelay=0) where Tv
        @createblock new(Vector{InPort}(), Vector{OutPort}(),
            signal(amplitude, Tv),
            signal(period, Tv),
            signal(pulsewidth, Tv),
            signal(phasedelay, Tv)
            ) 0 1
    end
end


"""
IO
"""

function Base.show(io::IO, blk::PulseGeneratorBlock)
    println(io, "Pulse($(blk.amp), $(blk.cycle), $(blk.width), $(blk.delay))")
end

"""
to expr
"""

function _toexpr(blk::PulseGeneratorBlock)
    amplitude = _toexpr(blk.amplitude)
    period = _toexpr(blk.period)
    pulsewidth = _toexpr(blk.pulsewidth)
    phasedelay = _toexpr(blk.phasedelay)
    quote
        if t < $phasedelay
            0.0
        else
            u = ((t - $phasedelay) % $period) / $period * 100
            if u < $pulsewidth
                $amplitude
            else
                0
            end
        end
    end
end

