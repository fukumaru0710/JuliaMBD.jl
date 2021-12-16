using JuliaMBD
using Test
using DifferentialEquations
using Plots

@testset "XmlToJulia" begin
    f = open("DCMtest.xml", "r")
    data = read(f, String)
    close(f)
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
    eval(Meta.parse(toJulia(data)))

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

@testset "JuliaMBD_macro.jl" begin
    @xmlmodel "DCMtest.xml"

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

@testset "JuliaMBD_mxfile.jl" begin
    @xmlmodel "DCMexample.xml"

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

@testset "JuliaMBD_mxfile_intId.jl" begin
    @xmlmodel "DCMexample2.xml"

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

@testset "JuliaMBD_mxfile_3.jl" begin
    @xmlmodel "DCMexample3.xml"

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

@testset "JuliaMBD_compress.jl" begin
    @xmlmodel "DCMexample4.xml"

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

@testset "suion.jl" begin
    @xmlmodel "suion.xml"
end

@testset "ProductBlockTest" begin
    @model MotorDriver begin
        @parameter alpha_i
        
        @blk In1 = InBlock()
        @blk In2 = InBlock()
        @blk In3 = InBlock()
        @blk Gain = GainBlock(1/100)
        @blk Gain1 = GainBlock(alpha_i)
        #@blk Add = AddBlock([:+, :*]) inport[1]:in1 inport[2]:in2
        @blk Product = ProductBlock() inport[1]:in1 inport[2]:in2
        @blk Out = OutBlock()
        @blk Out1 = OutBlock()
        
        @connect In1 => in1
        @connect In2 => Gain
        @connect Gain => in2
        @connect Product => Out
        @connect In3 => Gain1
        @connect Gain1 => Out1
    end
        
    @model MDTest begin
        @parameter alpha_i u_M_d i_M_d Vs
        
        @blk Con = ConstantBlock(Vs)
        @blk Ramp = RampBlock(slope=u_M_d, starttime=0, initialoutput=0)
        @blk Ramp1 = RampBlock(slope=i_M_d, starttime=0, initialoutput=0)
        @blk MD = MotorDriver(alpha_i=alpha_i) inport[1]:Vs inport[2]:u_M inport[3]:i_M outport[1]:v_A outport[2]:v_i
        
        @connect Con => Vs
        @connect Ramp => u_M
        @connect Ramp1 => i_M
    end
    m = MDTest(alpha_i=5/37.5, u_M_d=10, i_M_d=3, Vs=24)
    sol = @simulate(m, tspan=(0.0, 10.0), scope=(v_A, Ramp, v_i, Ramp1))
    sol.graph
end

@testset "MotorDriverProductBlock.jl" begin
    @xmlmodel "MotorDriverP.xml"
end

@testset "SaturationTest.jl" begin
    @xmlmodel "SaturationTest.xml"
end

@testset "QuantizerTest.jl" begin
    f = open("QuantizerTest.xml", "r")
    data = read(f, String)
    close(f)
    println(toJulia(data))
    @xmlmodel "QuantizerTest.xml"

    @model ADConverterTest begin
        @parameter V_A_min V_A_max alpha_A

        @blk Ramp = RampBlock(slope=1, starttime=0, initialoutput=5)
        @blk ADC = ADConverter(V_A_min=V_A_min, V_A_max=V_A_max, alpha_A=alpha_A)

        @connect Ramp => ADC
    end
    m = ADConverterTest(V_A_min=0, V_A_max=0, alpha_A=(2^10 - 1)/5)
    sol = @simulate(m, tspan=(0.0, 10.0), scope=(Ramp, ADC))
    sol.graph    
end

