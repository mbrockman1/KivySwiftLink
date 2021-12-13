//
//  WrapFunction.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 06/12/2021.
//

import Foundation



class WrapFunction: Codable {
    let name: String
    var args: [WrapArg]
    let returns: WrapArg
    let is_callback: Bool
    let swift_func: Bool
    let call_class: String!
    let call_target: String!
    
    
    let is_dispatch: Bool
    
    private enum CodingKeys: CodingKey {
        case name
        case args
        case returns
        case is_callback
        case swift_func
        case call_class
        case call_target
        case is_dispatch
    }
    
    var compare_string: String = ""
    var function_pointer = ""
    var wrap_class: WrapClass!
    
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.name) {
            name = try! container.decode(String.self, forKey: .name)
        } else {
            name = ""
        }
        if container.contains(.args) {
            args = try! container.decode([WrapArg].self, forKey: .args)
        } else {
            args = []
        }
        if container.contains(.returns) {
            returns = try! container.decode(WrapArg.self, forKey: .returns)
        } else {
            returns = WrapArg(name: "", type: .void, other_type: "", idx: 0, is_return: true, is_list: false, is_json: false, is_data: false, is_tuple: false, is_enum: false)
        }
        if container.contains(.is_callback) {
            is_callback = try! container.decode(Bool.self, forKey: .is_callback)
        } else {
            is_callback = false
        }
        if container.contains(.swift_func) {
            swift_func = try! container.decode(Bool.self, forKey: .swift_func)
        } else {
            swift_func = false
        }
        if container.contains(.call_class) {
            call_class = try! container.decode(String.self, forKey: .call_class)
        } else {
            call_class = nil
        }
        if container.contains(.call_target) {
            call_target = try! container.decode(String.self, forKey: .call_target)
        } else {
            call_target = nil
        }
        
        if container.contains(.is_dispatch) {
            is_dispatch = try! container.decode(Bool.self, forKey: .is_dispatch)
        } else {
            is_dispatch = false
        }
    }
    
    func set_args_cls(cls: WrapClass) {
        for arg in args {
            arg.cls = cls
        }
    }
    
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
        if self.call_class != nil {call_class = self.call_class}
        if self.call_target != nil {call_target = self.call_target}
        let _args = args.filter{arg -> Bool in
            arg.name != call_target && arg.name != call_class
        }
        return _args.map {
            convertPythonCallArg(arg: $0)
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
            convertPythonCallArg(arg: $0)
        }.filter({$0 != ""})
    }
    
    var send_args: [String] {
        args.map {

            var send_options: [PythonSendArgTypes] = []
            if $0.is_list {send_options.append(.list)}
            return convertPythonSendArg(type: $0.type, name: $0.name, options: send_options)
        }.filter({$0 != ""})
    }
    
    var send_args_py: [String] {
        args.map {
            var send_options: [PythonSendArgTypes] = []
            if $0.is_list {send_options.append(.list)}
            return convertPythonSendArg(type: $0.type, name: $0.name, options: send_options)
        }.filter({$0 != ""})
    }
    
    func export(options: [PythonTypeConvertOptions])  -> String {
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
            _args = args
        } else {
            _args = args
        }
        let func_args = _args.map({ arg in
            return arg.export(options: options)!
        })
        return func_args.joined(separator: ", ")
    }
    
}
