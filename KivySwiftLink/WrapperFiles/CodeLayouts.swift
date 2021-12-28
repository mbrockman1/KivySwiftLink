//
//  CodeLayouts.swift
//  KivySwiftLink2
//
//  Created by MusicMaker on 16/10/2021.
//
import SwiftyJSON
import Foundation
func generateCythonClass(cls: WrapClass, class_vars: String, dispatch_mode: Bool) -> String {
    let _class = cls.title
    if dispatch_mode {
        let events = cls.dispatch_events.map{"\"\($0)\""}
    let string = """
    cdef public void* \(_class)_voidptr
    #cdef public void* \(_class)_dispatch
    cdef public \(_class) \(_class)_shared
    cdef list \(_class)_events = [\(events.joined(separator: ", "))]

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
    """.replacingOccurrences(of: "    ", with: "\t")
}




func extendCythonClass(cls: WrapClass, options: [CythonClassOptionTypes]) -> String {
    
    var output: [String] = []
    
    for t in options {
        switch t {
        case .init_callstruct:
            let string = """
                cdef \(cls.title)Callbacks callbacks = [
                    \(cls.functions.filter{$0.has_option(option: .callback)}.map({"\t\(cls.title)_\($0.name)"}).joined(separator: ",\n\t\t"))
                    ]
                    set_\(cls.title)_Callback(callbacks)
            """
            output.append(string)
        case .event_dispatch:
            
            output.append("")
        case .swift_functions:
            let func_string = cls.functions.filter{$0.has_option(option: .swift_func) && !$0.has_option(option: .callback)}.map{"self._\($0.name)_ = func_struct.\($0.name)"}.joined(separator: "\n\t\t")
            output.append("""
            cdef set_swift_functions(self, \(cls.title)SwiftFuncs func_struct ):
                    \(func_string)
                    print("set_swift_functions")

            """)
        
        }
    }
    
    return output.joined(separator: "\n\t")
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
//                    string.append("""
//                    typedef NS_ENUM(NSUInteger, \(cls.title)Events) {
//                        \(events.joined(separator: "," + newLineTab))
//                    };
//                    """)
                    string.append("""
                    typedef enum \(cls.title)Events {
                        \(events.joined(separator: "," + newLineTab))
                    } \(cls.title)Events;
                    """)
                }
            }
            
            
        }
    }
    return string.joined(separator: newLineTab)
}














func generateDispatchFunctions(cls: WrapClass, objc: Bool) {
    let decoder = JSONDecoder()
    
    //for event in cls.dispatch_events {
        
        let dispatch_function: JSON = [
            "name":"dispatch",
            "args": [
                [
                    "name":"event",
                    "type":"other",
                    "other_type": "\(cls.title)Events",
                    "options": ["enum_"],
                    "idx": 0
                ],
                [
                    "name":"*largs",
                    "type":"jsondata",
                    "options": ["data","json"],
                    "idx": 1
                ],
                [
                    "name":"**kwargs",
                    "type":"jsondata",
                    "options": ["data","json"],
                    "idx": 2
                ]
            ],
            //"swift_func": false,
            "options": ["callback","dispatch"],
            "returns": [
                "name": "void",
                "type": "void",
                "idx": 0,
                "options": ["return_"],
            ]
        ]
        
        
        let function = try! decoder.decode(WrapFunction.self, from: dispatch_function.rawData())
    function.wrap_class = cls
    function.set_args_cls(cls: cls)
        cls.functions.insert(function, at: 0)
    //}
 
}






enum functionCodeType {
    case normal
    case python
    case cython
    case objc
    case send
    case call
    case dispatch
}

func generateFunctionCode(title: String, function: WrapFunction) -> String {
    var output: [String] = []
    if function.has_option(option: .swift_func) {
        output.append("self._\(function.name)_(\(function.send_args.joined(separator: ", ")))")
    } else {
        if function.has_option(option: .callback) {
            output.append("\(title)_\(function.name)(\(function.send_args.joined(separator: ", ")))")
        } else { // sends
            
            if function.returns.type != .void {
                let rtn = function.returns
                let rname = "\(title)_\(function.name)"
                let code = "\(rname)(\(function.send_args_py.joined(separator: ", ")))"
//                if rtn.is_data || rtn.is_list {
//                    output.append("cdef long \(rname)_size = len(\(rname))")
//                }
                output.append("cdef \(rtn.pyx_type) rtn_val = \(code)")
                output.append("return \(function.convertReturnSend(rname: rname, code: code))")
            } else {
                output.append("\(title)_\(function.name)(\(function.send_args_py.joined(separator: ", ")))")
            }
        }
        
    }
    
    return output.joined(separator: "\n\t\t")
}
func setCallPath(wraptitle: String, function: WrapFunction, options: [functionCodeType]) -> String {
    if function.has_option(option: .swift_func) {
        return "\(wraptitle)_shared.\(function.name)"
    }
    if function.has_option(option: .dispatch) {
        return "\(wraptitle)_shared.\(function.name)"
    }
    
    
    if function.call_class_is_arg {
        if let call_target = function.call_target {
            let target = function.get_callArg(name: function.call_class)
            return "(<object> \(target!.objc_name)).\(call_target).\(function.name)"
        }
        let target = function.get_callArg(name: function.call_class)
        return "(<object> \(target!.objc_name)).\(function.name)"
    }
    
    if function.call_target_is_arg {
        return "(<object> \(function.get_callArg(name: function.call_target)!.objc_name))"
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
    if function.has_option(option: .callback) {
        var call_args: [String]
        let call_path_options: [functionCodeType] = [.cython]
        if options.contains(.header) {call_args = function.call_args(cython_callback: true )} else {call_args = function.call_args(cython_callback: false)}
        let func_args = function.export(options: options)
        let call_path = setCallPath(wraptitle: wraptitle, function: function, options: call_path_options)
        let return_type = function.returns.pythonType2pyx(options: options)

        //let return_type = pythonType2pyx(type: pythonType2pyx(type: function.returns.type, options: options), options: options)
        //print("call_args", call_args)
        
        output = """
        cdef \( return_type ) \(wraptitle)_\(function.name)(\(func_args)) with gil:
            \(call_path)(\(call_args.joined(separator: ", ")))
        """
    } else {
        output = "\(function.returns.pythonType2pyx(options: options)) \("abc"))(\(function.export(options: options)))"
        if objc { output.append(";") }
    }
    return output
}


func generateTypeDefImports(imports: [WrapArg]) -> String {
    //let deftypes = get_typedef_types()
    var output: [String] = ["cdef extern from \"wrapper_typedefs.h\":"]
    if imports.count == 0 {return ""}
    var imps = imports
    imps.sort {
        !$0.has_option(.list) && $1.has_option(.list)
    }
    for arg in imps {
        let list = arg.has_option(.list)
        let data = arg.type == .data
        let jsondata = arg.type == .jsondata
        
        let dtype = arg.pythonType2pyx(options: [.c_type])
        //
        if list || data || jsondata {
            if list && (data || jsondata) {
                output.append("""
                    ctypedef struct \(arg.pyx_type):
                        const \(arg.convertPythonType(options: [.objc]))\(if: list, "*") ptr
                        long size;
                
                """)
            } else {
                
                if list && [.object,.str].contains(arg.type) {
                    output.append("""
                        ctypedef struct \(arg.pyx_type):
                            const \(arg.convertPythonType(options: [])) * ptr
                            long size;
                    
                    """)
                } else {
                    // Normal types / lists with normal types
                    //\(if: list, "const ")\(dtype)\(if: list, "*") ptr
                    output.append("""
                        ctypedef struct \(arg.pyx_type):
                            \(if: list, "const ")\(dtype)\(if: list, " *") ptr
                            long size;
                    
                    """)
                }
                
            }
            
            
        } else {
            output.append("\t"+"ctypedef \(dtype) \(arg.pyx_type)\n")
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
    case swift
    case protocols
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
                
                for function in cls.functions.filter({!$0.has_option(option: .callback) && !$0.has_option(option: .swift_func)}) {
                    let has_args = function.args.count != 0
                    let return_type = "\(if: objc_m, function.returns.objc_type, function.returns.pyx_type)"
                    output.append("""
                    \(return_type) \(cls.title)_\(function.name)(\(function.export(options: [.use_names, .objc]))) {
                        \(if: function.returns.name != "void", "return ")[\(cls.title.lowercased()) \(function.name)\(if: has_args, ": ")\(function.args.map{$0.name}.joined(separator: ": "))];
                    }
                    """)
                }
                
                
            default:
                continue
            }
        }
    }
    if options.contains(.swift) {
        for option in options {
            switch option {
            case .init_delegate:
                output.append("""
                func Init\(cls.title)_Delegate(delegate: \(cls.title)_Delegate) {
                    \(cls.title.lowercased()) = delegate
                    print("setting \(cls.title) delegate \\(String(describing: \(cls.title.lowercased())))")
                }
                """)
            case .callback:
                let call_args = cls.functions.filter{!$0.has_option(option: .callback) && !$0.has_option(option: .swift_func) && !$0.has_option(option: .dispatch)}.map{"\($0.name): \(cls.title)_\($0.name)"}.joined(separator: ", ")
                var call_title = cls.title.titleCase()
                call_title.removeFirst()
                output.append("""
                @_silgen_name(\"set_\(cls.title)_Callback\")
                func set_\(cls.title)_Callback(_ callback: \(cls.title)Callbacks) {
                    print("setting callback \\(String(describing: \(cls.title.lowercased())))")
                    \(cls.title.lowercased()).set_\(cls.title)_Callback(callback: \(cls.title)PyCallback(callback: callback))
                    //\(call_title)Callback = \(cls.title)PyCallback(callback: callback)
                    //let calls = \(cls.title)Sends(\(call_args))
                }
                """)
            case .send:
                //output.append("\(generateSendFunctions(module: self , objc: true))")
                
                for function in cls.functions.filter({!$0.has_option(option: .callback) && !$0.has_option(option: .swift_func)}) {
                    let swift_return = "\(if: function.returns.type != .void, "-> \(function.returns.swift_type)", "")"
                    let func_args = function.args.map{"\($0.name): \($0.swiftCallArgs)"}.joined(separator: ", ")
                    output.append("""
                    @_silgen_name(\"\(cls.title)_\(function.name)\")
                    func \(cls.title)_\(function.name)(\(function.export(options: [.use_names, .swift]))) \(swift_return) {
                        \(if: function.returns.type != .void, "return ")\(cls.title.lowercased()).\(function.name)(\(func_args))
                    }
                    """)
                }
                
                
            default:
                continue
            }
        }
    }
    return output.joined(separator: newLine)
}


func createSetSwiftFunctions(cls: WrapClass) {
//    var json = JSON()
//    var function: JSON = [
//        "name": "set_SwiftFunctions"
//    ]
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

func _createSetupPy(title: String) -> String {
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

func createSetupPy(title: String) -> String {
    """
    from distutils.core import setup, Extension

    setup(name='\(title)',
          version='1.0',
          ext_modules=[
              Extension('\(title)', # Put the name of your extension here
                        ['\(title).c'],
                        libraries=[],
                        library_dirs=[],
                        extra_compile_args=['-w'],
                        )
          ]
        )
    """
}
