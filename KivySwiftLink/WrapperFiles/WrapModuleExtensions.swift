import Foundation

extension WrapModule {
    var generateSwiftSendProtocol: String {
        var protocol_strings: [String] = []
        for cls in classes {
            var cls_protocols: [String] = []
            for function in cls.functions {
                if !function.has_option(option: .callback) && !function.has_option(option: .swift_func) {
                    //cls_protocols.append("- (\(pythonType2pyx(type: function.returns.type, options: [.objc])))\(function.name)\(function.export(options: [.objc, .header]));")
                    //cls_protocols.append("- (\(function.returns.objc_type))\(function.name)\(function.export(options: [.objc, .header]));")
                    let swift_return = "\(if: function.returns.type != .void, "-> \(function.returns.swift_type)", "")"
                    //let func_args = function.args.map{"\($0.name): \($0.name)"}.joined(separator: ", ")
                    cls_protocols.append("""
                        func \(function.name)(\(function.export(options: [.use_names, .swift, .protocols]))) \(swift_return)
                    """)
                }
            }
            //func set_\(cls.title)_Callback(_ callback: \(cls.title)Callbacks)
            var call_title = cls.title.titleCase()
            call_title.removeFirst()
            let protocol_string = """
            protocol \(cls.title)_Delegate {
                func set_\(cls.title)_Callback(callback: \(cls.title)PyCallback)
            \(cls_protocols.joined(separator: newLine))
            }
            
            private var \(cls.title.lowercased()): \(cls.title)_Delegate!
            
            """
            protocol_strings.append(protocol_string)
        }
        return protocol_strings.joined(separator: newLine)
    }
    
    var generateSwiftCallbackWrap: String {
        var rtn_strings: [String] = []
        
        for cls in classes {
            var call_title = cls.title.titleCase()
            call_title.removeFirst()
            let callback_title = "\(call_title)Callback"
            
            let functions = cls.functions.filter{$0.has_option(option: .callback)}
            let call_pointers = functions.map{ f -> String in
                let direct = f.options.contains(.direct)
                return "\(if: direct, "let ", "private let _")\(f.name): \(f.function_pointer)"
            }.joined(separator: newLineTab)
            let set_call_pointers = functions.map{"\(if: $0.options.contains(.direct), "", "_")\($0.name) = callback.\($0.name)"}.joined(separator: newLineTabTab)
            let call_funcs = functions.filter(
                {!$0.options.contains(.direct)}).map{ f -> String in
                    let _args = f.args.map{"\($0.swiftCallbackArgs)"}.joined(separator: ", ")
                    
                    return """
                    func \(f.name)(\(f.export(options: [.use_names, .swift, .protocols]))) {
                            _\(f.name)(\(_args))
                        }
                    """
            }
            rtn_strings.append("""
            struct \(cls.title)PyCallback {
                private let pycall: \(cls.title)Callbacks
                \(call_pointers)

                init(callback: \(cls.title)Callbacks){
                    pycall = callback
                    \(set_call_pointers)
                }
                
                \(call_funcs.joined(separator: newLineTab))
            }

            //var \(callback_title): \(cls.title)PyCallback!
            """)
        }
        return rtn_strings.joined(separator: newLine)
    }

    
    func generateSendFunctions(objc: Bool, header: Bool) -> String {
        var send_strings: [String] = []
        var send_options: [PythonTypeConvertOptions] = [.use_names]
        var return_options: [PythonTypeConvertOptions] = []
        if header {send_options.append(.header)}
        if objc {
            send_options.append(.objc)
            return_options.append(.objc)
        }
//        else {
//            send_options.append(.py_mode)
//        }
        
        
        for cls in classes {
            
            for function in cls.functions {
                if !function.has_option(option: .callback) && !function.has_option(option: .swift_func) {
                    let func_return_options = return_options
//                    if function.returns.has_option(.list) {
//                        func_return_options.append(.is_list)
//                    }
                    //let return_type = "\(pythonType2pyx(type: function.returns.type, options: return_options))"
                    //print(return_type)
                    let return_type2 = function.returns.convertPythonType(options: func_return_options)
                    var func_string = "\(return_type2) \(cls.title)_\(function.name)(\(function.export(options: send_options)))"
                    if objc { func_string.append(";") }
                    
                    send_strings.append(func_string)
                }
            }
        }
        if objc {
            return send_strings.joined(separator: newLine)
        } else {
            return send_strings.joined(separator: "\n\t")
        }
        
    }
    
    var generatePyxClassFunctions: String {
        var output: [String] = []
        
        for cls in classes {
            
            for function in cls.functions {
                if !function.has_option(option: .callback) {
                    let return_type = function.returns.type
                    var rtn: String
                    if return_type == .void {rtn = "None"} else {rtn = PurePythonTypeConverter(type: return_type)}
                    let py_return = "\(if: function.returns.has_option(.list),"list[\(rtn)]",rtn)"
                    output.append("\t"+"def \(function.name)(self, \(function.export(options: [.py_mode]))) -> \(py_return):")
                    //handle list args
                    let list_args = function.args.filter{$0.has_option(.list) && !$0.has_option(.codable)}
                    
                    for list_arg in list_args {
                        if list_arg.type == .str {
                            output.append(list_arg.strlistFunctionLine)
                        } else {
                            output.append(list_arg.listFunctionLine)
                        }
                        
                    }
                    //output.append(contentsOf: list_args.map{listFunctionLine(wrap_arg: $0)})
                    
                    let jsondata_args = function.args.filter{$0.type == .jsondata}
                    for json in jsondata_args {
                        output.append("\t\tcdef bytes j_\(json.name) = json.dumps(\(json.name)).encode()")
                        //output.append("\t\tcdef const unsigned char* __\(json.name) = _\(json.name)")
                        output.append("\t\tcdef long \(json.name)_size = len(j_\(json.name))")
                    }
                    let data_args = function.args.filter{$0.type == .data}
                    output.append(contentsOf: data_args.map{"\t\tcdef long \($0.name)_size = len(\($0.name))"})
                    let codable_args = function.args.filter { (arg) -> Bool in arg.has_option(.codable)}
                    output.append(contentsOf: codable_args.map({ (arg) -> String in
                        """
                                cdef bytes j_\(arg.name) = json.dumps(\(arg.name).__dict__).encode()
                                cdef long \(arg.name)_size = len(j_\(arg.name))
                        """
                    }))
                    output.append("\t\t" + generateFunctionCode(title: cls.title, function: function))
                    for arg in list_args {
                        if arg.type == .str {
    //                        output.append("""
    //                        for x in range(\(arg.name)_size)
    //                        """)
                        }
                        output.append("\t\tfree(\(arg.name)_array)")
                    }
                    output.append("")
                }
            }
        }
        return output.joined(separator: newLine)
    }
    
    
    func generateStruct(options: [StructTypeOptions]) -> String {
        var output: [String] = []
        var ending = ""
        let objc = options.contains(.objc)
        let swift_mode = options.contains(.swift_functions)
        let callback_mode = options.contains(.callbacks)
        if swift_mode {ending = "SwiftFuncs"}
        else if callback_mode {ending = "Callbacks"}
        else if options.contains(.swift) {ending = "Sends"}
        
        for cls in classes {
            var struct_args: [String] = []
            for function in cls.functions {
                if callback_mode {
                    if function.has_option(option: .callback) {
                        let arg = "\(function.function_pointer)\(if: objc, " _Nonnull") \(function.name)"
                        struct_args.append(arg)
                    }
                }
                
                else if swift_mode {
                    if function.has_option(option: .swift_func) && !function.has_option(option: .callback) {
                        let arg = "\(function.function_pointer)\(if: objc, " _Nonnull") \(function.name)"
                        struct_args.append(arg)
                    }
                }
                if options.contains(.swift) {
                    if !function.has_option(option: .callback) {
                        let arg = "\(function.function_pointer)\(if: objc, " _Nonnull") \(function.name)"
                        struct_args.append(arg)
                    }
                }
                
            }
            
            if options.contains(.swift) {
                if objc {
                    output.append(
                        """
                        typedef struct \(cls.title)\(ending) {
                            \(struct_args.joined(separator: ";\n\t"));
                        } \(cls.title)\(ending);
                        """
                    )
                } else {
                    output.append(
                        """
                        ctypedef struct \(cls.title)\(ending):
                            \t\(struct_args.joined(separator: newLineTabTab))
                        """
                    )
                }
                
            } else {
                if objc {
                    output.append(
                        """
                        typedef struct \(cls.title)\(ending) {
                            \(struct_args.joined(separator: ";\n\t"));
                        } \(cls.title)\(ending);
                        """
                    )
                } else {
                    output.append(
                    """
                    ctypedef struct \(cls.title)\(ending):
                        \t\(struct_args.joined(separator: newLineTabTab))
                    """
                    )
                }
            }
            
            
        }
        return output.joined(separator: newLineTab) + newLine
    }

    func generateCallbackFunctions(options: [PythonTypeConvertOptions]) -> String {
        var output: [String] = []
        //let objc = options.contains(.objc)
        //let header = options.contains(.header)
        for cls in classes {
            
            for function in cls.functions {
                
                if function.has_option(option: .callback) {
                    if options.contains(.objc) {
                        output.append(functionGenerator(wraptitle: cls.title, function: function, options: options))
    //                    output.append("""
    //                    //\(pythonType2pyx(type: function.returns.type, options: options)) \(cls.title)_\(function.name)(\(function.export(options: options));
    //                    """)
                    } else {
                        //var send_options = options
                        //send_options.append(.header)
                        output.append(functionGenerator(wraptitle: cls.title, function: function, options: options))
                    }
                    
                }
            }
        }
        return output.joined(separator: newLine + newLine)
    }
    
    func generateFunctionPointers(objc: Bool, options: [FunctionPointersOptions]) -> String {
        var tdef = ""
        if objc { tdef = "typedef" } else { tdef = "ctypedef"}
        var output: [String] = []
        
        var excluded_state = "false"
        if options.contains(.excluded_callbacks) {excluded_state = "true"}
        
        for cls in classes {
            for (_,function) in cls.pointer_compare_dict.sorted(by: { $0.1["name"]! < $1.1["name"]! }).filter({$0.1["excluded_callbacks"] != excluded_state}) {
                //let function = cls.pointer_compare_dict[key]!
                var key_value: String
                if objc {key_value = "objc_string"} else {key_value = "pyx_string"}
                var pointer_string = "\(tdef) \("void") (*\(function["name"]!))(\(function[key_value]!))"
                if objc {pointer_string.append(";")}
                output.append(pointer_string)
            }
        }
        if objc {
            return output.joined(separator: newLine)
        } else {
            return output.joined(separator: newLineTab)
        }
    }
}
