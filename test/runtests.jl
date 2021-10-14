using JuliaMBD
using Test
using DifferentialEquations
using Plots

@testset "XmlToJulia" begin
    f = open("DCMtest.xml", "r")
    data = read(f, String)
    close(f)
    #expr = Meta.parse(xmlToJulia.toJulia(data))
    println(toJulia(data))
end

@testset "JuliaSimulate" begin
    @model MSD begin
        @parameter M g k D

        @blk In = InBlock()
        @blk Consta = ConstantBlock(M*g)
        @blk Gain1 = GainBlock(D)
        @blk Gain2 = GainBlock(k)
        @blk Gain3 = GainBlock(1/M)
        @blk Inte = IntegratorBlock()
        @blk Inte1 = IntegratorBlock(initialcondition=M*g/k)
        @blk Out = OutBlock()

        @connect In + Consta - Gain1 - Gain2 => Gain3
        @connect Gain3 => Inte
        @connect Inte => Inte1
        @connect Inte => Gain1
        @connect Inte1 => Out
        @connect Inte1 => Gain2
    end

    @model MSDtest begin
        @parameter M g k D ff

        @blk MSDsys = MSD(M=M, g=g, k=k, D=D) outport:x
        @blk Pulse = PulseGeneratorBlock(amplitude=ff, period=20, pulsewidth=50) outport:f

        @connect Pulse => MSDsys
    end

    m = MSDtest(M=10, g=9.8, k=100, D=10, ff=10)
    sol = @simulate(m, tspan=(0.0, 60.0), scope=(x, f))
    sol.graph
end

@testset "JuliaMBD.jl" begin
    f = open("DCMtest.xml", "r")
    data = read(f, String)
    close(f)
    #println(toJulia(data))
    eval(toJulia(data))

    @model DCM_test begin
        @parameter R K_e K_tau J_M J_I D L v_M

        @blk Step = StepBlock(steptime=1, finalvalue=v_M) outport:v_M
        @blk DCMmodel = DCM(R=R, K_e=K_e, K_tau=K_tau, J_M=J_M, J_I=J_I, D=D, L=L) outport[1]:omega outport[2]:i_M

        @connect Step => DCMmodel
    end

    m = DCM_test(R=5.7, K_e=7.16e-2, K_tau=7.2e-2, J_M=0.11e-3, J_I=1.3e-3, D=6.0e-5, L=0.2, v_M=24)
    sol = @simulate(m, tspan=(0.0, 10.0), scope=(omega, i_M, v_M))
    sol.graph

end