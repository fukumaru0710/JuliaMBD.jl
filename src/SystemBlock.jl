"""
System block
"""

export systemequation, odeproblem, scope
export SystemBlock, blk!, connect!, assignvar!
export SimulationResult

mutable struct SystemBlock <: AbstractBlock
    inport::Vector{InPort}
    outport::Vector{OutPort}
    env::Dict{Symbol,Any}
    states::Dict{Symbol,AbstractBlock}

    function SystemBlock()
        new(Vector{InPort}(), Vector{OutPort}(), Dict{Symbol,Any}(), Dict{Symbol,AbstractBlock}())
    end
end

"""
IO
"""

function Base.show(io::IO, blk::SystemBlock)
    println(io, "SystemBlock()")
end

"""
functions
"""

function blk!(system::SystemBlock, label::Symbol, blk::AbstractBlock)::AbstractBlock
    system.env[label] = blk
end

function blk!(system::SystemBlock, label::Symbol, blk::AbstractIntegratorBlock)::AbstractBlock
    system.states[blk.state] = blk
    system.env[label] = blk
end

function blk!(system::SystemBlock, label::Symbol, blk::SystemBlock)::AbstractBlock
    for (k,v) in blk.states
        system.states[k] = v
    end
    for (k,v) in blk.env
        k2 = Symbol(label, "_", k)
        system.env[k2] = blk.env[k]
    end
    system.env[label] = blk
end

function blk!(system::SystemBlock, label::Symbol, blk::InBlock)::AbstractBlock
    push!(system.inport, blk.inport[1])
    system.env[label] = blk
end

function blk!(system::SystemBlock, label::Symbol, blk::OutBlock)::AbstractBlock
    push!(system.outport, blk.outport[1])
    system.env[label] = blk
end

"""
connect
"""

function connect!(src::AbstractSignalLine{Tv}, dest::InPort, ::Type{Tv} = Float64) where Tv
    dest.line = src
    nothing
end

function connect!(src::OutPort, dest::InPort, ::Type{Tv} = Float64) where Tv
    connect!(signal(src, Tv), dest, Tv)
end

function connect!(src::Vector{OutPort}, dest::InPort, ::Type{Tv} = Float64) where Tv
    connect!(src[1], dest, Tv)
end

function connect!(src::AbstractBlock, dest::InPort, ::Type{Tv} = Float64) where Tv
    connect!(src.outport[1], dest, Tv)
end


function connect!(src::Any, dest::Vector{InPort}, ::Type{Tv} = Float64) where Tv
    connect!(src, dest[1], Tv)
end

function connect!(src::Any, dest::AbstractBlock, ::Type{Tv} = Float64) where Tv
    connect!(src, dest.inport[1], Tv)
end

"""
assign var
"""

function assignvar!(system::SystemBlock, label::Symbol, x::Any)
    system.env[label] = x
end

"""
system equation
"""

function systemequation(system::SystemBlock, label::Symbol = :model)
    u = gensym()
    du = Symbol("d", u)
    states = sort(collect(keys(system.states)))
    n = length(states)
    dict = Dict(zip(states, [:($u[$i]) for i = 1:n]))
    expr = [Expr(:(=), :($(du)[$i]), _replace(dict, _tosystemexpr(system.states[states[i]]))) for i = 1:n]
    initvec = [_toexpr(system.states[x].initialcondition) for x = states]
    init = Symbol(label, "init")
    func = Symbol(label, "!")
    quote
        $init = $initvec
        function $func($(du), $(u), p, t)
            $(Expr(:block, expr...))
        end
    end
end

function _systemequation_func(system::SystemBlock)
    u = gensym()
    du = Symbol("d", u)
    states = sort(collect(keys(system.states)))
    n = length(states)
    dict = Dict(zip(states, [:($u[$i]) for i = 1:n]))
    expr = [Expr(:(=), :($(du)[$i]), _replace(dict, _tosystemexpr(system.states[states[i]]))) for i = 1:n]
    func = quote
        ($(du), $(u), p, t) -> begin
            $(Expr(:block, expr...))
        end
    end
    eval(func)
end

function _systemequation_init(system::SystemBlock)
    states = sort(collect(keys(system.states)))
    [eval(_toexpr(system.states[x].initialcondition)) for x = states]
end

struct NoSolution
    t
end

function odeproblem(system::SystemBlock; tspan)
    if length(system.states) > 0
        func = _systemequation_func(system)
        initvec = _systemequation_init(system)
        DifferentialEquations.ODEProblem(func, initvec, tspan)
    else
        NoSolution([x for x = tspan])
    end
end

function DifferentialEquations.solve(x::NoSolution, args...; kargs...)
    x
end

function scope(system::SystemBlock, var::Symbol, solution)
    u = :solvedvalue
    states = sort(collect(keys(system.states)))
    n = length(states)
    dict = Dict(zip(states, [:($u(t)[$i]) for i = 1:n]))
    varx = signal(system.env[var])
    expr = _replace(dict, _toexpr(varx))
    func = eval(quote
        (t, solvedvalue) -> begin
            $(expr)
        end
            end)
    t -> begin
        func(t, solution)
        end
end

function _replace(dict, expr::Expr)
    args = [_replace(dict, x) for x = expr.args]
    Expr(expr.head, args...)
end

function _replace(dict, expr::Symbol)
    if expr in keys(dict)
        :($(dict[expr]))
    else
        expr
    end
end

function _replace(dict, expr::Any)
    expr
end

