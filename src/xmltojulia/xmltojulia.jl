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
    Value = Dict()
    Add = Dict()
    AddChild = Dict()
    Product = Dict()
    ProductChild = Dict()
    parameter = Dict()
    blk = Dict()
    connect = Dict()
    UpperLimit = Dict()
    LowerLimit = Dict()
    QuantizationInterval = Dict()
    #Option = Dict()

    ModelName = []
    Parameter = []
    Blk = []
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
            if Type[id] == "add"
                Add[id] = []
                AddChild[id] = []
            end
            if Type[id] == "sub"
                parameter[id] = data["parameter"]
            end
            if Type[id] == "product"
                Product[id] = []
                ProductChild[id] = []
            end
            if Type[id] == "saturation"
                UpperLimit[id] = []
                LowerLimit[id] = []
            end
            if Type[id] == "quantizer"
                QuantizationInterval[id] = []
            end
        end
        if haskey(data, "parent")
            Parent[id] = data["parent"]
            if haskey(Type, Parent[id])
                if Type[Parent[id]] == "add"
                    newid = replace.(id, "-"=>"")
                    push!(AddChild[Parent[id]], newid)
                end
                if Type[Parent[id]] == "product"
                    newid = replace.(id, "-"=>"")
                    push!(ProductChild[Parent[id]], newid)
                end
            end
        end
        if haskey(data, "vertex")
            Vertex[id] = data["vertex"]
        end
        if haskey(data, "value")
            Value[id] = data["value"]
            if Type[Parent[id]] == "add"
                push!(Add[Parent[id]], Value[id])
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

    function Parse(data, Id, Option)
        if haskey(data, "edge")
            ParseEdge(data, Id)
        end
        if haskey(data, "type")
            if Type[Id] == "sub"
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

    function ParseChild(data, Id, Option)
        if haskey(data, "vertex")
            ParseVertex(data, Id, Option)
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

    function ParseVertex(data, Id, Option)
        if haskey(Style[Id], "text")
            #println(Label[Id] * " text")
        elseif Type[Id] == "sub"
            push!(Parameter, parameter[Id])
            #println("@parameter " * parameter[Id])
        else
            #print(Type[Id] * "    ")
            #print("@blk ")
            if Type[Id] == "input"
                push!(Blk, BlockLabel[Id] * " = " * "InBlock()")
                #print(BlockLabel[Id] * " = " * "InBlock()")
            end
            if Type[Id] == "output"
                push!(Blk, BlockLabel[Id] * " = " * "OutBlock()")
                #print(BlockLabel[Id] * " = " * "OutBlock()")
            end
            if Type[Id] == "constant"
                push!(Blk, BlockLabel[Id] * " = " * "ConstantBlock(" * Label[Id] * ")")
                #print(BlockLabel[Id] * " = " * "ConstantBlock(" * Label[Id] * ")")
            end
            if Type[Id] == "gain"
                push!(Blk, BlockLabel[Id] * " = " * "GainBlock(" * Label[Id] * ")")
                #print(BlockLabel[Id] * " = " * "GainBlock(" * Label[Id] * ")")
            end
            if Type[Id] == "integrator"
                integratortext = BlockLabel[Id] * " = " * "IntegratorBlock("
                #push!(Blk, BlockLabel[Id] * " = " * "IntegratorBlock(" * ")")
                #print(BlockLabel[Id] * " = " * "IntegratorBlock(" * ")")
                if haskey(Option, "initialcondition")
                    integratortext = integratortext * "initialcondition=" * Option["initialcondition"]
                end
                integratortext = integratortext * ")"
                push!(Blk, integratortext)
            end
            if Type[Id] == "add"
                addtext = BlockLabel[Id] * " = " * "AddBlock(["
                #print(BlockLabel[Id] * " = " * "AddBlock([")
                for i in length(Add[Id]):-1:1
                    addtext = addtext * ":" * Add[Id][i]
                    #print(":" * Add[Id][i])
                    if i != 1
                        addtext = addtext * ", "
                        #print(", ")
                    end
                end
                addtext = addtext * "]) "
                #print("]) ")
                for i in length(Add[Id]):-1:1
                    addtext = addtext * "inport[" * string(length(Add[Id])-i+1) * "]:"
                    #print("inport[" * string(length(Add[Id])-i+1) * "]:")
                    ##print("In" * string(i) * " ")
                    addtext = addtext * "a" * AddChild[Id][i] * " "
                    #print(AddChild[Id][i] * " ")
                end
                #print(addtext)
                push!(Blk, addtext)
            end
            if Type[Id] == "product"
                producttext = BlockLabel[Id] * " = " * "ProductBlock() "
                for i in 2:-1:1
                    producttext = producttext * "inport[" * string(3-i) * "]:"
                    producttext = producttext * "a" * ProductChild[Id][3-i] * " "
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
        global Value = Dict()
        global Add = Dict()
        global AddChild = Dict()
        global Product = Dict()
        global ProductChild = Dict()
        global parameter = Dict()
        global blk = Dict()
        global connect = Dict()
        global UpperLimit = Dict()
        global LowerLimit = Dict()
        global QuantizationInterval = Dict()
        #Option = Dict()

        global ModelName = []
        global Parameter = []
        global Blk = []
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
            Option = Dict()
            Parse(cell, Id, Option)
            for child in eachelement(cell)
                ParseChild(child, Id, Option)
            end
        end
    
        io = IOBuffer()
        for j in 1:length(ModelName)
            write(io, "@model $(ModelName[j]) begin\n")
            for i in 1:length(Parameter)
                write(io, "@parameter $(Parameter[i])\n")
            end
            write(io, "\n")
            for i in 1:length(Blk)
                write(io, "@blk $(Blk[i])\n")
            end
            println()
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

