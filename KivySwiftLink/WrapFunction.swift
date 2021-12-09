//
//  WrapFunction.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 06/12/2021.
//

import Foundation


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
