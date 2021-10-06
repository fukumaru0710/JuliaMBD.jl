module JuliaMBD

import DifferentialEquations
import Plots

include("TypeDef.jl")

include("Port.jl")
include("Line.jl")

include("predefined_blocks/AddBlock.jl")
include("predefined_blocks/GainBlock.jl")
include("predefined_blocks/IntegratorBlock.jl")
include("predefined_blocks/ModBlock.jl")
include("predefined_blocks/DivisionBlock.jl")
include("predefined_blocks/TrigonometricFunctionBlock.jl")
include("predefined_blocks/MathFunctionBlock.jl")

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

end
