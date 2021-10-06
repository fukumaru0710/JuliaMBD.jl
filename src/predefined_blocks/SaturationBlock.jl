"""
FunctionBlocks
"""

export SaturationBlock

mutable struct SaturationBlock <: AbstractFunctionBlock
    inport::Vector{InPort}
    outport::Vector{OutPort}
    upperlimit::AbstractSignalLine
    lowerlimit::AbstractSignalLine

    function SaturationBlock(::Type{Tv} = Float64; upperlimit = 0, lowerlimit = 0) where Tv
        @createblock new(Vector{InPort}(), Vector{OutPort}(),
            signal(upperlimit, Tv),
            signal(lowerlimit, Tv)
            ) 1 1
    end
end


"""
IO
"""

function Base.show(io::IO, blk::SaturationBlock)
    println(io, "Saturation()")
end

"""
to expr
"""

function _toexpr(blk::SaturationBlock)
    upperlimit = _toexpr(blk.upperlimit)
    lowerlimit = _toexpr(blk.lowerlimit)
    
    Expr(:if, Expr(:comparison, lowerlimit, :>=, _toexpr(blk.inport[1])), lowerlimit, Expr(:if, Expr(:comparison, upperlimit, :<=, _toexpr(blk.inport[1])), upperlimit, _toexpr(blk.inport[1])))

    #Expr(:if, Expr(:comparison, upperlimit, :<=, _toexpr(blk.inport[1])), upperlimit, _toexpr(blk.inport[1]))
    
end

