"""
FunctionBlocks
"""

export StepBlock

mutable struct StepBlock <: AbstractFunctionBlock
    inport::Vector{InPort}
    outport::Vector{OutPort}
    steptime::AbstractSignalLine
    initialvalue::AbstractSignalLine
    finalvalue::AbstractSignalLine

    function StepBlock(::Type{Tv} = Float64; steptime = 0, initialvalue = 0, finalvalue = 0) where Tv
        @createblock new(Vector{InPort}(), Vector{OutPort}(),
            signal(steptime, Tv),
            signal(initialvalue, Tv),
            signal(finalvalue, Tv)
            ) 0 1
    end
end


"""
IO
"""

function Base.show(io::IO, blk::StepBlock)
    println(io, "Step()")
end

"""
to expr
"""

function _toexpr(blk::StepBlock)
    steptime = _toexpr(blk.steptime)
    initialvalue = _toexpr(blk.initialvalue)
    finalvalue = _toexpr(blk.finalvalue)
    :((t < $steptime) ? $initialvalue : $finalvalue)
end

