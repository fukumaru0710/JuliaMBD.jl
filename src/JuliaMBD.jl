module JuliaMBD

import DifferentialEquations
import Plots

export toJulia, @xmlmodel, @modelcontents

include("TypeDef.jl")

include("Port.jl")
include("Line.jl")

include("predefined_blocks/AddBlock.jl")
include("predefined_blocks/SubBlock.jl")
include("predefined_blocks/GainBlock.jl")
include("predefined_blocks/IntegratorBlock.jl")
include("predefined_blocks/ModBlock.jl")
include("predefined_blocks/DivisionBlock.jl")
include("predefined_blocks/TrigonometricFunctionBlock.jl")
include("predefined_blocks/MathFunctionBlock.jl")
include("predefined_blocks/ProductBlock.jl")

include("predefined_blocks/ConstantBlock.jl")
include("predefined_blocks/StepBlock.jl")
include("predefined_blocks/RampBlock.jl")
include("predefined_blocks/PulseGeneratorBlock.jl")
include("predefined_blocks/SaturationBlock.jl")
include("predefined_blocks/QuantizerBlock.jl")

include("predefined_blocks/InBlock.jl")
include("predefined_blocks/OutBlock.jl")

include("SystemBlock.jl")
include("SimMacro.jl")

include("xmltojulia/xmltojulia.jl")

import .xmlToJulia

function toJulia(s)
    xmlToJulia.toJulia(s)
end

macro xmlmodel(fn)
    expr = quote
        f = open($fn, "r")
        data = read(f, String)
        close(f)
        expr = Meta.parse(toJulia(data))
        eval(expr)
    end
esc(expr)
end

macro modelcontents(fn)
    expr2 = quote
        f = open($fn, "r")
        data = read(f, String)
        close(f)
        println(toJulia(data))
    end
end

end