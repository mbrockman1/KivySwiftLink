//
//  WrapClasses.swift
//  KivySwiftLink2
//
//  Created by MusicMaker on 15/10/2021.
//

import Foundation
import SwiftyJSON


class WrapClass: Codable {
    let title: String
    var functions: [WrapFunction]
    var decorators: [WrapClassDecorator]
    
    private enum CodingKeys: CodingKey {
        case title
        case functions
        case decorators
    }
    
    var pointer_compare_strings: [String] = []
    var pointer_compare_dict: [String:[String:String]] = [:]
    var dispatch_mode = false
    var has_swift_functions = false
    var dispatch_events: [String] = []
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try! container.decode(String.self, forKey: .title)
        functions = try! container.decode([WrapFunction].self, forKey: .functions)
        if container.contains(.decorators) {
            decorators = try container.decode([WrapClassDecorator].self, forKey: .decorators)
        } else {
            decorators = []
        }
        
        
        
        
        handleDecorators()
        for function in functions {
            function.wrap_class = self
            function.set_args_cls(cls: self)
        }
        let callback_count = functions.filter{$0.options.contains(.callback)}.count
        //let sends_count = functions.filter{!$0.is_callback && !$0.swift_func}.count
        if callback_count > 0 {
            //let func_init_string = try! JSON(extendedGraphemeClusterLiteral: "").rawData()
            //let set_callback_function = WrapFunction()
        }
    }
    func build() {
        if has_swift_functions {
            let set_swift_function: JSON = [
                "name":"set_swift_functions",
                "args": [
                    [
                        "name":"func_struct",
                        "type": "other",
                        "other_type":"\(title)SwiftFuncs",
                        "idx": 0
                    ]
                ],
                "options": ["swift_func", "callback"],
                "returns": [
                    "name": "void",
                    "type": "void",
                    "idx": 0,
                    "options": ["return_"],
                ]
            ]
            
            let decoder = JSONDecoder()
            let wrap_set_swiftfunction = try! decoder.decode(WrapFunction.self, from: set_swift_function.rawData())
            self.functions.append(wrap_set_swiftfunction)
        }
        
        
        if dispatch_mode {
            generateDispatchFunctions(cls: self, objc: false)
        }
        
        generateFunctionCompares()
        doFunctionCompares()
    }
    
    func handleDecorators() {
        let decs = decorators.map({$0.type})
        if decs.contains("EventDispatch") {self.dispatch_mode = true}
        if let dis_dec = decorators.filter({$0.type=="EventDispatch"}).first {
            dispatch_events = (dis_dec.dict[0]["events"] as! [String])
        }
        
        
        for function in self.functions {if function.has_option(option: .swift_func) {self.has_swift_functions = true; break}}
        
    }
    
    func generateFunctionCompares(){
        for function in functions {
            if function.compare_string == "" {
                let compare_args = function.args.map {$0.type.rawValue}
                let compare_string = "\(function.returns) \(compare_args.joined(separator: " "))"
                function.compare_string = compare_string
                if function.has_option(option: .callback) || function.has_option(option: .swift_func) {
                    if !pointer_compare_strings.contains(compare_string) {
                        pointer_compare_strings.append(compare_string)
                        let compare_count = pointer_compare_strings.count
                        pointer_compare_dict[compare_string] = [
                            "name": "\(title)_ptr\(compare_count)",
                            "pyx_string": function.export(options: []),
                            "objc_string": function.export(options: [.objc]),
                            "returns": function.returns.pythonType2pyx(options: []),
                            "excluded_callbacks": "\(function.has_option(option: .swift_func) && function.has_option(option: .callback))"
                            ]
                    }
                }
            }
        }
    }

    func doFunctionCompares() {
        
        for function in functions {
            if function.has_option(option: .callback) || function.has_option(option: .swift_func) {
                let compare_string = function.compare_string
                let pointer_type = pointer_compare_dict[compare_string]!
                function.function_pointer = pointer_type["name"]!
            }
        }
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
