"""
FunctionBlocks
"""

export QuantizerBlock

mutable struct QuantizerBlock <: AbstractFunctionBlock
    inport::Vector{InPort}
    outport::Vector{OutPort}
    quantizationinterval::AbstractSignalLine

    function QuantizerBlock(::Type{Tv} = Float64; quantizationinterval = 0) where Tv
        @createblock new(Vector{InPort}(), Vector{OutPort}(),
            signal(quantizationinterval, Tv),
            ) 1 1
    end
end


"""
IO
"""

function Base.show(io::IO, blk::QuantizerBlock)
    println(io, "Quantizer()")
end

"""
to expr
"""

function _toexpr(blk::QuantizerBlock)
    quantizationinterval = _toexpr(blk.quantizationinterval)
    inport = _toexpr(blk.inport[1])
    :($quantizationinterval * round($inport / $quantizationinterval))
end

