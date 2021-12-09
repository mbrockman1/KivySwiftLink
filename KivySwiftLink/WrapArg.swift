//
//  WrapArg.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 06/12/2021.
//

import Foundation

class WrapArgBase: Codable {
    let name: String
    let type: PythonType
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
        var objc_type_options: [PythonTypeConvertOptions] = [.objc]
        if is_list! {
            pyx_type_options.append(.is_list)
            objc_type_options.append(.is_list)
        }
        pyx_type = convertPythonType(type: type, options: pyx_type_options)
        objc_name = "arg\(idx)"
        objc_type = convertPythonType(type: type, options: objc_type_options)
        size = TYPE_SIZES[type.rawValue]
        
    }
    

    
    func export(options: [PythonTypeConvertOptions]) -> String! {
        var options = options
        var _name: String
        if options.contains(.use_names) {
            _name = name
        } else {
            _name = objc_name!
        }
        
        if options.contains(.objc) {
            if self.is_list {options.append(.is_list)}
            if options.contains(.header) {
                var header_string = ""
                switch idx {
                case 0:
                    header_string.append(":(\(convertPythonType(type: type, options: options) ))\(name)")
                default:
                    //header_string.append("\(name):(\(convertPythonType(type: type, options: options) ))\(name)")
                    header_string.append(":(\(convertPythonType(type: type, options: options) ))\(name)")
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
