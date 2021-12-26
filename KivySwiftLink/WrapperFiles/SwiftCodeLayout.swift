//
//  SwiftCodeLayout.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 15/12/2021.
//

import Foundation


func generateSwiftCallbackWrap(module: WrapModule) -> String {
    var rtn_strings: [String] = []
    
    for cls in module.classes {
        var call_title = cls.title.titleCase()
        call_title.removeFirst()
        let callback_title = "\(call_title)Callback"
        
        let functions = cls.functions.filter{$0.has_option(option: .callback)}
        let call_pointers = functions.map{ f -> String in
            let direct = f.options.contains(.direct)
            return "\(if: direct, "let ", "private let _")\(f.name): \(f.function_pointer)"
        }.joined(separator: newLineTab)
        let set_call_pointers = functions.map{"\(if: $0.options.contains(.direct), "", "_")\($0.name) = callback.\($0.name)"}.joined(separator: newLineTabTab)
        let call_funcs = functions.filter(
            {!$0.options.contains(.direct)}).map{ f -> String in
                let _args = f.args.map{"\(swiftCallbackArgs(arg: $0))"}.joined(separator: ", ")
                return """
                func \(f.name)(\(f.export(options: [.use_names, .swift, .protocols]))) {
                        _\(f.name)(\(_args))
                    }
                """
        }
        rtn_strings.append("""
        struct \(cls.title)PyCallback {
            private let pycall: \(cls.title)Callbacks
            \(call_pointers)

            init(callback: \(cls.title)Callbacks){
                pycall = callback
                \(set_call_pointers)
            }
            
            \(call_funcs.joined(separator: newLineTab))
        }

        //var \(callback_title): \(cls.title)PyCallback!
        """)
    }
    return rtn_strings.joined(separator: newLine)
}
