//
//  WrapModule.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 06/12/2021.
//

import Foundation
import SwiftyJSON

class WrapModuleBase: Codable {
    var filename: String
    var classes: [WrapClass]
    
}

class WrapModule: WrapModuleBase {
    
    var dispatchEnabled = false

    var usedTypes: [WrapArg] = []
    var usedListTypes: [WrapArg] = []
    let working_dir = FileManager().currentDirectoryPath
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        build()
    }
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
                \tevents = [\(cls.dispatch_events.map({"\"\($0)\""}).joined(separator: ", "))]

                """)
                class_ext_options.append(.event_dispatch)
                //EnumStrings = generateEnums(cls: cls, options: [.cython,.dispatch_events])
            }
            if cls.has_swift_functions {
                class_ext_options.append(.swift_functions)
                class_vars.append("\t" + cls.functions.filter{$0.swift_func && !$0.is_callback}.map{"cdef \($0.function_pointer) _\($0.name)_"}.joined(separator: "\n\t") + newLine)
                swift_funcs_struct = generateStruct(module: self, options: [.swift_functions])
                swift_funcs_struct.append("\n\t\(generateFunctionPointers(module: self, objc: false, options: [.excluded_callbacks_only]))")
            }
            
            let pyx_string = """
            cdef extern from "_\(filename).h":
                ######## cdef extern Callback Function Pointers: ########
                \(if: cls.dispatch_mode, generateEnums(cls: cls, options: [.cython,.dispatch_events]))
                \(generateFunctionPointers(module: self, objc: false, options: [.excluded_callbacks]))

                ######## cdef extern Callback Struct: ########
                \(swift_funcs_struct)
                
                \(generateStruct(module: self, options: [.callbacks]))
                
                ######## cdef extern Send Functions: ########
                void set_\(cls.title)_Callback(\(cls.title)Callbacks callback)
                \(generateSendFunctions(module: self, objc: false))
                
            
            ######## Callbacks Functions: ########
            \(generateCallbackFunctions(module: self, options: [.header]))
            
            ######## Cython Class: ########
            \(generateCythonClass(cls: cls, class_vars: class_vars.joined(separator: newLine), dispatch_mode: cls.dispatch_mode))

                ######## Cython Class Extensions: ########
                \(extendCythonClass(cls: cls, options: class_ext_options))
                ######## Class Functions: ########
            \(generatePyxClassFunctions(module: self)  )
            """
            pyx_strings.append(pyx_string)
        }
        return pyx_strings.joined(separator: newLine).replacingOccurrences(of: "    ", with: "\t")
        
    }
    
    var h: String {
        //let cls = self.classes[0]
        var h_string = """
        #import <Foundation/Foundation.h>
        #import "wrapper_typedefs.h"

        """
        for cls in self.classes{
            h_string.append( """
            //insert enums / Structs
            \(if: cls.dispatch_mode,generateEnums(cls: cls, options: [.dispatch_events, .objc]))
            //######## cdef extern Callback Function Pointers: ########//
            \(generateFunctionPointers(module: self, objc: true, options: [.excluded_callbacks]))
            
            //######## cdef extern Callback Struct: ########//
            \(if: cls.has_swift_functions, generateStruct(module: self, options: [.swift_functions, .objc]) )
            \(if: cls.has_swift_functions, generateFunctionPointers(module: self, objc: true, options: [.excluded_callbacks_only]) )
            \(generateStruct(module: self, options: [.objc, .callbacks]))
            
            //######## Send Functions Protocol: ########//
            \(generateSendProtocol(module: self))
            \(generateHandlerFuncs(cls: cls, options: [.objc_h, .init_delegate, .callback]))
            //######## Send Functions: ########//
            \(generateSendFunctions(module: self, objc: true))
            """)
        }
        
        return h_string
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
                if (returns.is_list || returns.is_data) && !["object","void"].contains(returns.type.rawValue) {
                    fatalError("\n\t\(if: returns.is_list,"list[\(returns.type.rawValue)]",returns.type.rawValue) as return type is not supported atm")
                }
                if !usedTypes.contains(where: {$0.type == returns.type && ($0.is_list == returns.is_list)}) {
                    //check for supported return list
                    
                    
                    if returns.is_list || returns.is_data || returns.is_json || test_types.contains(returns.type.rawValue) {
                        
                        usedTypes.append(returns)
                        if !usedTypes.contains(where: {$0.type == returns.type && !$0.is_list}) {
                            //print("list type not found", returns.type)
                            usedTypes.append(add_missing_arg_type(type: returns.type.rawValue))
                        }
                    }
                        
                }
                                    
                for arg in function.args {
                    
                    
                    if !usedTypes.contains(where: {$0.type == arg.type && ($0.is_list == arg.is_list)}) {
                        if arg.is_list || arg.is_data || arg.is_json || test_types.contains(arg.type.rawValue){
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
