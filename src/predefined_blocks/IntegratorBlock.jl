"""
Integrator Block
"""

export IntegratorBlock

abstract type AbstractIntegratorBlock <: AbstractBlock end

mutable struct IntegratorBlock <: AbstractIntegratorBlock
    inport::Vector{InPort}
    outport::Vector{OutPort}
    state::Symbol
    initialcondition::AbstractSignalLine
    saturationlimits::Vector{AbstractSignalLine}

    function IntegratorBlock(::Type{Tv} = Float64; initialcondition = 0, saturationlimits = []) where Tv
        @createblock new(Vector{InPort}(), Vector{OutPort}(), gensym(),
            signal(initialcondition, Tv),
            [signal(x, Tv) for x = saturationlimits]
            ) 1 1
    end
end


"""
IO
"""

function Base.show(io::IO, blk::IntegratorBlock)
    println(io, "IntegratorBlock()")
end

"""
to expr
"""

function _toexpr(blk::IntegratorBlock)
    return blk.state
end

"""
tosystemexpr

This is an expression to build system equations.

"""

function _tosystemexpr(blk::IntegratorBlock)
    saturationlimits = [_toexpr(x) for x = blk.saturationlimits]
    if length(saturationlimits) == 0
        _toexpr(blk.inport[1])
    else
        lower, upper = saturationlimits
        Expr(:if, Expr(:comparison, lower, :<=, blk.state, :<=, uupper), _toexpr(blk.inport[1]), 0)
    end
end

