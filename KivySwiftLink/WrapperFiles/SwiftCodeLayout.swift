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
        let call_title = try! cls.title.split(whereSeparator: { (char) -> Bool in
            char.isUppercase
        }).joined(separator: "_")
        let callback_title = "\(call_title.lowercased())Callback"
        
        let functions = cls.functions.filter{$0.is_callback}.map{"\($0.name)"}
        rtn_strings.append("""
        struct \(cls.title)PyCallback {
            let pycall: \(cls.title)Callbacks
            
            init(callback: \(cls.title)Callbacks){
                pycall = callback
            }
        }

        var \(callback_title): \(cls.title)PyCallback!
        """)
    }
    return rtn_strings.joined(separator: newLine)
}
