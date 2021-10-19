//
//  WrapClasses.swift
//  KivySwiftLink2
//
//  Created by MusicMaker on 15/10/2021.
//

import Foundation
import SwiftyJSON

class WrapModuleBase: Codable {
    var filename: String
    var classes: [WrapClass]
    
}

class WrapModule: WrapModuleBase {
    
    var dispatchEnabled = false
    var usedTypes: [String] = []
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        build()
    }
    var pyx: String {
        var imports = """
        #cython: language_level=3
        import json
        from libc.stdlib cimport malloc, free
        """
        if dispatchEnabled {
            imports.append("\nfrom kivy._event cimport EventDispatcher")
        }
        
        let cls = classes[0]
        
        let pyx_string = """
        \(imports)
        cdef extern from "wrapper_typedefs.h":
            \(generateTypeDefImports(imports: usedTypes))
        
        cdef extern from "_\(filename).h":
            ######## cdef extern Callback Function Pointers: ########
            \(generateFunctionPointers(module: self, objc: false))

            ######## cdef extern Callback Struct: ########
            \(generateStruct(module: self,ending: "Callback", objc: false))

            ######## cdef extern Send Functions: ########
            void set_\(cls.title)_Callback(\(cls.title)Callback callback)
            \(generateSendFunctions(module: self, objc: false))

        ######## Callbacks Functions: ########
        \(generateCallbackFunctions(module: self, objc: false, header: false))

        ######## Cython Class: ########
        \(generateCythonClass(_class: cls.title, class_vars: "", dispatch_mode: cls.dispatch_mode))
            ######## Cython Class Extensions: ########
            \(extendCythonClass(cls: cls, options: [.init_callstruct]))
            ######## Class Functions: ########
        \(generatePyxClassFunctions(module: self)  )
        """
        return pyx_string
        
    }
    
    var h: String {
        let h_string = """
        #import <Foundation/Foundation.h>
        #import "wrapper_typedefs.h"
        //insert enums / Structs
        //######## cdef extern Callback Function Pointers: ########//
        \(generateFunctionPointers(module: self, objc: true))

        //######## cdef extern Callback Struct: ########//
        \(generateStruct(module: self,ending: "Callback", objc: true))

        //######## Send Functions Protocol: ########//
        \(generateSendProtocol(module: self))
        //######## Send Functions: ########//
        \(generateSendFunctions(module: self, objc: true))
        """
        
        return h_string
    }
    
    var m: String {
        let m_string = """
        //#import <Foundation/Foundation.h>
        #import "_\(filename).h"
        //#import "wrapper_typedefs.h"
        //insert enums / Structs
        //######## cdef extern Callback Function Pointers: ########//
        \(generateFunctionPointers(module: self, objc: true))

        //######## cdef extern Callback Struct: ########//
        \(generateStruct(module: self, ending: "Callback", objc: true))

        //######## Send Functions Protocol: ########//
        \(generateSendProtocol(module: self))
        //######## Send Functions: ########//
        \(generateSendFunctions(module: self, objc: true))
        """
        
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
    
    func find_used_arg_types() {
        for cls in classes {
            for function in cls.functions {
                if !usedTypes.contains(function.returns.pyx_type) {
                    usedTypes.append(function.returns.pyx_type)
                                    }
                for arg in function.args {
                    if !usedTypes.contains(arg.pyx_type) {
                        usedTypes.append(arg.pyx_type)
                    }
                }
            }
        }
    }
    
    func export(objc: Bool, header: Bool) -> String {
        for _ in classes {
            //_class.export(objc: objc, header: header)
        }
        
        return ""
    }
}
class WrapClassBase: Codable {
    let title: String
    var functions: [WrapFunction]
    var decorators: [WrapClassDecorator]
    
    
}
class WrapClass: WrapClassBase {
    var pointer_compare_strings: [String] = []
    var pointer_compare_dict: [String:[String:String]] = [:]
    var dispatch_mode = false
    var has_swift_functions = false
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
    }
    func build() {
        handleDecorators()
        generateFunctionCompares()
        doFunctionCompares()
    }
    
    func handleDecorators() {
        let decs = decorators.map({$0.type})
        if decs.contains("EventDispatch") {self.dispatch_mode = true}
    }
    
    func generateFunctionCompares(){
        for function in functions {
            if function.compare_string == "" {
                let compare_args = function.args.map {$0.type}
                let compare_string = "\(function.returns) \(compare_args.joined(separator: " "))"
                function.compare_string = compare_string
                if function.is_callback || function.swift_func {
                    if !pointer_compare_strings.contains(compare_string) {
                        pointer_compare_strings.append(compare_string)
                        let compare_count = pointer_compare_strings.count
                        pointer_compare_dict[compare_string] = [
                            "name": "\(title)_ptr\(compare_count)",
                            "pyx_string": function.export(objc: false, header: false, use_names: false),
                            "objc_string": function.export(objc: true, header: false),
                            "returns": pythonType2pyx(type: function.returns.type, objc: false)
                            ]
                    }
                }
            }
        }
    }

    func doFunctionCompares() {
        
        for function in functions {
            if function.is_callback || function.swift_func {
                let compare_string = function.compare_string
                let pointer_type = pointer_compare_dict[compare_string]!
                function.function_pointer = pointer_type["name"]!
            }
        }
    }
}

class WrapFunctionBase: Codable {
    let name: String
    var args: [WrapArg]
    var returns: WrapArg
    let is_callback: Bool
    let swift_func: Bool
    var call_class: String!
    var call_target: String!
    
}

class WrapFunction: WrapFunctionBase {
    var compare_string: String = ""
    var function_pointer = ""
    var wrap_class: WrapClass!
    
    var call_args: [String] {
        var call_class = ""
        var call_target = ""
        if self.call_class != nil {call_class = self.call_class}
        if self.call_target != nil {call_target = self.call_target}
        let _args = args.filter{arg -> Bool in
            arg.name != call_target && arg.name != call_class
        }
        return _args.map {
            if !$0.is_counter {
                return convertPythonCallArg(type: $0.type, name: $0.name, is_list_data: $0.is_list)
                }
            return ""
        }.filter({$0 != ""})
    }
    
    var send_args: [String] {
        args.map {
            if !$0.is_counter {
                return convertPythonSendArg(type: $0.type, name: $0.name, is_list_data: $0.is_list)
                }
            return ""
        }.filter({$0 != ""})
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    func export(objc: Bool, header: Bool, use_names: Bool = false, py_mode: Bool = false)  -> String {
        
        if objc {
            let func_args = args.map({ arg in
                arg.export(objc: objc, header: header, use_names: use_names, py_mode: py_mode)!
            })
            if header {
                return func_args.joined(separator: " ")
            } else {
                return func_args.joined(separator: ", ")
            }
            
        }
        var _args: [WrapArg]
        if py_mode {
            _args = args.filter({!$0.is_counter})
        } else {
            _args = args
        }
//        _args = _args.filter{arg -> Bool in
//            arg.name != call_target && arg.name != call_class
//        }
        let func_args = _args.map({ arg in
            return arg.export(objc: objc, header: header, use_names: use_names, py_mode: py_mode)!
        })
        if header {
            return func_args.joined(separator: " ")
        } else {
            return func_args.joined(separator: ", ")
        }
        
    }
    
}

class WrapArgBase: Codable {
    let name: String
    let type: String
    let idx: Int
    
    var is_return: Bool!
    var is_list: Bool!
    var is_counter: Bool!
    var is_json: Bool!
    var is_data: Bool!
    
    var objc_name: String!
    var objc_type: String!
    
    var pyx_name: String!
    var pyx_type: String!
    
    var size: Int!
    
}

class WrapArg: WrapArgBase {
    
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        if is_list == nil {
            is_list = false
        }
        if is_counter == nil {
            is_counter = false
        }
        if is_json == nil {
            is_json = false
        }
        if is_data == nil {
            is_data = false
        }
        if is_return == nil {
            is_return = false
        }
        set_types()
    }
    
    
    
    func set_types() {
        pyx_name = name
        pyx_type = convertPythonType(type: type, is_list: is_list!, objc: false, header: false)
        objc_name = "arg\(idx)"
        objc_type = convertPythonType(type: type, objc: true, header: false)
        size = TYPE_SIZES[type]
        
    }
    

    
    func export(objc: Bool, header: Bool, use_names: Bool = false, py_mode: Bool = false) -> String! {
        var _name: String
        if use_names {
            _name = name
        } else {
            _name = objc_name!
        }
        if objc {
            if header {
                var header_string = ""
                switch idx {
                case 0:
                    header_string.append(":(\(convertPythonType(type: type, is_list: is_list, objc: objc, header: header) ))\(_name)")
                default:
                    header_string.append("\(name):(\(convertPythonType(type: type, is_list: is_list, objc: objc, header: header) ))\(_name)")
                }
                //let func_string = "\(convertPythonType(type: type, is_list: is_list, objc: objc, header: header)) \(objc_name!)"
                return header_string
            } else {
                let func_string = "\(convertPythonType(type: type, is_list: is_list, objc: objc, header: header)) \(_name)"
                return func_string
            }
        }
        if py_mode {
            if is_list {return "\(name): List[\(type)]"}
            return "\(name): \(type)"
        }
        
        let func_string = "\(convertPythonType(type: type, is_list: is_list)) \(_name)"
        return func_string
    }
}


class WrapClassDecorator: Codable {
    let type: String
    let args: [String]
}
