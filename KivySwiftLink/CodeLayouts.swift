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
        def default(call: object):
            global \(_class)_shared
            if \(_class)_shared != None:
                return {\(_class)}_shared
            else:
                \(_class)_shared = \(_class)(call)
                return \(_class)_shared

        def __init__(self,object callback_class):
            global \(_class)_voidptr
            \(_class)_voidptr = <const void*>callback_class
            #print("{call_var} init:", (<object>{call_var}))
    """}
    
    return """
    cdef public void* \(_class)_voidptr
    cdef public \(_class) \(_class)_shared

    cdef class \(_class):
        \(class_vars)
        @staticmethod
        def default(call: object):
            global \(_class)_shared
            if \(_class)_shared != None:
                return {\(_class)}_shared
            else:
                \(_class)_shared = \(_class)(call)
                return \(_class)_shared

        def __init__(self,object callback_class):
            global \(_class)_voidptr
            \(_class)_voidptr = <const void*>callback_class
            #print("{call_var} init:", (<object>{call_var}))
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
    return output.joined(separator: "\n\t")
}

func generateFunctionPointers(module: WrapModule, objc: Bool) -> String {
    var tdef = ""
    if objc { tdef = "typedef" } else { tdef = "ctypedef"}
    var output: [String] = []
    
    for cls in module.classes {
        for function in cls.pointer_compare_dict {
            var key_value: String
            if objc {key_value = "objc_string"} else {key_value = "pyx_string"}
            var pointer_string = "\(tdef) \("void") (*\(function.value["name"]!))(\(function.value[key_value]!))"
            if objc {pointer_string.append(";")}
            output.append(pointer_string)
        }
//        for function in cls.functions {
//            if function.is_callback {
//                var pointer_string = "\(tdef) \("void") (*\(function.function_pointer))(\(function.export(objc: objc, header: false)))"
//                if objc {pointer_string.append(";")}
//                output.append(pointer_string)
//            }
//        }
    }
    if objc {
        return output.joined(separator: "\n")
    } else {
        return output.joined(separator: "\n\t")
    }
}



func generateStruct(module: WrapModule, objc: Bool) -> String {
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
                typedef struct \(cls.title)_Callback {
                \(struct_args.joined(separator: ";\n"));
                } \(cls.title)_Callback;
                """
            )
        } else {
            output.append(
            """
            ctypedef struct \(cls.title)_Callback:
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


func generateSendFunctions(module: WrapModule, objc: Bool) -> String {
    var send_strings: [String] = []
    for cls in module.classes {
        
        for function in cls.functions {
            if !function.is_callback {
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
            }
        }
    }
    return output.joined(separator: "\n")
}

func generateFunctionCode(title: String, function: WrapFunction) -> String {
    var output: [String] = []
    
    output.append("\(title)_\(function.name)(\(function.send_args.joined(separator: ", ")))\n")
    return output.joined(separator: "\n\t")
}


func functionGenerator(wraptitle: String, function: WrapFunction, objc: Bool, header: Bool) -> String {
    var output: String
    if function.is_callback {
        output = """
        cdef \(pythonType2pyx(type: pythonType2pyx(type: function.returns.type, objc: objc), objc: objc) ) \(wraptitle)_\(function.name)(\(function.export(objc: objc, header: header)):
            \t(<object> \(wraptitle)_voidptr).\(function.export(objc: objc, header: header))
        """
    } else {
        output = "\(pythonType2pyx(type: function.returns.type, objc: objc)) \(wraptitle)_\(function.name)(\(function.export(objc: objc, header: false, use_names: true)))"
        if objc { output.append(";") }
    }
    return output
}
