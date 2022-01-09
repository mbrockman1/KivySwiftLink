//
//  WrapModule.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 06/12/2021.
//

import Foundation
import SwiftyJSON

//class WrapModuleBase: Codable {
//    var filename: String
//    var classes: [WrapClass]
//
//}



class WrapModule: Codable {
    var filename: String
    var classes: [WrapClass]
    var custom_structs: [CustomStruct]
    var dispatchEnabled = false

    var usedTypes: [WrapArg] = []
    var usedListTypes: [WrapArg] = []
    let working_dir = FileManager().currentDirectoryPath
    
    private enum CodingKeys: CodingKey {
        case filename
        case classes
        case custom_structs
    }
    required init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        filename = try container.decode(String.self, forKey: .filename)
        classes = try container.decode([WrapClass].self, forKey: .classes)
        custom_structs = try container.decode([CustomStruct].self, forKey: .custom_structs)
        wrap_module_shared = self
        postProcess()
        build()
    }
    
    
    func postProcess() {
        for cls in classes {
            for function in cls.functions {
                for arg in function.args {
                    arg.postProcess(mod: self, cls: cls)
                }
            }
        }
    }
//    required init(from decoder: Decoder) throws {
//        try super.init(from: decoder)
//        build()
//    }
    var pyx: String {
        
        var imports = """
        #cython: language_level=3
        import json
        from typing import List
        from libc.stdlib cimport malloc, free
        """
        if dispatchEnabled {
            imports.append("\nfrom kivy._event cimport EventDispatcher")
        }
        let type_imports = """
        \(generateTypeDefImports(imports: usedTypes))
        """
        var pyx_strings = [imports,type_imports]
        for cls in classes {
            var class_vars: [String] = []
            var class_ext_options: [CythonClassOptionTypes] = [.init_callstruct]
            //var EnumStrings: String = ""
            var swift_funcs_struct = ""
            if cls.dispatch_mode {
//                let dis_dec = cls.decorators.filter({$0.type=="EventDispatch"})[0]
//                let events = (dis_dec.dict[0]["events"] as! [String]).map({"\"\($0)\""})
                class_vars.append("""
                \t__events__ = \(cls.title)_events

                """)
                class_ext_options.append(.event_dispatch)
                //EnumStrings = generateEnums(cls: cls, options: [.cython,.dispatch_events])
            }
            if cls.has_swift_functions {
                class_ext_options.append(.swift_functions)
                class_vars.append("\t" + cls.functions.filter{$0.has_option(option: .swift_func) && !$0.has_option(option: .callback)}.map{"cdef \($0.function_pointer) _\($0.name)_"}.joined(separator: "\n\t") + newLine)
                swift_funcs_struct = generateStruct(options: [.swift_functions])
                swift_funcs_struct.append("\n\t\(generateFunctionPointers(objc: false, options: [.excluded_callbacks_only]))")
            }
            let pyx_string = """
            cdef extern from "_\(filename).h":
                ######## cdef extern Callback Function Pointers: ########
                \(if: cls.dispatch_mode, generateEnums(cls: cls, options: [.cython,.dispatch_events]))
                \(generateFunctionPointers(objc: false, options: [.excluded_callbacks]))

                ######## cdef extern Callback Struct: ########
                \(swift_funcs_struct)
                
                \(generateStruct(options: [.callbacks]))
                
                ######## cdef extern Send Functions: ########
                void set_\(cls.title)_Callback(\(cls.title)Callbacks callback)
                \(generateSendFunctions(objc: false, header: true))
                
            \(custom_structs.map{$0.export(options: [.python])}.joined(separator: newLine))

            ######## Callbacks Functions: ########
            \(generateCallbackFunctions(options: [.header]))
            
            ######## Cython Class: ########
            \(generateCythonClass(cls: cls, class_vars: class_vars.joined(separator: newLine), dispatch_mode: cls.dispatch_mode))

                ######## Cython Class Extensions: ########
                \(extendCythonClass(cls: cls, options: class_ext_options))
                ######## Class Functions: ########
            \(generatePyxClassFunctions)
            """
            pyx_strings.append(pyx_string)
        }
        return pyx_strings.joined(separator: newLine).replacingOccurrences(of: "    ", with: "\t")
        //
        //\(generatePyxClassFunctions(module: self)  )
        //\(generateStruct(module: self, options: [.swift]))
    }
    
    var h: String {
        //let cls = self.classes[0]
        var h_string = ["""
        #ifndef \(filename)_h
        #define \(filename)_h
        #include "wrapper_typedefs.h"
        #include <stdbool.h>
        
        """]
        for cls in self.classes{
            h_string.append( """
            //insert enums / Structs
            \(if: cls.dispatch_mode,generateEnums(cls: cls, options: [.dispatch_events, .objc]))
            //######## cdef extern Callback Function Pointers: ########//
            \(generateFunctionPointers(objc: true, options: [.excluded_callbacks]))
            
            //######## cdef extern Callback Struct: ########//
            \(if: cls.has_swift_functions, generateStruct(options: [.swift_functions, .objc]) )
            \(if: cls.has_swift_functions, generateFunctionPointers(objc: true, options: [.excluded_callbacks_only]) )
            \(generateStruct(options: [.objc, .callbacks]))
                        
            //######## Send Functions Protocol: ########//
            \(generateHandlerFuncs(cls: cls, options: [.objc_h]))
            //######## Send Functions: ########//
            \(generateSendFunctions(objc: true, header: true))
            """)
            //\(generateSendProtocol(module: self))
            //\(generateStruct(module: self, options: [.objc, .swift]))
            //\(generateHandlerFuncs(cls: cls, options: [.objc_h, .init_delegate, .callback]))
            //
        }
        h_string.append("#endif /* \(filename)_h */")
        return h_string.joined(separator: newLine)
    }
    
    var m: String {
        var m_string = """
        #import "_\(filename).h"
        
        """
        for cls in self.classes {
            m_string.append("\(generateHandlerFuncs(cls: cls, options: [.objc_m, .init_delegate, .callback, .send]))")
        }
        return m_string
        }
    
    var c: String {
        var c_string = """
        #import "_\(filename).h"
        """
        for cls in self.classes {
            c_string.append("\(generateHandlerFuncs(cls: cls, options: [.objc_m, .init_delegate, .callback, .send]))")
        }
        return c_string
    }
    
    var swift: String {
        var swift_string = """
        import Foundation
        
        \(custom_structs.map{$0.export(options: [.swift])}.joined(separator: newLine))
        //######## Send Functions Protocol: ########//
        \(generateSwiftSendProtocol)
        
        \(generateSwiftCallbackWrap)
        
        """
        for cls in self.classes {
            swift_string.append("\(generateHandlerFuncs(cls: cls, options: [.swift, .init_delegate, .callback, .send]))")
        }
        return swift_string
        }
    
    func build() {
        for _class in classes {
            _class.build()
            if _class.dispatch_mode {
                dispatchEnabled = true
            }
            
            
        }
        find_used_arg_types()
    }
    
    func add_missing_arg_type(type:String) -> WrapArg {
        let is_data = ["data","jsondata"].contains(type)
        let json_arg: JSON = [
            "name":type,
            "type":type,
            "idx": 0,
            "is_data": is_data
        ]
        
        let decoder = JSONDecoder()
        return try! decoder.decode(WrapArg.self, from: json_arg.rawData())
    }
    
    func find_used_arg_types() {
        let test_types = ["object","json","jsondata","data","str", "bytes"]
        
        for cls in classes {
            //var has_swift_functions = false
            for function in cls.functions {
                let returns = function.returns
                if (returns.has_option(.list) || returns.has_option(.data)) && !["object","void"].contains(returns.type.rawValue) {
                    fatalError("\n\t\(if: returns.has_option(.list),"list[\(returns.type.rawValue)]",returns.type.rawValue) as return type is not supported atm")
                }
                if !usedTypes.contains(where: {$0.type == returns.type && ($0.has_option(.list) == returns.has_option(.list))}) {
                    //check for supported return list
                    
                    
                    if returns.has_option(.list) || returns.has_option(.data) || returns.has_option(.json) || test_types.contains(returns.type.rawValue) {
                        
                        usedTypes.append(returns)
                        if !usedTypes.contains(where: {$0.type == returns.type && !$0.has_option(.list)}) {
                            usedTypes.append(add_missing_arg_type(type: returns.type.rawValue))
                        }
                    }
                        
                }
                                    
                for arg in function.args {
                    let is_list = arg.has_option(.list)
                    
                    if !usedTypes.contains(where: {$0.type == arg.type && ($0.has_option(.list) == is_list)}) {
                        if is_list || arg.has_option(.data) || arg.has_option(.json) || test_types.contains(arg.type.rawValue){
                            usedTypes.append(arg)
                        }
                    }
                }
                //if function.swift_func {has_swift_functions = true}
            } //function loop end
            
           
            
        }
    }
    
    func export(objc: Bool, header: Bool) -> String {
        for _ in classes {
            //_class.export(objc: objc, header: header)
        }
        
        return ""
    }
}


var wrap_module_shared: WrapModule!
