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
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try! container.decode(String.self, forKey: .title)
        functions = try! container.decode([WrapFunction].self, forKey: .functions)
        decorators = try! container.decode([WrapClassDecorator].self, forKey: .decorators)
        
        
        handleDecorators()
        let callback_count = functions.filter{$0.is_callback}.count
        //let sends_count = functions.filter{!$0.is_callback && !$0.swift_func}.count
        if callback_count > 0 {
            //let func_init_string = try! JSON(extendedGraphemeClusterLiteral: "").rawData()
            //let set_callback_function = WrapFunction()
        }
    }
    func build() {
        //print("build",self,has_swift_functions)
        if has_swift_functions {
            let set_swift_function: JSON = [
                "name":"set_swift_functions",
                "args": [
                    [
                        "name":"func_struct",
                        "type":"PythonCoreMidiSwiftFuncs",
                        "idx": 0
                    ]
                ],
                "swift_func": true,
                "is_callback": true,
                "returns": [
                    "name": "void",
                    "type": "void",
                    "idx": 0,
                    "is_return": true
                ]
            ]
            
            let decoder = JSONDecoder()
            let wrap_set_swiftfunction = try! decoder.decode(WrapFunction.self, from: set_swift_function.rawData())
            self.functions.append(wrap_set_swiftfunction)
        }
        
        
        
        
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
                let compare_args = function.args.map {$0.type.rawValue}
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
                            "returns": pythonType2pyx(type: function.returns.type, options: []),
                            "excluded_callbacks": "\(function.swift_func && function.is_callback)"
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
