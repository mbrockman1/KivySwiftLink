//
//  WrapClasses.swift
//  KivySwiftLink2
//
//  Created by MusicMaker on 15/10/2021.
//

import Foundation

class WrapModuleBase: Codable {
    var filename: String
    var classes: [WrapClass]
}

class WrapModule: WrapModuleBase {
    var dispatchEnabled = false
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        build()
    }
    var pyx: String {
        get {
            var imports = """
            #cython: language_level=3
            import json
            from libc.stdlib cimport malloc, free
            """
            if dispatchEnabled {
                imports.append("\nfrom kivy._event cimport EventDispatcher")
            }
            
            let pyx_string = """
            \(imports)
                
            cdef extern from "_\(filename).h":
                ######## cdef extern Callback Function Pointers: ########
                \(generateFunctionPointers(module: self, objc: false))

                ######## cdef extern Callback Struct: ########
                \(generateStruct(module: self, objc: false))

                ######## cdef extern Send Functions: ########
                \(generateSendFunctions(module: self, objc: false))

                ######## Callbacks Functions: ########
                \(generateCallbackFunctions(module: self, objc: false, header: false))

            ######## Cython Class: ########
            \(generateCythonClass(_class: classes[0].title, class_vars: "", dispatch_mode: false))

                ######## Class Functions: ########
            \(generatePyxClassFunctions(module: self)  )
            """
            return pyx_string
        }
    }
    
    var h: String {
        get {
            let h_string = """
            #import <Foundation/Foundation.h>
            #import "wrapper_typedefs.h"
            //insert enums / Structs
            //######## cdef extern Callback Function Pointers: ########//
            \(generateFunctionPointers(module: self, objc: true))

            //######## cdef extern Callback Struct: ########//
            \(generateStruct(module: self, objc: true))

            //######## Send Functions Protocol: ########//
            \(generateSendProtocol(module: self))
            //######## Send Functions: ########//
            \(generateSendFunctions(module: self, objc: true))
            """
            
            return h_string
        }
    }
    
    var m: String {
            get {
                let m_string = """
                //#import <Foundation/Foundation.h>
                #import "_\(filename).h"
                //#import "wrapper_typedefs.h"
                //insert enums / Structs
                //######## cdef extern Callback Function Pointers: ########//
                \(generateFunctionPointers(module: self, objc: true))

                //######## cdef extern Callback Struct: ########//
                \(generateStruct(module: self, objc: true))

                //######## Send Functions Protocol: ########//
                \(generateSendProtocol(module: self))
                //######## Send Functions: ########//
                \(generateSendFunctions(module: self, objc: true))
                """
                
                return m_string
            }
        }
    
    func build() {
        for _class in classes {
            _class.build()
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
}
class WrapClass: WrapClassBase {
    var pointer_compare_strings: [String] = []
    var pointer_compare_dict: [String:[String:String]] = [:]
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    func build() {
        generateFunctionCompares()
        doFunctionCompares()
    }
    
    func generateFunctionCompares(){
        for function in functions {
            if function.compare_string == "" {
                let compare_args = function.args.map {$0.type}
                let compare_string = "\(function.returns) \(compare_args.joined(separator: " "))"
                function.compare_string = compare_string
                if function.is_callback {
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
            if function.is_callback {
                let compare_string = function.compare_string
                let pointer_type = pointer_compare_dict[compare_string]!
                function.function_pointer = pointer_type["name"]!
            }
        }
    }
    
    
    
    
//    func export(objc: Bool, header: Bool)  -> String! {
//        for function in functions {
//            //print(function.name)
//            if let string = function.export(objc: objc, header: header) {
//                if objc {
//                    print("void \(function.name)(\(string));\n")
//                } else {
//                    print("cdef \(function.name)(\(string))\n")
//                }
//
//            }
//        }
//        return nil
//    }
}

class WrapFunctionBase: Codable {
    let name: String
    var args: [WrapArg]
    var returns: WrapArg
    let is_callback: Bool
    
}

class WrapFunction: WrapFunctionBase {
    var compare_string: String = ""
    var function_pointer = ""
    
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
        let func_args = args.filter({!$0.is_counter}).map({ arg in
            arg.export(objc: objc, header: header, use_names: use_names, py_mode: py_mode)!
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
        pyx_type = convertPythonType(type: type)
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
