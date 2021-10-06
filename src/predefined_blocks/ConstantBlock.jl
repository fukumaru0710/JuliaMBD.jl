"""
FunctionBlocks
"""

export ConstantBlock

mutable struct ConstantBlock <: AbstractFunctionBlock
    inport::Vector{InPort}
    outport::Vector{OutPort}
    value

    function ConstantBlock(value, ::Type{Tv} = Float64) where Tv
        @createblock new(Vector{InPort}(), Vector{OutPort}(), signal(value, Tv)) 0 1
    end
end

"""
IO
"""

function Base.show(io::IO, blk::ConstantBlock)
    println(io, "Constant($(blk.value))")
end

"""
to expr
"""

function _toexpr(blk::ConstantBlock)
    _toexpr(blk.value)
end
