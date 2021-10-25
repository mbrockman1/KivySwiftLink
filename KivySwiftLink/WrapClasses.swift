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
            var EnumStrings: String = ""
            var swift_funcs_struct = ""
            if dispatchEnabled {
                let dis_dec = cls.decorators.filter({$0.type=="EventDispatch"})[0]
                let events = (dis_dec.dict[0]["events"] as! [String]).map({"\"\($0)\""})
                class_vars.append("""
                \tevents = [\(events.joined(separator: ", "))]

                """)
                class_ext_options.append(.event_dispatch)
                EnumStrings = generateEnums(cls: cls, options: [.cython,.dispatch_events])
            }
            if cls.has_swift_functions {
                class_ext_options.append(.swift_functions)
                class_vars.append("\t" + cls.functions.filter{$0.swift_func}.map{"cdef \($0.function_pointer) _\($0.name)_"}.joined(separator: "\n\t") + newLine)
                swift_funcs_struct = generateStruct(module: self, options: [.swift_functions])
            }
            
            let pyx_string = """
            cdef extern from "_\(filename).h":
                ######## cdef extern Callback Function Pointers: ########
                \(generateFunctionPointers(module: self, objc: false))

                ######## cdef extern Callback Struct: ########
                \(generateStruct(module: self, options: [.callbacks]))
                \(swift_funcs_struct)
                ######## cdef extern Send Functions: ########
                void set_\(cls.title)_Callback(\(cls.title)Callbacks callback)
                \(generateSendFunctions(module: self, objc: false))
                \(if: cls.dispatch_mode, generateEnums(cls: cls, options: [.cython,.dispatch_events]))
            ######## Callbacks Functions: ########
            \(generateCallbackFunctions(module: self, options: [.header]))

            ######## Cython Class: ########
            \(generateCythonClass(_class: cls.title, class_vars: class_vars.joined(separator: newLine), dispatch_mode: cls.dispatch_mode))

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
        let cls = self.classes[0]
        let h_string = """
        #import <Foundation/Foundation.h>
        #import "wrapper_typedefs.h"
        //insert enums / Structs
        \(if: cls.dispatch_mode,generateEnums(cls: cls, options: [.dispatch_events, .objc]))
        //######## cdef extern Callback Function Pointers: ########//
        \(generateFunctionPointers(module: self, objc: true))
        
        //######## cdef extern Callback Struct: ########//
        \(generateStruct(module: self, options: [.objc, .callbacks]))
        \(if: cls.has_swift_functions, generateStruct(module: self, options: [.swift_functions, .objc]) )
        //######## Send Functions Protocol: ########//
        \(generateSendProtocol(module: self))
        \(generateHandlerFuncs(cls: cls, options: [.objc_h, .init_delegate, .callback]))
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
        \(generateHandlerFuncs(cls: self.classes[0], options: [.objc_m, .init_delegate, .callback]))
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
        let test_types = ["object","json","jsondata","data","str", "bytes"]
        for cls in classes {
            for function in cls.functions {
                let returns = function.returns
                if !usedTypes.contains(where: {$0.type == returns.type && ($0.is_list == returns.is_list)}) {
                    if returns.is_list || returns.is_data || returns.is_json || test_types.contains(returns.type) {
                        usedTypes.append(returns)
                    }
                        
                }
                                    
                for arg in function.args {
                    
                    
                    if !usedTypes.contains(where: {$0.type == arg.type && ($0.is_list == arg.is_list)}) {
                        if arg.is_list || arg.is_data || arg.is_json || test_types.contains(arg.type){
                            usedTypes.append(arg)
                        }
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
        handleDecorators()
        let callback_count = functions.filter{$0.is_callback}.count
        let sends_count = functions.filter{!$0.is_callback && !$0.swift_func}.count
        if callback_count > 0 {
            //let func_init_string = try! JSON(extendedGraphemeClusterLiteral: "").rawData()
            //let set_callback_function = WrapFunction()
        }
    }
    func build() {
        generateFunctionCompares()
        doFunctionCompares()
    }
    
    func handleDecorators() {
        let decs = decorators.map({$0.type})
        if decs.contains("EventDispatch") {self.dispatch_mode = true}
        for function in self.functions {if function.swift_func {self.has_swift_functions = true; break}}
        
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
                            "pyx_string": function.export(options: []),
                            "objc_string": function.export(options: [.objc]),
                            "returns": pythonType2pyx(type: function.returns.type, options: [])
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
    
    func get_callArg(name: String) -> WrapArg! {
        for arg in args {
            if arg.name == name {
                return arg
            }
        }
        return nil
    }
    
    func call_args(cython_callback: Bool = false) -> [String] {
        var call_class = ""
        var call_target = ""
        //print("call_args:")
        if self.call_class != nil {call_class = self.call_class}
        if self.call_target != nil {call_target = self.call_target}
        let _args = args.filter{arg -> Bool in
            arg.name != call_target && arg.name != call_class
        }
        return _args.map {
            //print($0.name,$0.is_counter!, cython_callback)
            if !$0.is_counter!   {
                return convertPythonCallArg(arg: $0)
                }
            return ""
        }.filter({$0 != ""})
    }
    
    var call_args_cython: [String] {
        var call_class = ""
        var call_target = ""
        if self.call_class != nil {call_class = self.call_class}
        if self.call_target != nil {call_target = self.call_target}
        let _args = args.filter{arg -> Bool in
            arg.name != call_target && arg.name != call_class
        }
        return _args.map {
            if !$0.is_counter! {
                return convertPythonCallArg(arg: $0)
                }
            return ""
        }.filter({$0 != ""})
    }
    
    var send_args: [String] {
        args.map {
//        args.filter{$0.is_counter!}.map {
            //if !$0.is_counter {
            //var name: String
            var send_options: [PythonSendArgTypes] = []
            if $0.is_list {send_options.append(.list)}
            return convertPythonSendArg(type: $0.type, name: $0.name, options: send_options)
        }.filter({$0 != ""})
    }
    
    var send_args_py: [String] {
        args.map {
        //args.filter{!$0.is_counter!}.map {
            //if !$0.is_counter {
            //var name: String
            var send_options: [PythonSendArgTypes] = []
            if $0.is_list {send_options.append(.list)}
            return convertPythonSendArg(type: $0.type, name: $0.name, options: send_options)
        }.filter({$0 != ""})
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    

    
    
    func export(options: [PythonTypeConvertOptions])  -> String {
        //print("export", options)
        if options.contains(.objc) {
            let func_args = args.map({ arg in
                arg.export(options: options)!
            })
            if options.contains(.header) {
                return func_args.joined(separator: " ")
            } else {
                return func_args.joined(separator: ", ")
            }
            
        }
        var _args: [WrapArg]
        if options.contains(.py_mode) {
            _args = args.filter({!$0.is_counter})
        } else {
            _args = args
        }
//        _args = _args.filter{arg -> Bool in
//            arg.name != call_target && arg.name != call_class
//        }
        let func_args = _args.map({ arg in
            
            return arg.export(options: options)!
        })
        return func_args.joined(separator: ", ")
//        if options.contains(.header) {
//            return func_args.joined(separator: " ")
//        } else {
//            return func_args.joined(separator: ", ")
//        }
        
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
    
    
    var is_tuple: Bool!
    var tuple_types: [WrapArg]!
}

class WrapArg: WrapArgBase, Equatable {
    
    
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
        if is_tuple == nil {
            is_tuple = false
        }
        set_types()
    }
    
    static func ==(lhs: WrapArg , rhs: WrapArg) -> Bool {
        return lhs.type == lhs.type
    }
    
    func set_types() {
        pyx_name = name
        var pyx_type_options: [PythonTypeConvertOptions] = []
        let objc_type_options: [PythonTypeConvertOptions] = [.objc]
        if is_list! {
            pyx_type_options.append(.is_list)
        }
        pyx_type = convertPythonType(type: type, options: pyx_type_options)
        objc_name = "arg\(idx)"
        objc_type = convertPythonType(type: type, options: objc_type_options)
        size = TYPE_SIZES[type]
        
    }
    

    
    func export(options: [PythonTypeConvertOptions]) -> String! {
        var _name: String
        if options.contains(.use_names) {
            _name = name
        } else {
            _name = objc_name!
        }
        if options.contains(.objc) {
            if options.contains(.header) {
                var header_string = ""
                switch idx {
                case 0:
                    header_string.append(":(\(convertPythonType(type: type, options: options) ))\(_name)")
                default:
                    header_string.append("\(name):(\(convertPythonType(type: type, options: options) ))\(_name)")
                }
                //let func_string = "\(convertPythonType(type: type, is_list: is_list, objc: objc, header: header)) \(objc_name!)"
                return header_string
            } else {
                let func_string = "\(convertPythonType(type: type, options: options)) \(_name)"
                return func_string
            }
        }
        if options.contains(.py_mode) {
            if is_list {return "\(name): List[\(PurePythonTypeConverter(type: type))]"}
            return "\(name): \(PurePythonTypeConverter(type: type))"
        }
        var arg_options = options
        if self.is_list {
            arg_options.append(.is_list)
        }
        let func_string = "\(convertPythonType(type: type, options: arg_options)) \(_name)"
        //let func_string = "\(convertPythonType(type: PurePythonTypeConverter(type: type), options: options)) \(_name)"
        return func_string
    }
}


class WrapClassDecoratorBase: Codable {
    let type: String
    let args: [String]
}

class WrapClassDecorator: WrapClassDecoratorBase {
    var dict: [[String:Any]] = []
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        dict.append(contentsOf: args.map({JSON(parseJSON: $0).dictionaryObject!}))
    }
}
