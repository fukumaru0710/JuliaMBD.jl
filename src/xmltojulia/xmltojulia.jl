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
            if Type[id] == "input"
                if haskey(data, "number")
                    Inblk[string(data["number"])] = BlockLabel[id]
                end
            end
            if Type[id] == "output"
                if haskey(data, "number")
                    Outblk[string(data["number"])] = BlockLabel[id]
                end
            end
            if Type[id] == "add"
                #Add[id] = []
                AddChild[id] = []
            end
            if Type[id] == "model"
                parameter[id] = data["parameter"]
            end
            if Type[id] == "product"
                ProductChild[id] = []
            end
            if Type[id] == "saturation"
                UpperLimit[id] = []
                LowerLimit[id] = []
            end
            if Type[id] == "quantizer"
                QuantizationInterval[id] = []
            end
            if Type[id] == "mod"
                ModChild[id] = []
            end
        end
        if haskey(data, "parent")
            Parent[id] = data["parent"]
            if haskey(Type, Parent[id])
                if Type[Parent[id]] == "add"
                    newid = replace.(id, "-"=>"")
                    newid = "a" * newid
                    push!(AddChild[Parent[id]], newid)
                end
                if Type[Parent[id]] == "product"
                    newid = replace.(id, "-"=>"")
                    newid = "a" * newid
                    push!(ProductChild[Parent[id]], newid)
                end
                if Type[Parent[id]] == "mod"
                    newid = replace.(id, "-"=>"")
                    newid = "a" * newid
                    push!(ModChild[Parent[id]], newid)
                end
            end
        end
        if haskey(data, "vertex")
            Vertex[id] = data["vertex"]
        end
        if haskey(data, "parameter")
            parameter[id] = data["parameter"]
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
        if haskey(data, "upperlimit")
            if data["upperlimit"] != ""
                UpperLimit[id] = data["upperlimit"]
            end
        end
        if haskey(data, "lowerlimit")
            if data["lowerlimit"] != ""
                LowerLimit[id] = data["lowerlimit"]
            end
        end
        if haskey(data, "quantizationinterval")
            if data["quantizationinterval"] != ""
                QuantizationInterval[id] = data["quantizationinterval"]
            end
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
            if Type[Id] == "integrator"
                #Option = Dict()
                #if data["initialcondition"] != ""
                #    Option["initialcondition"] = data["initialcondition"]
                    #println("op")
                #end
            end
        end
    end

    function ParseChild(data, Id)
        if haskey(data, "vertex")
            ParseVertex(data, Id)
        end
    end

    function ParseEdge(data, Id)
        if haskey(BlockLabel, Target[Id])
            push!(Connect, BlockLabel[Source[Id]] * " => " * BlockLabel[Target[Id]])
            #println("@connect " * BlockLabel[Source[Id]] * " => " * BlockLabel[Target[Id]])
        else
            #AddBlock、ProductBlock上の演算子の処理(+,-,・につなぐのでtargetにはならない)
            #println("@connect " * BlockLabel[Source[Id]] * " => " * BlockLabel[Parent[Target[Id]]] * " " * Value[Target[Id]])
            newtarget = replace.(Target[Id], "-"=>"")
            push!(Connect, BlockLabel[Source[Id]] * " => " * "a" * newtarget)
            #println("@connect " * BlockLabel[Source[Id]] * " => " * Target[Id])
        end
    end

    function ParseVertex(data, Id)
        if haskey(Style[Id], "text")
        elseif Type[Id] == "model"
            push!(Parameter, parameter[Id])
        else
            #=if Type[Id] == "input"
                push!(Blk, BlockLabel[Id] * " = " * "InBlock()")
            end
            if Type[Id] == "output"
                push!(Blk, BlockLabel[Id] * " = " * "OutBlock()")
            end=#
            if Type[Id] == "constant"
                push!(Blk, BlockLabel[Id] * " = " * "ConstantBlock(" * parameter[Id] * ")")
            end
            if Type[Id] == "gain"
                push!(Blk, BlockLabel[Id] * " = " * "GainBlock(" * parameter[Id] * ")")
            end
            if Type[Id] == "integrator"
                integratortext = BlockLabel[Id] * " = " * "IntegratorBlock("
                #push!(Blk, BlockLabel[Id] * " = " * "IntegratorBlock(" * ")")
                #print(BlockLabel[Id] * " = " * "IntegratorBlock(" * ")")
                #=if haskey(Option, "initialcondition")
                    integratortext = integratortext * "initialcondition=" * Option["initialcondition"]
                end
                integratortext = integratortext * ")"
                push!(Blk, integratortext)=#
            end
            if Type[Id] == "add"
                addtext = BlockLabel[Id] * " = " * "AddBlock() "
                for i in 2:-1:1
                    addtext = addtext * "inport[" * string(3-i) * "]:"
                    addtext = addtext * AddChild[Id][3-i] * " "
                end
                push!(Blk, addtext)
            end
            if Type[Id] == "product"
                producttext = BlockLabel[Id] * " = " * "ProductBlock() "
                for i in 2:-1:1
                    producttext = producttext * "inport[" * string(3-i) * "]:"
                    producttext = producttext * ProductChild[Id][3-i] * " "
                end
                push!(Blk, producttext)
            end
            if Type[Id] == "saturation"
                saturationtext = BlockLabel[Id] * " = " * "SaturationBlock("
                if UpperLimit[Id] != Any[]
                    saturationtext = saturationtext * "upperlimit=" * UpperLimit[Id]
                    if LowerLimit[Id] != Any[]
                        saturationtext = saturationtext * ", "
                    end
                end
                if LowerLimit[Id] != Any[]
                    saturationtext = saturationtext * "lowerlimit=" * LowerLimit[Id]
                end
                saturationtext = saturationtext * ")"
                push!(Blk, saturationtext)
            end
            if Type[Id] == "quantizer"
                quantizertext = BlockLabel[Id] * " = " * "QuantizerBlock("
                if QuantizationInterval[Id] != Any[]
                    quantizertext = quantizertext * "quantizationinterval=" * QuantizationInterval[Id]
                end
                quantizertext = quantizertext * ")"
                push!(Blk, quantizertext)
            end
            if Type[Id] == "mod"
                modtext = BlockLabel[Id] * " = " * "ModBlock() "
                for i in 2:-1:1
                    modtext = modtext * "inport[" * string(3-i) * "]:"
                    modtext = modtext * ModChild[Id][3-i] * " "
                end
                push!(Blk, modtext)
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