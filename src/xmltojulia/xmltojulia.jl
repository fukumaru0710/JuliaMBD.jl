module xmlToJulia

    using EzXML
    using Base64
    using Inflate
    using HTTP
    export toJulia

    Parent = Dict()
    BlockLabel = Dict()
    Type = Dict()
    Label = Dict()
    Style = Dict()
    Vertex = Dict()
    Edge = Dict()
    Target = Dict()
    Source = Dict()
    AddChild = Dict()
    SubChild = Dict()
    ProductChild = Dict()
    parameter = Dict()
    blk = Dict()
    Inblk = Dict()
    Outblk = Dict()
    connect = Dict()
    UpperLimit = Dict()
    LowerLimit = Dict()
    QuantizationInterval = Dict()
    ModChild = Dict()
    SystemChildIn = Dict()
    SystemChildOut = Dict()
    modelName = Dict()
    InitialCondition = Dict()
    Child = Dict()
    Slope = Dict()
    InitialOutput = Dict()
    StartTime = Dict()
    StepTime = Dict()
    InitialValue = Dict()
    FinalValue = Dict()
    Amplitude = Dict()
    Period = Dict()
    PulseWidth = Dict()
    PhaseDelay = Dict()

    #Option = Dict()

    ModelName = []
    Parameter = []
    Blk = []
    InBlock = []
    OutBlock = []
    Connect = []

    function GetId(data)
        data_Id = data["id"]
        return data_Id
    end

    function GetStyle(data)
        styles = Dict()
        if haskey(data, "style")
            data_Style = data["style"]
            #println("- ", mxCell_Style)
            for x in split(data_Style, ";")
                #println(x)
                e = split(x, "=")
                if length(e) == 1
                    #println("")
                    styles[e[1]] = ""
                elseif length(e) == 2
                    #println(e[2])
                    styles[e[1]] = e[2]
                else
                    println("Error: Style in Cell")
                end
            end
        end
        #println(styles)
        return styles
    end

    function GetData(data)
        id = data["id"]
        if haskey(data, "label")
            Label[id] = data["label"]
        end
        if haskey(data, "style")
            Style[id] = GetStyle(data)
        end
        if haskey(data, "blockLabel")
            BlockLabel[id] = data["blockLabel"]
        end
        if haskey(data, "type")
            Type[id] = data["type"]
            if Type[id] == "model"
                parameter[id] = data["parameter"]
            end
            if Type[id] == "input"
                BlockLabel[id] = "In" * BlockLabel[id]
                Inblk[string(data["blockLabel"])] = BlockLabel[id]
            end
            if Type[id] == "output"
                BlockLabel[id] = "Out" * BlockLabel[id]
                Outblk[string(data["blockLabel"])] = BlockLabel[id]
            end
            if Type[id] == "integrator"
                InitialCondition[id] = []
            end
            if Type[id] == "add"
                AddChild[id] = []
                Child[id] = []
            end
            if Type[id] == "sub"
                SubChild[id] = []
                Child[id] = []
            end
            if Type[id] == "product"
                ProductChild[id] = []
                Child[id] = []
            end
            if Type[id] == "mod"
                ModChild[id] = []
                Child[id] = []
            end
            if Type[id] == "system"
                parameter[id] = []
                SystemChildIn[id] = []
                SystemChildOut[id] = []
                modelName[id] = data["modelName"]
                Child[id] = []
            end
        end
        if haskey(data, "parent")
            Parent[id] = data["parent"]
            if haskey(Type, Parent[id])
                if Type[Parent[id]] == "add"
                    if string(data["value"][1]) == "i"
                        newid = replace.(id, "-"=>"")
                        newid = "a" * newid
                        if string(data["value"][2]) == "1"
                            pushfirst!(AddChild[Parent[id]], newid)
                        else
                            push!(AddChild[Parent[id]], newid)
                        end
                    end
                end
                if Type[Parent[id]] == "sub"
                    if string(data["value"][1]) == "i"
                        newid = replace.(id, "-"=>"")
                        newid = "a" * newid
                        if string(data["value"][2]) == "1"
                            pushfirst!(SubChild[Parent[id]], newid)
                        else
                            push!(SubChild[Parent[id]], newid)
                        end
                    end
                end
                if Type[Parent[id]] == "product"
                    if string(data["value"][1]) == "i"
                        newid = replace.(id, "-"=>"")
                        newid = "a" * newid
                        if string(data["value"][2]) == "1"
                            pushfirst!(ProductChild[Parent[id]], newid)
                        else
                            push!(ProductChild[Parent[id]], newid)
                        end
                    end
                end
                if Type[Parent[id]] == "mod"
                    if string(data["value"][1]) == "i"
                        newid = replace.(id, "-"=>"")
                        newid = "a" * newid
                        if string(data["value"][2]) == "1"
                            pushfirst!(ModChild[Parent[id]], newid)
                        else
                            push!(ModChild[Parent[id]], newid)
                        end
                    end
                end
                if Type[Parent[id]] == "system"
                    if string(data["value"][1]) == "i"
                        newid = replace.(id, "-"=>"")
                        newid = "a" * newid
                        push!(SystemChildIn[Parent[id]], newid)
                    end
                    if string(data["value"][1]) == "o"
                        newid = replace.(id, "-"=>"")
                        newid = "a" * newid
                        push!(SystemChildOut[Parent[id]], newid)
                    end
                end
            end
        end
        if haskey(data, "vertex")
            Vertex[id] = data["vertex"]
        end
        if haskey(data, "parameter")
            if Type[id] == "system"
                parameter[id] = split(data["parameter"])
            else
                parameter[id] = data["parameter"]
            end
        end
        if haskey(data, "edge")
            Edge[id] = data["edge"]
            if haskey(data, "target")
                Target[id] = data["target"]
            end
            if haskey(data, "source")
                Source[id] = data["source"]
            end
        end
        if haskey(data, "initialcondition")
                InitialCondition[id] = data["initialcondition"]
        end
        if haskey(data, "upperlimit")
                UpperLimit[id] = data["upperlimit"]
        end
        if haskey(data, "lowerlimit")
                LowerLimit[id] = data["lowerlimit"]
        end
        if haskey(data, "quantizationinterval")
                QuantizationInterval[id] = data["quantizationinterval"]
        end
        if haskey(data, "slope")
            Slope[id] = data["slope"]
        end
        if haskey(data, "initialoutput")
                InitialOutput[id] = data["initialoutput"]
        end
        if haskey(data, "starttime")
                StartTime[id] = data["starttime"]
        end
        if haskey(data, "steptime")
            StepTime[id] = data["steptime"]
        end
        if haskey(data, "initialvalue")
            InitialValue[id] = data["initialvalue"]
        end
        if haskey(data, "finalvalue")
            FinalValue[id] = data["finalvalue"]
        end
        if haskey(data, "amplitude")
            Amplitude[id] = data["amplitude"]
        end
        if haskey(data, "period")
            Period[id] = data["period"]
        end
        if haskey(data, "pulsewidth")
            PulseWidth[id] = data["pulsewidth"]
        end
        if haskey(data, "phasedelay")
            PhaseDelay[id] = data["phasedelay"]
        end
    end

    function GetDataChild(data, id)
        if haskey(data, "parent")
            Parent[id] = data["parent"]
        end
            if haskey(data, "style")
            Style[id] = GetStyle(data)
        end
        if haskey(data, "vertex")
            Vertex[id] = data["vertex"]
        end
    end

    function Parse(data, Id)
        if haskey(data, "edge")
            ParseEdge(data, Id)
        end
        if haskey(data, "type")
            if Type[Id] == "model"
                push!(ModelName, BlockLabel[Id])
            end
        end
    end

    function ParseChild(data, Id)
        if haskey(data, "vertex")
            ParseVertex(data, Id)
        end
    end

    function ParseEdge(data, Id)        
        if haskey(Child, Parent[Target[Id]])
            newtarget = replace.(Target[Id], "-"=>"")
            if Type[Parent[Source[Id]]] == "system"
                newsource = replace.(Source[Id], "-"=>"")
                push!(Connect, "a" * newsource * " => " * "a" * newtarget)
            else
                push!(Connect, BlockLabel[Parent[Source[Id]]] * " => " * "a" * newtarget)
            end
        else
            if Type[Parent[Source[Id]]] == "system"
                newsource = replace.(Source[Id], "-"=>"")
                push!(Connect, "a" * newsource * " => " * BlockLabel[Parent[Target[Id]]])
            else
                push!(Connect, BlockLabel[Parent[Source[Id]]] * " => " * BlockLabel[Parent[Target[Id]]])
            end
        end
    end

    function ParseVertex(data, Id)
        if haskey(Style[Id], "text")
        elseif Type[Id] == "model"
            push!(Parameter, parameter[Id])
        else
            if Type[Id] == "constant"
                push!(Blk, BlockLabel[Id] * " = " * "ConstantBlock(" * parameter[Id] * ")")
            end
            if Type[Id] == "ramp"
                ramptext = BlockLabel[Id] * " = " * "RampBlock("
                if Slope[Id] != ""
                    ramptext = ramptext * "slope=" * Slope[Id]
                end
                if StartTime[Id] != ""
                    ramptext = ramptext * "starttime=" * StartTime[Id]
                end
                if InitialOutput[Id] != ""
                    ramptext = ramptext * "initialoutput=" * InitialOutput[Id]
                end
                ramptext = ramptext * ")"
                push!(Blk, ramptext)
            end
            if Type[Id] == "step"
                steptext = BlockLabel[Id] * " = " * "StepBlock("
                if StepTime[Id] != ""
                    steptext = steptext * "steptime=" * StepTime[Id]
                end
                if InitialValue[Id] != ""
                    steptext = steptext * "initialvalue=" * InitialValue[Id]
                end
                if FinalValue[Id] != ""
                    steptext = steptext * "finalvalue=" * FinalValue[Id]
                end
                steptext = steptext * ")"
                push!(Blk, steptext)
            end
            if Type[Id] == "pulse"
                pulsetext = BlockLabel[Id] * " = " * "PulseGeneratorBlock("
                if Amplitude[Id] != ""
                    pulsetext = pulsetext * "amplitude=" * Amplitude[Id]
                end
                if Period[Id] != ""
                    pulsetext = pulsetext * "period=" * Period[Id]
                end
                if PulseWidth[Id] != ""
                    pulsetext = pulsetext * "pulsewidth=" * PulseWidth[Id]
                end
                if PhaseDelay[Id] != ""
                    pulsetext = pulsetext * "phasedelay=" * PhaseDelay[Id]
                end
                pulsetext = pulsetext * ")"
                push!(Blk, pulsetext)
            end
            if Type[Id] == "gain"
                push!(Blk, BlockLabel[Id] * " = " * "GainBlock(" * parameter[Id] * ")")
            end
            if Type[Id] == "integrator"
                integratortext = BlockLabel[Id] * " = " * "IntegratorBlock("
                if InitialCondition[Id] != ""
                    integratortext = integratortext * "initialcondition=" * InitialCondition[Id]
                end
                integratortext = integratortext * ")"
                push!(Blk, integratortext)
            end
            if Type[Id] == "add"
                addtext = BlockLabel[Id] * " = " * "AddBlock() "
                for i in 1:2
                    addtext = addtext * "inport[" * string(i) * "]:"
                    addtext = addtext * AddChild[Id][i] * " "
                end
                push!(Blk, addtext)
            end
            if Type[Id] == "sub"
                subtext = BlockLabel[Id] * " = " * "SubBlock() "
                for i in 1:2
                    subtext = subtext * "inport[" * string(i) * "]:"
                    subtext = subtext * SubChild[Id][i] * " "
                end
                push!(Blk, subtext)
            end
            if Type[Id] == "product"
                producttext = BlockLabel[Id] * " = " * "ProductBlock() "
                for i in 1:2
                    producttext = producttext * "inport[" * string(i) * "]:"
                    producttext = producttext * ProductChild[Id][i] * " "
                end
                push!(Blk, producttext)
            end
            if Type[Id] == "saturation"
                saturationtext = BlockLabel[Id] * " = " * "SaturationBlock("
                if UpperLimit[Id] != ""
                    saturationtext = saturationtext * "upperlimit=" * UpperLimit[Id]
                    if LowerLimit[Id] != ""
                        saturationtext = saturationtext * ", "
                    end
                end
                if LowerLimit[Id] != ""
                    saturationtext = saturationtext * "lowerlimit=" * LowerLimit[Id]
                end
                saturationtext = saturationtext * ")"
                push!(Blk, saturationtext)
            end
            if Type[Id] == "quantizer"
                quantizertext = BlockLabel[Id] * " = " * "QuantizerBlock("
                if QuantizationInterval[Id] != ""
                    quantizertext = quantizertext * "quantizationinterval=" * QuantizationInterval[Id]
                end
                quantizertext = quantizertext * ")"
                push!(Blk, quantizertext)
            end
            if Type[Id] == "mod"
                modtext = BlockLabel[Id] * " = " * "ModBlock() "
                for i in 1:2
                    modtext = modtext * "inport[" * string(i) * "]:"
                    modtext = modtext * ModChild[Id][i] * " "
                end
                push!(Blk, modtext)
            end
            if Type[Id] == "system"
                systemtext = BlockLabel[Id] * " = " * modelName[Id] * "("
                for i in 1:length(parameter[Id])
                    systemtext = systemtext * parameter[Id][i] * "=" * parameter[Id][i]
                    if i == length(parameter[Id])
                    else
                        systemtext = systemtext * ", "
                    end
                end
                systemtext = systemtext * ")"
                for i in 1:length(SystemChildIn[Id])
                    systemtext = systemtext * " inport[" * string(i) * "]:" * SystemChildIn[Id][i]
                end
                for i in 1:length(SystemChildOut[Id])
                    systemtext = systemtext * " outport[" * string(i) * "]:" * SystemChildOut[Id][i]
                end
                push!(Blk, systemtext)
            end
        end
    end

    function ParseVertexIn()
        for i in 1:length(Inblk)
            if haskey(Inblk, string(i))
                intext = Inblk[string(i)] * " = " * "InBlock()"
                push!(InBlock, intext)
            end
        end
    end

    function ParseVertexOut()
        for i in 1:length(Outblk)
            if haskey(Outblk, string(i))
                outtext = Outblk[string(i)] * " = " * "OutBlock()"
                push!(OutBlock, outtext)
            end
        end
    end

    function init()
        global Parent = Dict()
        global BlockLabel = Dict()
        global Type = Dict()
        global Label = Dict()
        global Style = Dict()
        global Vertex = Dict()
        global Edge = Dict()
        global Target = Dict()
        global Source = Dict()
        global AddChild = Dict()
        global ProductChild = Dict()
        global parameter = Dict()
        global blk = Dict()
        global Inblk = Dict()
        global Outblk = Dict()
        global connect = Dict()
        global UpperLimit = Dict()
        global LowerLimit = Dict()
        global QuantizationInterval = Dict()
        global ModChild = Dict()
        global SystemChildIn = Dict()
        global SystemChildOut = Dict()
        global modelName = Dict()
        global InitialCondition = Dict()
        global Child = Dict()
        global Slope = Dict()
        global InitialOutput = Dict()
        global StartTime = Dict()
        #Option = Dict()

        global ModelName = []
        global Parameter = []
        global Blk = []
        global InBlock = []
        global OutBlock = []
        global Connect = []
    end

    function toJulia(s)
        init()
        xml = parsexml(s)
        mx = xml.root
        if haskey(mx, "dx")
            ro = elements(mx)[1]
        else
            for com in eachelement(mx)
                global mxgraph = nodecontent(com)
            end
            dec = base64decode(mxgraph)
            if dec == UInt8[]
                dia = elements(mx)[1]
                mxg = elements(dia)[1]
                ro = elements(mxg)[1]
            else
                dec_inflate = inflate(dec)
                dec_string = String(dec_inflate)
                dec_uris = HTTP.URIs.unescapeuri(dec_string)
                xml_dec = parsexml(dec_uris)
                mx_dec = xml_dec.root
                ro = elements(mx_dec)[1]
            end
        end

        for cell in eachelement(ro)
            GetData(cell)
            Id = GetId(cell)
            for child in eachelement(cell)
                #print("-")
                GetDataChild(child, Id)
            end
            #println("-----")
        end

        for cell in eachelement(ro)
            Id = GetId(cell)
            Parse(cell, Id)
            for child in eachelement(cell)
                ParseChild(child, Id)
            end
        end
        ParseVertexIn()
        ParseVertexOut()
    
        io = IOBuffer()
        for j in 1:length(ModelName)
            write(io, "@model $(ModelName[j]) begin\n")
            for i in 1:length(Parameter)
                write(io, "@parameter $(Parameter[i])\n")
            end
            write(io, "\n")
            for i in 1:length(InBlock)
                write(io, "@blk $(InBlock[i])\n")
            end
            for i in 1:length(Blk)
                write(io, "@blk $(Blk[i])\n")
            end
            for i in 1:length(OutBlock)
                write(io, "@blk $(OutBlock[i])\n")
            end
            write(io, "\n")
            for i in 1:length(Connect)
                write(io, "@connect $(Connect[i])\n")
            end
            write(io, "end\n")
        end
        str = String(take!(io))
        close(io)
        str
    end

    
end