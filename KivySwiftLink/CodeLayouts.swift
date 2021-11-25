//
//  CodeLayouts.swift
//  KivySwiftLink2
//
//  Created by MusicMaker on 16/10/2021.
//
import SwiftyJSON
import Foundation
func generateCythonClass(_class: String, class_vars: String, dispatch_mode: Bool) -> String {
    if dispatch_mode {
    let string = """
    cdef public void* \(_class)_voidptr
    cdef public void* \(_class)_dispatch
    cdef public \(_class) \(_class)_shared

    cdef class \(_class)(EventDispatcher):
    \(class_vars)
        @staticmethod
        def shared():
            global \(_class)_shared
            if \(_class)_shared != None:
                return \(_class)_shared
            return None

        def __init__(self,object callback_class):
            global \(_class)_shared
            if \(_class)_shared == None:
                \(_class)_shared = self
            global \(_class)_voidptr
            \(_class)_voidptr = <const void*>callback_class
    """
        
        return string.replacingOccurrences(of: "    ", with: "\t")
    }
    
    
    return """
    cdef public void* \(_class)_voidptr
    cdef public \(_class) \(_class)_shared

    cdef class \(_class):
    \(class_vars)
        @staticmethod
        def shared():
            global \(_class)_shared
            if \(_class)_shared != None:
                return \(_class)_shared

        def __init__(self,object callback_class):
            global \(_class)_shared
            if \(_class)_shared == None:
                \(_class)_shared = self
            global \(_class)_voidptr
            \(_class)_voidptr = <const void*>callback_class
            
    """
}


enum CythonClassOptionTypes {
    case init_callstruct
    case event_dispatch
    case swift_functions
}

func extendCythonClass(cls: WrapClass, options: [CythonClassOptionTypes]) -> String {
    
    var output: [String] = []
    
    for t in options {
        switch t {
        case .init_callstruct:
            let string = """
                cdef \(cls.title)Callbacks callbacks = [
                    \(cls.functions.filter{$0.is_callback}.map({"\t\(cls.title)_\($0.name)"}).joined(separator: ",\n\t\t"))
                    ]
                    set_\(cls.title)_Callback(callbacks)
            """
            output.append(string)
        case .event_dispatch:
            
            output.append("")
        case .swift_functions:
            let func_string = cls.functions.filter{$0.swift_func && !$0.is_callback}.map{"self._\($0.name)_ = func_struct.\($0.name)"}.joined(separator: "\n\t\t")
            output.append("""
            cdef set_swift_functions(self, \(cls.title)SwiftFuncs func_struct ):
                    \(func_string)
                    print("set_swift_functions")

            """)
        
        }
    }
    
    return output.joined(separator: "\n\t")
}

enum EnumGeneratorOptions {
    case cython
    case objc
    case dispatch_events
}

func generateEnums(cls: WrapClass, options: [EnumGeneratorOptions]) -> String {
    var string: [String] = []
    for option in options {
        if option == .dispatch_events {
            if let dis_dec = cls.decorators.filter({$0.type=="EventDispatch"}).first {
                let events = (dis_dec.dict[0]["events"] as! [String])
                if options.contains(.cython) {
                    string.append("""
                    ctypedef enum \(cls.title)Events:
                        \(tab + events.joined(separator: newLineTabTab))

                    """)
                }
                if options.contains(.objc) {
                    string.append("""
                    typedef NS_ENUM(NSUInteger, \(cls.title)Events) {
                        \(events.joined(separator: "," + newLineTab))
                    };
                    """)
                }
            }
            
            
        }
    }
    return string.joined(separator: newLineTab)
}


func listFunctionLine(wrap_arg: WrapArg) -> String {
    let arg = wrap_arg.name
    let arg_type = convertPythonType(type: wrap_arg.type, options: [])
    if let size = wrap_arg.size {} else {print(wrap_arg.type)}
    let type_size = wrap_arg.size!
    let decode = "\(if: wrap_arg.type == "object", "<PythonObject>")"
    return """
            cdef int \(arg)_size = len(\(arg))
            cdef \(arg_type)* \(arg)_array = <\(arg_type)*> malloc(\(arg)_size  * \(type_size))
            cdef int \(arg)_i
            for \(arg)_i in range(\(arg)_size):
                \(arg)_array[\(arg)_i] = \(decode)\(arg)[\(arg)_i]
            cdef \(wrap_arg.pyx_type!) \(arg)_struct = [\(arg)_array, \(arg)_size]
    """
}

func dataFunctionLine(wrap_arg: WrapArg) -> String {
    let arg = wrap_arg.name
    let arg_type = convertPythonType(type: wrap_arg.type, options: [])
    let type_size = wrap_arg.size!
    let decode = ""
    return """
            cdef int \(arg)_size = len(\(arg))
            cdef \(arg_type)* \(arg)_array = <\(arg_type)*> malloc(\(arg)_size  * \(type_size))
            cdef int \(arg)_i
            for \(arg)_i in range(\(arg)_size):
                \(arg)_array[\(arg)_i] = \(decode)\(arg)[\(arg)_i]
    """
}


func strlistFunctionLine(wrap_arg: WrapArg) -> String {
    let arg = wrap_arg.name
    let arg_type = convertPythonType(type: wrap_arg.type, options: [])
    let type_size = wrap_arg.size!
    let decode = ""
    return """
            \(arg)_bytes = [x.encode('utf-8') for x in \(arg)]
            cdef int \(arg)_size = len(\(arg))
            cdef \(arg_type)*\(arg)_array = <\(arg_type) *> malloc(\(arg)_size  * \(type_size))
            cdef int \(arg)_i
            for \(arg)_i in range(\(arg)_size):
                \(arg)_array[\(arg)_i] = \(decode)\(arg)_bytes[\(arg)_i]
    """}

func generateCallbackFunctions(module: WrapModule, options: [PythonTypeConvertOptions]) -> String {
    var output: [String] = []
    //let objc = options.contains(.objc)
    //let header = options.contains(.header)
    for cls in module.classes {
        
        for function in cls.functions {
            
            if function.is_callback {
                if options.contains(.objc) {
                    output.append(functionGenerator(wraptitle: cls.title, function: function, options: options))
//                    output.append("""
//                    //\(pythonType2pyx(type: function.returns.type, options: options)) \(cls.title)_\(function.name)(\(function.export(options: options));
//                    """)
                } else {
                    var send_options = options
                    //send_options.append(.header)
                    output.append(functionGenerator(wraptitle: cls.title, function: function, options: options))
                }
                
            }
        }
    }
    return output.joined(separator: newLine + newLine)
}

enum FunctionPointersOptions {
    case exclude_swift_func
    case exclude_callback
    case excluded_callbacks
    case excluded_callbacks_only
}

func generateFunctionPointers(module: WrapModule, objc: Bool, options: [FunctionPointersOptions]) -> String {
    var tdef = ""
    if objc { tdef = "typedef" } else { tdef = "ctypedef"}
    var output: [String] = []
    
    var excluded_state = "false"
    if options.contains(.excluded_callbacks) {excluded_state = "true"}
    
    for cls in module.classes {
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

enum StructTypeOptions {
    case pyx
    case objc
    
    case callbacks
    case event_dispatch
    case swift_functions
}

func generateStruct(module: WrapModule, options: [StructTypeOptions]) -> String {
    var output: [String] = []
    var ending = ""
    let objc = options.contains(.objc)
    let swift_mode = options.contains(.swift_functions)
    let callback_mode = options.contains(.callbacks)
    if swift_mode {ending = "SwiftFuncs"} else if callback_mode {ending = "Callbacks"}
    
    for cls in module.classes {
        var struct_args: [String] = []
        for function in cls.functions {
            if callback_mode {
                if function.is_callback {
                    let arg = "\t\(function.function_pointer)\(if: objc, " _Nonnull") \(function.name)"
                    struct_args.append(arg)
                }
            }
            
            else if swift_mode {
                if function.swift_func && !function.is_callback {
                    let arg = "\t\(function.function_pointer)\(if: objc, " _Nonnull") \(function.name)"
                    struct_args.append(arg)
                }
            }
            
        }
        
        
        
        if objc {
            output.append(
                """
                typedef struct \(cls.title)\(ending) {
                \(struct_args.joined(separator: ";\n"));
                } \(cls.title)\(ending);
                """
            )
        } else {
            output.append(
            """
            ctypedef struct \(cls.title)\(ending):
            \t\(struct_args.joined(separator: "\n\t"))
            """
            )
        }
    }
    return output.joined(separator: newLineTab) + newLine
}


func generateSendProtocol(module: WrapModule) -> String {
    var protocol_strings: [String] = []
    for cls in module.classes {
        var cls_protocols: [String] = []
        for function in cls.functions {
            if !function.is_callback && !function.swift_func {
                //cls_protocols.append("- (\(pythonType2pyx(type: function.returns.type, options: [.objc])))\(function.name)\(function.export(options: [.objc, .header]));")
                cls_protocols.append("- (\(function.returns.objc_type!))\(function.name)\(function.export(options: [.objc, .header]));")

            }
        }
        let protocol_string = """
        @protocol \(cls.title)_Delegate 
        - (void)set_\(cls.title)_Callback:(struct \(cls.title)Callbacks)callback;
        \(cls_protocols.joined(separator: newLine))
        @end

        static id<\(cls.title)_Delegate> _Nonnull \(cls.title.lowercased());        
        """
        protocol_strings.append(protocol_string)
    }
    return protocol_strings.joined(separator: newLine)
}

enum SendFunctionOptions {
    case objc
    case python
}

func generateSendFunctions(module: WrapModule, objc: Bool) -> String {
    var send_strings: [String] = []
    var send_options: [PythonTypeConvertOptions] = [.use_names]
    var return_options: [PythonTypeConvertOptions] = []
    if objc {
        send_options.append(.objc)
        return_options.append(.objc)
    }
    
    
    for cls in module.classes {
        
        for function in cls.functions {
            if !function.is_callback && !function.swift_func {
                var func_return_options = return_options
                if function.returns.is_list {
                    func_return_options.append(.is_list)
                }
                let return_type = "\(pythonType2pyx(type: function.returns.type, options: return_options))"
                //print(return_type)
                let return_type2 = convertPythonType(type: function.returns.type, options: func_return_options)
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




func generatePyxClassFunctions(module: WrapModule) -> String {
    var output: [String] = []
    
    for cls in module.classes {
        
        for function in cls.functions {
            if !function.is_callback {
                let return_type = function.returns.type
                var rtn: String
                if return_type == "void" {rtn = "None"} else {rtn = PurePythonTypeConverter(type: return_type)}
                let py_return = "\(if: function.returns.is_list,"list[\(rtn)]",rtn)"
                output.append("\t"+"def \(function.name)(self, \(function.export(options: [.py_mode]))) -> \(py_return):")
                //handle list args
                let list_args = function.args.filter{$0.is_list}
                
                for list_arg in list_args {
                    if list_arg.type == "str" {
                        output.append(strlistFunctionLine(wrap_arg: list_arg))
                    } else {
                        output.append(listFunctionLine(wrap_arg: list_arg))
                    }
                    
                }
                //output.append(contentsOf: list_args.map{listFunctionLine(wrap_arg: $0)})
                
                let jsondata_args = function.args.filter{$0.type=="jsondata"}
                for json in jsondata_args {
                    output.append("\t\tcdef bytes j_\(json.name) = json.dumps(\(json.name)).encode()")
                    //output.append("\t\tcdef const unsigned char* __\(json.name) = _\(json.name)")
                    output.append("\t\tcdef long \(json.name)_size = len(j_\(json.name))")
                }
                let data_args = function.args.filter{$0.type=="data"}
                output.append(contentsOf: data_args.map{"\t\tcdef long \($0.name)_size = len(\($0.name))"})
                
                output.append("\t\t" + generateFunctionCode(title: cls.title, function: function))
                for arg in list_args {
                    if arg.type == "str" {
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

enum functionCodeType {
    case normal
    case python
    case cython
    case objc
    case send
    case call
}

func generateFunctionCode(title: String, function: WrapFunction) -> String {
    var output: [String] = []
    if function.swift_func {
        output.append("self._\(function.name)_(\(function.send_args.joined(separator: ", ")))")
    } else {
        if function.is_callback {
            output.append("\(title)_\(function.name)(\(function.send_args.joined(separator: ", ")))")
        } else { // sends
            
            if function.returns.type != "void" {
                let rtn = function.returns
                let rname = "\(title)_\(function.name)"
                let code = "\(rname)(\(function.send_args_py.joined(separator: ", ")))"
//                if rtn.is_data || rtn.is_list {
//                    output.append("cdef long \(rname)_size = len(\(rname))")
//                }
                output.append("cdef \(rtn.pyx_type!) rtn_val = \(code)")
                output.append("return \(convertReturnSend(f: function, rname: rname, code: code))")
            } else {
                output.append("\(title)_\(function.name)(\(function.send_args_py.joined(separator: ", ")))")
            }
        }
        
    }
    
    return output.joined(separator: "\n\t\t")
}
func setCallPath(wraptitle: String, function: WrapFunction, options: [functionCodeType]) -> String {
    if function.swift_func {
        return "\(wraptitle)_shared.\(function.name)"
    }
    
    
    
    if call_class_is_arg(function: function) {
        if let call_target = function.call_target {
            let target = function.get_callArg(name: function.call_class)
            return "(<object> \(target!.objc_name!)).\(call_target).\(function.name)"
        }
        let target = function.get_callArg(name: function.call_class)
        return "(<object> \(target!.objc_name!)).\(function.name)"
    }
    
    if call_target_is_arg(function: function) {
        return "(<object> \(function.get_callArg(name: function.call_target)!.objc_name!))"
    }
    
    if let call_class = function.call_class {
        if let call_target = function.call_target {
            return "(<object> \(call_class)_voidptr).\(call_target).\(function.name)"
        }
        return "(<object> \(call_class)_voidptr).\(function.name)"
    }
    return "(<object> \(wraptitle)_voidptr).\(function.name)"
}

func functionGenerator(wraptitle: String, function: WrapFunction, options: [PythonTypeConvertOptions]) -> String {
    var output: String
    let objc = options.contains(.objc)
    //print("functionGenerator", wraptitle, function.name, options)
    if function.is_callback {
        var call_args: [String]
        if options.contains(.header) {call_args = function.call_args(cython_callback: true )} else {call_args = function.call_args(cython_callback: false)}
        let func_args = function.export(options: options)
        let call_path = setCallPath(wraptitle: wraptitle, function: function, options: [.cython])
        let return_type = pythonType2pyx(type: function.returns.type, options: options)

        //let return_type = pythonType2pyx(type: pythonType2pyx(type: function.returns.type, options: options), options: options)
        //print("call_args", call_args)
        
        output = """
        cdef \( return_type ) \(wraptitle)_\(function.name)(\(func_args)) with gil:
        \t\(call_path)(\(call_args.joined(separator: ", ")))
        """
    } else {
        output = "\(pythonType2pyx(type: function.returns.type, options: options)) \("abc"))(\(function.export(options: options)))"
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
func generateTypeDefImports(imports: [WrapArg]) -> String {
    //let deftypes = get_typedef_types()
    var output: [String] = ["cdef extern from \"wrapper_typedefs.h\":"]
    if imports.count == 0 {return ""}
    var imps = imports
    imps.sort {
        !$0.is_list && $1.is_list
    }
    for arg in imps {
        let list = arg.is_list!
        let data = arg.is_data!
        let jsondata = arg.type == "jsondata"
        
        //print("generateTypeDefImports",arg.type, list, data)
        let dtype = pythonType2pyx(type: arg.type, options: [.c_type])
        //
        if list || data || jsondata {
            if list && (data || jsondata) {
                output.append("""
                    ctypedef struct \(arg.pyx_type!):
                        const \(convertPythonType(type: arg.type, options: [.objc]))\(if: list, "*") ptr
                        long size;
                
                """)
            } else {
                
                if arg.is_list && ["object","str"].contains(arg.type) {
                    output.append("""
                        ctypedef struct \(arg.pyx_type!):
                            const \(convertPythonType(type: arg.type, options: [])) * ptr
                            long size;
                    
                    """)
                } else {
                    // Normal types / lists with normal types
                    //\(if: list, "const ")\(dtype)\(if: list, "*") ptr
                    output.append("""
                        ctypedef struct \(arg.pyx_type!):
                            \(if: list, "const ")\(dtype)\(if: list, " *") ptr
                            long size;
                    
                    """)
                }
                
            }
            
            
        } else {
            output.append("\t"+"ctypedef \(dtype) \(arg.pyx_type!)\n")
        }
        
        
    }
    
    
    
    return output.joined(separator: "\n")
}

enum handlerFunctionCodeType {
    case normal
    case python
    case cython
    case init_delegate
    case objc_h
    case objc_m
    case send
    case callback
}

func generateHandlerFuncs(cls: WrapClass, options: [handlerFunctionCodeType]) -> String {
    var output: [String] = [""]
    let objc_m = options.contains(.objc_m)
    if options.contains(.objc_h) {
        for option in options {
            switch option {
            case .init_delegate:
                output.append("void Init\(cls.title)_Delegate(id<\(cls.title)_Delegate> _Nonnull callback);")
            case .callback:
                output.append("")
            default:
                output.append("void set_\(cls.title)_Callback(struct \(cls.title)Callbacks callback);")
            }
        }
    }
    if options.contains(.objc_m) {
        for option in options {
            switch option {
            case .init_delegate:
                output.append("""
                void Init\(cls.title)_Delegate(id<\(cls.title)_Delegate> _Nonnull callback) {
                    \(cls.title.lowercased()) = callback;
                    NSLog(@"setting \(cls.title) delegate %@",\(cls.title.lowercased()));
                }
                """)
            case .callback:
                output.append("""
                void set_\(cls.title)_Callback(struct \(cls.title)Callbacks callback) {
                    NSLog(@"setting callback %@",\(cls.title.lowercased()));
                    [\(cls.title.lowercased()) set_\(cls.title)_Callback:callback];
                }
                """)
            case .send:
                //output.append("\(generateSendFunctions(module: self , objc: true))")
                
                for function in cls.functions.filter({!$0.is_callback && !$0.swift_func}) {
                    let has_args = function.args.count != 0
                    let return_type = "\(if: objc_m, function.returns.objc_type!, function.returns.pyx_type!)"
                    output.append("""
                    \(return_type) \(cls.title)_\(function.name)(\(function.export(options: [.use_names]))) {
                        \(if: function.returns.name != "void", "return ")[\(cls.title.lowercased()) \(function.name)\(if: has_args, ": ")\(function.args.map{$0.name}.joined(separator: ": "))];
                    }
                    """)
                }
                
                
            default:
                ""
            }
        }
    }
    return output.joined(separator: newLine)
}


func createSetSwiftFunctions(cls: WrapClass) {
    var json = JSON()
    var function: JSON = [
        "name": "set_SwiftFunctions"
    ]
}

func createRecipe(title: String) -> String{
    """
    from kivy_ios.toolchain import CythonRecipe

    class \(title)(CythonRecipe):
        version = "master"
        url = "src"
        library = "lib\(title).a"
        depends = ["python3", "hostpython3"]

        # Frameworks you used
        pbx_frameworks = []

        def install(self):
            self.install_python_package(
                # Put the extension name here
                name=self.so_filename("\(title)"), is_dir=False)

    recipe = \(title)()
    """
}

func createSetupPy(title: String) -> String {
    """
    from distutils.core import setup, Extension

    setup(name='\(title)',
          version='1.0',
          ext_modules=[
              Extension('\(title)', # Put the name of your extension here
                        ['\(title).c', '_\(title).m'],
                        libraries=[],
                        library_dirs=[],
                        extra_compile_args=['-ObjC','-w'],
                        )
          ]
        )
    """
}
