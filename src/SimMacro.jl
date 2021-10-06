"""
macro
"""

export @model, @connect, @blk
export @simulate, @scope

mutable struct DefFunc
    name::Symbol
    params
    body
    DefFunc() = new(:f, [], [])
end

function _makeparams(params)::Expr
    args = map(params) do x
        if Meta.isexpr(x, :(=))
            Expr(:kw, x.args[1], Expr(:call, :signal, x.args[2]))
        elseif isa(x, Symbol)
            Expr(:kw, x, Expr(:call, :signal, Expr(:quote, x)))
        end
    end
    Expr(:parameters, args...)
end

function _deffunc(f::DefFunc)
    Expr(:function, 
        Expr(:call, f.name, _makeparams(f.params)),
        Expr(:block, f.body...))
end
    
"""
int1 = Sim.IntegratorBlock(init = 1)
Sim.blk!(system, :int1, int1)
"""

macro model(name, desc)
    @assert Meta.isexpr(desc, :block)
    f = DefFunc()
    f.name = name
    s = gensym()
    push!(f.body, :(local $s = SystemBlock()))
    for line = desc.args
        if Meta.isexpr(line, :macrocall) && line.args[1] == Symbol("@parameter")
            append!(f.params, filter(x->isa(x, Union{Symbol,Expr}), line.args[2:end]))
        else
            push!(f.body, _modelexpand(s, line))
        end
    end
    push!(f.body, s)
    esc(_deffunc(f))
end

function _modelexpand(system, expr::Expr)
    if Meta.isexpr(expr, :macrocall) && expr.args[1] == Symbol("@blk")
        b = expr.args[3]
        v = expr.args[4:end]
        _blk(system, b, v)
    elseif Meta.isexpr(expr, :macrocall) && expr.args[1] == Symbol("@connect")
        _connect(expr.args[3])
    else
        args = Any[_expand(system, x) for x = expr.args]
        Expr(expr.head, args...)
    end
end

function _modelexpand(system, expr::Any)
    expr
end

"""
blk
"""

macro blk(system, blk, vars...)
    _blk(system, blk, vars)
end

function _blk(system, blk, vars)
    @assert Meta.isexpr(blk, :(=)) && isa(blk.args[1], Symbol) && Meta.isexpr(blk.args[2], :call)
    ex = []
    symbol = blk.args[1]
    qsymbol = Expr(:quote, symbol)
    blktype = blk.args[2].args[1]
    blkargs = blk.args[2].args[2:end]
    push!(ex, :($symbol = blk!($system, $qsymbol, $blktype($(blkargs...)))))
    for x = vars
        @assert Meta.isexpr(x, :call) && x.args[1] == :(:)
        if Meta.isexpr(x.args[2], :ref) && isa(x.args[2].args[1], Symbol)
            port = Expr(:ref, Expr(:., symbol, Expr(:quote, x.args[2].args[1])), x.args[2].args[2])
            var = x.args[3]
            qvar = Expr(:quote, var)
            push!(ex, :($var = assignvar!($system, $qvar, $port)))
        elseif isa(x.args[2], Symbol)
            port = Expr(:., symbol, Expr(:quote, x.args[2]))
            var = x.args[3]
            qvar = Expr(:quote, var)
            push!(ex, :($var = assignvar!($system, $qvar, $port)))
        end
    end
    Expr(:block, ex...)
end

"""
connect
"""

macro connect(con)
    _connect(con)
end

function _connect(con)
    if Meta.isexpr(con, :call) && con.args[1] == :(<=)
        src = _connectexpandoutport(con.args[3])
        dest = con.args[2]
        :(connect!($src, $dest))
    elseif Meta.isexpr(con, :call) && con.args[1] == :(=>)
        src = _connectexpandoutport(con.args[2])
        dest = con.args[3]
        :(connect!($src, $dest))
    else
        error("error")
    end
end

function _connectexpandoutport(x::Expr)
    if Meta.isexpr(x, :call)
        args = [_connectexpandoutport(u) for u = x.args[2:end]]
        Expr(:call, x.args[1], args...)
    else
        Expr(:call, :signal, x)
    end
#         args = [Expr(:call, :signal, u) for u = x.args[1:end]]
#         Expr(x.head, args...)
#     end
end

function _connectexpandoutport(x::Symbol)
    Expr(:call, :signal, x)
end

function _connectexpandoutport(x::Any)
    x
end

"""
simulate
"""

struct SimulationResult
    t
    graph
    odesolution
    f::Dict{Symbol,Any}
end

macro simulate(model, kargs...)
    vars = nothing
    tspan = nothing
    solver = nothing
    solverops = []
    for x = kargs
        if Meta.isexpr(x, :(=)) && x.args[1] == :scope
            vars = _parsescope(x)
        elseif Meta.isexpr(x, :(=)) && x.args[1] == :tspan
            tspan = _parsetspan(x)
        elseif Meta.isexpr(x, :(=)) && x.args[1] == :solver
            solver = x.args[2]
        elseif Meta.isexpr(x, :(=)) && x.args[1] == :solveroptions
            solverops = _parsesolver(x.args[2])
        end
    end
    if solver != nothing
        insert!(solverops, 1, solver)
    end
    @assert vars != nothing && tspan != nothing
    ex = quote
        n = length($vars)
        @assert n >= 1
        @assert all(x -> haskey($model.env, x), $vars)
        prob = odeproblem($model, tspan = $tspan)
        solution = DifferentialEquations.solve(prob, $(solverops...))
        vars = [scope($model, x, solution) for x = $vars]
        g = Plots.plot(vars, solution.t[1], solution.t[end], layout=(n,1), leg=false)
        result = SimulationResult(solution.t, g, solution, Dict{Symbol,Any}())
        for (i,s) = enumerate($vars)
            result.f[s] = vars[i]
        end
        result
    end
    esc(ex)
end

function _parsescope(scope)
    @assert Meta.isexpr(scope, :(=)) && scope.args[1] == :scope
    if Meta.isexpr(scope.args[2], :vect) || Meta.isexpr(scope.args[2], :tuple)
        args = [Expr(:quote, x) for x = scope.args[2].args]
        Expr(:vect, args...)
    else
        Expr(:vect, Exper(:quote, scope.args[2].args))
    end
end

function _parsetspan(tspan)
    @assert Meta.isexpr(tspan, :(=)) && tspan.args[1] == :tspan
    if (Meta.isexpr(tspan.args[2], :vect) || Meta.isexpr(tspan.args[2], :tuple)) && length(tspan.args[2].args) == 2
        Expr(:tuple, tspan.args[2].args[1], tspan.args[2].args[2])
    else
        Expr(:tuple, 0, tspan.args[2])
    end
end

function _parsesolver(ops)
    @assert Meta.isexpr(ops, :vect) || Meta.isexpr(ops, :tuple)
    map(ops.args) do x
        @assert Meta.isexpr(x, :(=))
        Expr(:kw, x.args[1], x.args[2])
    end
end

"""
scope
"""

macro scope(system, var, solution)
    esc(:(scope($system, $(Expr(:quote, var)), $solution)))
end

