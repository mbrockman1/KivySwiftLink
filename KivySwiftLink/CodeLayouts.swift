//
//  CodeLayouts.swift
//  KivySwiftLink2
//
//  Created by MusicMaker on 16/10/2021.
//

import Foundation
func generateCythonClass(_class: String, class_vars: String, dispatch_mode: Bool) -> String {
    if dispatch_mode {
    return """
    cdef public void* \(_class)_voidptr
    cdef public void* \(_class)_dispatch
    cdef public \(_class) \(_class)_shared

    cdef class \(_class)(EventDispatcher) :
        \(class_vars)
        @staticmethod
        def shared():
            global \(_class)_shared
            if \(_class)_shared != None:
                return {\(_class)}_shared
            return None

        def __init__(self,object callback_class):
            global \(_class)_shared
            if \(_class)_shared == None:
                \(_class)_shared = self
            else:
                return
            global \(_class)_voidptr
            \(_class)_voidptr = <const void*>callback_class
    """}
    
    return """
    cdef public void* \(_class)_voidptr
    cdef public \(_class) \(_class)_shared

    cdef class \(_class):
        \(class_vars)
        @staticmethod
        def shared():
            global \(_class)_shared
            if \(_class)_shared != None:
                return {\(_class)}_shared
            return None

        def __init__(self,object callback_class):
            global \(_class)_shared
            if \(_class)_shared == None:
                \(_class)_shared = self
            else:
                return
            global \(_class)_voidptr
            \(_class)_voidptr = <const void*>callback_class
            
    """
}

func listFunctionLine(wrap_arg: WrapArg) -> String {
    let arg = wrap_arg.name
    let arg_type = wrap_arg.type
    let type_size = wrap_arg.size!
    let decode = ""
    return """
            cdef int \(arg)_size = len(\(arg))
            cdef \(arg_type) *\(arg)_array = <\(arg_type) *> malloc(\(arg)_size  * \(type_size))
            cdef int \(arg)_i
            for \(arg)_i in range(\(arg)_size):
                \(arg)_array[\(arg)_i] = \(decode)\(arg)[\(arg)_i]
    """
}
func strlistFunctionLine(wrap_arg: WrapArg) -> String {
    let arg = wrap_arg.name
    let arg_type = wrap_arg.type
    let type_size = wrap_arg.size!
    let decode = ""
    return """
            \(arg)_bytes = [x.encode('utf-8') for x in \(arg)]
            cdef int \(arg)_size = len(\(arg))
            cdef \(arg_type) *\(arg)_array = <\(arg_type) *> malloc(\(arg)_size  * \(type_size))
            cdef int \(arg)_i
            for \(arg)_i in range(\(arg)_size):
                \(arg)_array[\(arg)_i] = \(decode)\(arg)_bytes[\(arg)_i]
    """}

func generateCallbackFunctions(module: WrapModule, objc: Bool, header: Bool) -> String {
    var output: [String] = []

    for cls in module.classes {
        
        for function in cls.functions {
            
            if function.is_callback {
                if objc {
                    output.append("""
                    \(pythonType2pyx(type: function.returns.type, objc: objc)) \(cls.title)_\(function.name)(\(function.export(objc: objc, header: header));
                    """)
                } else {
                    output.append(functionGenerator(wraptitle: cls.title, function: function, objc: objc, header: header))
                }
                
            }
        }
    }
    return output.joined(separator: "\n")
}

func generateFunctionPointers(module: WrapModule, objc: Bool) -> String {
    var tdef = ""
    if objc { tdef = "typedef" } else { tdef = "ctypedef"}
    var output: [String] = []
    
    for cls in module.classes {
        for key in cls.pointer_compare_dict.keys.sorted() {
            let function = cls.pointer_compare_dict[key]!
            var key_value: String
            if objc {key_value = "objc_string"} else {key_value = "pyx_string"}
            var pointer_string = "\(tdef) \("void") (*\(function["name"]!))(\(function[key_value]!))"
            if objc {pointer_string.append(";")}
            output.append(pointer_string)
        }
    }
    if objc {
        return output.joined(separator: "\n")
    } else {
        return output.joined(separator: "\n\t")
    }
}



func generateStruct(module: WrapModule, ending: String, objc: Bool) -> String {
    var output: [String] = []
    
    
    for cls in module.classes {
        var struct_args: [String] = []
        for function in cls.functions {
            
            if function.is_callback {
                let arg = "\t\(function.function_pointer) \(function.name)"
                struct_args.append(arg)
            }
        }
        
        if objc {
            output.append(
                """
                typedef struct \(cls.title)\(ending) {
                \(struct_args.joined(separator: ";\n"));
                } \(cls.title)_Callback;
                """
            )
        } else {
            output.append(
            """
            ctypedef struct \(cls.title)\(ending):
                \(struct_args.joined(separator: "\n\t"))
            """
            )
        }
    }
    
    return output.joined(separator: "\n")
}


func generateSendProtocol(module: WrapModule) -> String {
    var protocol_strings: [String] = []
    for cls in module.classes {
        var cls_protocols: [String] = []
        for function in cls.functions {
            if !function.is_callback {
                cls_protocols.append("- (\(pythonType2pyx(type: function.returns.type, objc: true)))\(function.name)\(function.export(objc: true, header: true));")
            }
        }
        let protocol_string = """
        @protocol \(cls.title)_Delegate
        - (void)set_\(cls.title)_Callback:(struct \(cls.title)_Callback)callback;
        \(cls_protocols.joined(separator: "\n"))
        @end

        static id<\(cls.title)_Delegate> _Nonnull \(cls.title.lowercased());        
        """
        protocol_strings.append(protocol_string)
    }
    return protocol_strings.joined(separator: "\n")
}

enum SendFunctionOptions {
    case objc
    case python
}

func generateSendFunctions(module: WrapModule, objc: Bool) -> String {
    var send_strings: [String] = []
    for cls in module.classes {
        
        for function in cls.functions {
            if !function.is_callback && !function.swift_func {
                var func_string = "\(pythonType2pyx(type: function.returns.type, objc: objc)) \(cls.title)_\(function.name)(\(function.export(objc: objc, header: false, use_names: true)))"
                if objc { func_string.append(";") }
                send_strings.append(func_string)
            }
        }
    }
    if objc {
        return send_strings.joined(separator: "\n")
    } else {
        return send_strings.joined(separator: "\n\t")
    }
    
}

func generatePyxClassFunctions(module: WrapModule) -> String {
    var output: [String] = []
    
    for cls in module.classes {
        
        for function in cls.functions {
            if !function.is_callback {
                let return_type = function.returns.type
                var rtn: String
                if return_type == "void" {rtn = "None"} else {rtn = return_type}
                output.append("\t"+"def \(function.name)(\(function.export(objc: false, header: false, use_names: false, py_mode: true))) -> \(rtn):")
                let list_args = function.args.filter{$0.is_list}
                for arg in list_args {
                    output.append(listFunctionLine(wrap_arg: arg))
                }
                output.append("\t\t" + generateFunctionCode(title: cls.title, function: function))
                for arg in list_args {
                    output.append("\t\tfree(\(arg.name)_array)")
                }
                output.append("")
            }
        }
    }
    return output.joined(separator: "\n")
}

enum functionCodeType {
    case normal
    case python
    case cython
    case send
    case call
}

func generateFunctionCode(title: String, function: WrapFunction) -> String {
    var output: [String] = []
    if function.swift_func {
        output.append("self._\(function.name)_(\(function.send_args.joined(separator: ", ")))")
    } else {
        output.append("\(title)_\(function.name)(\(function.send_args.joined(separator: ", ")))")
    }
    
    return output.joined(separator: "\n\t")
}
func setCallPath(wraptitle: String, function: WrapFunction, options: [functionCodeType]) -> String {
    
    if call_class_is_arg(function: function) {
        if let call_target = function.call_target {
            return "(<object> \(function.call_class!)).\(call_target).\(function.name)"
        }
        return "(<object> \(function.call_class!)).\(function.name)"
    }
    
    if call_target_is_arg(function: function) {
        return "(<object> \(function.call_target!))"
    }
    
    if let call_class = function.call_class {
        if let call_target = function.call_target {
            return "(<object> \(call_class)_voidptr).\(call_target).\(function.name)"
        }
        return "(<object> \(call_class)_voidptr).\(function.name)"
    }
    return "(<object> \(wraptitle)_voidptr).\(function.name)"
}

func functionGenerator(wraptitle: String, function: WrapFunction, objc: Bool, header: Bool) -> String {
    var output: String
    if function.is_callback {
        
        let func_args = function.export(objc: objc, header: header)
        let return_type = pythonType2pyx(type: pythonType2pyx(type: function.returns.type, objc: objc), objc: objc)
        let call_path = setCallPath(wraptitle: wraptitle, function: function, options: [])
        output = """
        cdef \( return_type ) \(wraptitle)_\(function.name)(\(func_args)):
            \(call_path)(\(function.call_args.joined(separator: ", ")))
        """
    } else {
        output = "\(pythonType2pyx(type: function.returns.type, objc: objc)) \("abc"))(\(function.export(objc: objc, header: false, use_names: true)))"
        if objc { output.append(";") }
    }
    return output
}

func call_target_is_arg(function: WrapFunction) -> Bool {
    let args = function.args.map{$0.name}
    if let call_target = function.call_target {
        if args.contains(call_target) {
            return true
        }
    }
    return false
    
}

func call_class_is_arg(function: WrapFunction) -> Bool {
    let args = function.args.map{$0.name}
    if let call_class = function.call_class {
        if args.contains(call_class) {
            return true
        }
    }
    return false
}
func generateTypeDefImports(imports: [String]) -> String {
    let deftypes = get_typedef_types()
    var output: [String] = []
    for type in imports {
        //print(type)
        if deftypes.contains(type) {
            output.append("\(type)")
        }
    }
    return output.joined(separator: "\n\t")
}

enum CythonClassOptionTypes {
    case init_callstruct
    case event_dispatch
}

func extendCythonClass(cls: WrapClass, options: [CythonClassOptionTypes]) -> String {
    
    var output: [String] = []
    
    for t in options {
        switch t {
        case .init_callstruct:
            let string = """
                cdef PythonCoreMidiCallback callbacks = [
                    \(cls.functions.filter{$0.is_callback}.map({"\t\(cls.title)_\($0.name)"}).joined(separator: ",\n\t\t"))
                    ]
                    set_PythonCoreMidi_Callback(callbacks)
            """
            output.append(string)
        case .event_dispatch:
            ""
        }
    }
    
    return output.joined(separator: "\n\t")
}
