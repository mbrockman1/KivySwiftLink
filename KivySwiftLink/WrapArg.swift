//
//  WrapArg.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 06/12/2021.
//


let PythonTypes_String = PythonType.allCases.map({$0.rawValue})

import Foundation

class WrapArgBase: Codable {
    let name: String
    let type: PythonType
    let other_type: String
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
    
    
    private enum CodingKeys: CodingKey {
            case name
            case type
            case idx
            }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            type = try container.decode(PythonType.self, forKey: .type)
            other_type = ""
        } catch {
            type = .other
            other_type = try container.decode(String.self, forKey: .type)
            print(type, other_type)
        }
        
        name = try! container.decode(String.self, forKey: .name)
        idx = try! container.decode(Int.self, forKey: .idx)
    }
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
        if type == .other {
            pyx_type = other_type
            objc_type = other_type
        } else {
            pyx_type = convertPythonType(type: type, options: pyx_type_options)
            objc_type = convertPythonType(type: type, options: objc_type_options)
        }
        
        objc_name = "arg\(idx)"
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
        if type == .other { print(type,other_type, options)}
        if options.contains(.objc) {
            if self.is_list {options.append(.is_list)}
            if options.contains(.header) {
                var header_string = ""
                switch idx {
                case 0:
                    if type == .other {
                        
                    } else {
                        header_string.append(":(\(convertPythonType(type: type, options: options) ))\(name)")
                    }
                    
                default:
                    //header_string.append("\(name):(\(convertPythonType(type: type, options: options) ))\(name)")
                    header_string.append(":(\(convertPythonType(type: type, options: options) ))\(name)")
                }
                //let func_string = "\(convertPythonType(type: type, is_list: is_list, objc: objc, header: header)) \(objc_name!)"
                return header_string
            } else {
                if type == .other {return "\(other_type) \(_name)"}
                let func_string = "\(convertPythonType(type: type, options: options)) \(_name)"
                return func_string
            }
        }
        if options.contains(.py_mode) {
            if is_list {return "\(name): List[\(PurePythonTypeConverter(type: type))]"}
            
            if type == .other {
                print(other_type)
                return "\(name): \(other_type)"
            }
            return "\(name): \(PurePythonTypeConverter(type: type))"
        }
        var arg_options = options
        if self.is_list {
            arg_options.append(.is_list)
        }
        if type == .other {return "\(other_type) \(_name)"}
        let func_string = "\(convertPythonType(type: type, options: arg_options)) \(_name)"
        //let func_string = "\(convertPythonType(type: PurePythonTypeConverter(type: type), options: options)) \(_name)"
        return func_string
    }
}
