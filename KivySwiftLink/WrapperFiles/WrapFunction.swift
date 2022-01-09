//
//  WrapFunction.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 06/12/2021.
//

import Foundation

enum WrapFunctionOption: String, CaseIterable,Codable {
    case list
    case data
    case json
    case callback
    case swift_func
    case dispatch
    case direct
}

class WrapFunction: Codable {
    let name: String
    var args: [WrapArg]
    let returns: WrapArg
    //let is_callback: Bool
    //let swift_func: Bool
    //let direct: Bool
    let call_class: String!
    let call_target: String!
    
    var options: [WrapFunctionOption]
    
    
    //let is_dispatch: Bool
    
    private enum CodingKeys: CodingKey {
        case name
        case args
        case returns
        //case is_callback
        //case swift_func
        case call_class
        case call_target
        //case is_dispatch
        //case direct
        case options
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
            returns = WrapArg(name: "", type: .void, other_type: "", idx: 0, arg_options: [.return_])
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
        
        
        if container.contains(.options) {
            options = try! container.decode([WrapFunctionOption].self, forKey: .options)
        } else {
            options = []
        }
    }
    
    func has_option(option: WrapFunctionOption) -> Bool {
        return options.contains(option)
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
            $0.convertPythonCallArg
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
            $0.convertPythonCallArg
        }.filter({$0 != ""})
    }
    
    var send_args: [String] {
        args.map {

            var send_options: [PythonSendArgTypes] = []
            if $0.has_option(.list) {send_options.append(.list)}
            return $0.convertPythonSendArg(options: send_options)
        }.filter({$0 != ""})
    }
    
    var send_args_py: [String] {
        args.map { arg -> String in
            var send_options: [PythonSendArgTypes] = []
            if arg.has_option(.list) {send_options.append(.list)}
            if arg.type == .other {
                if let wrap_module = wrap_module_shared {
                    if let customcstruct = wrap_module.custom_structs.first(where: { (custom) -> Bool in
                        custom.title == arg.other_type
                    }) {
                        for sub in customcstruct.sub_classes {
                            switch sub {
                            case .Codable:
                                //return "json.dumps(\(arg.name).__dict__).encode()"
                                return "[j_\(arg.name), \(arg.name)_size]"
                            }
                        }
                    }
                    
                }
                
            }
            return arg.convertPythonSendArg(options: send_options)
        }.filter({$0 != ""})
    }
    
    func export(options: [PythonTypeConvertOptions])  -> String {
        if options.contains(.objc) {
            let func_args = args.map({ arg in
                arg.export(options: options)!
            })
//            if options.contains(.header) {
//                return func_args.joined(separator: " ")
//            } else {
                return func_args.joined(separator: ", ")
//            }
        }
        
        if options.contains(.swift) {
            let func_args = args.map({ arg in
                arg.export(options: options)!
            })
 
            return func_args.joined(separator: ", ")
            
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




extension WrapFunction {
    func convertReturnSend(rname: String, code: String) -> String {
        let rtype = returns.type
        
        switch rtype {
        case .str:
            if returns.has_option(.list) {
                return "[rtn_val.ptr[x].decode() for x in range(rtn_val.size)]"
            }
            return "\(code).decode()"
        case .data:
            if returns.has_option(.list) {
                return "[rtn_val.ptr[x].ptr[:rtn_val.ptr[x].size] for x in range(rtn_val.size)]"
            }
            return "rtn_val.ptr[:rtn_val.size]"
        case .jsondata:
            if returns.has_option(.list) {
                return "[json.loads(rtn_val.ptr[x].ptr[:rtn_val.ptr[x].size]) for x in range(rtn_val.size)]"
            }
            return "json.loads(rtn_val.ptr[:rtn_val.size])"
        case .object:
            if returns.has_option(.list) {
                return "[(<object>rtn_val.ptr[x]) for x in range(rtn_val.size)]"
            }
            return "<object>\(code)"
        default:
            if returns.has_option(.list) {
                return "[rtn_val.ptr[x] for x in range(rtn_val.size)]"
            }
            return code
        }
    }
    
    var call_target_is_arg: Bool {
        let _args = args.map{$0.name}
        if let call_target = call_target {
            if _args.contains(call_target) {
                return true
            }
        }
        return false
        
    }

    var call_class_is_arg: Bool {
        let _args = args.map{$0.name}
        if let call_class = call_class {
            if _args.contains(call_class) {
                return true
            }
        }
        return false
    }

}
