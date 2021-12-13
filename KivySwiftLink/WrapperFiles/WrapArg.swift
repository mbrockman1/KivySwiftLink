//
//  WrapArg.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 06/12/2021.
//


let PythonTypes_String = PythonType.allCases.map({$0.rawValue})

import Foundation

class WrapArg: Codable, Equatable {
    var name: String
    var type: PythonType
    var other_type: String
    var idx: Int
    
    
    var is_return: Bool
    var is_list: Bool
    var is_json: Bool
    var is_data: Bool
    var is_tuple: Bool
    var is_enum: Bool
    
    var objc_name: String
    var objc_type: String
    
    var pyx_name: String
    var pyx_type: String
    
    var size: Int
    
    
    
    var tuple_types: [WrapArg]!
    var cls: WrapClass!
    
    private enum CodingKeys: CodingKey {
        case name
        case type
        case other_type
        case idx
        case is_return
        case is_list
        case is_data
        case is_json
        case is_tuple
        case is_enum
        }
    
    init(name: String, type: PythonType, other_type: String, idx: Int, is_return: Bool, is_list: Bool, is_json: Bool, is_data: Bool, is_tuple: Bool, is_enum: Bool) {
            self.name = name
            self.type = type
            self.other_type = other_type
            self.idx = idx
            self.is_return = is_return
            self.is_list = is_list
            self.is_json = is_json
            self.is_data = is_data
            self.is_tuple = is_tuple
            self.is_enum = is_enum
            
            pyx_name = name
            objc_name = "arg\(idx)"
            
            var pyx_type_options: [PythonTypeConvertOptions] = []
            var objc_type_options: [PythonTypeConvertOptions] = [.objc]
            if is_list {
                pyx_type_options.append(.is_list)
                objc_type_options.append(.is_list)
            }
            if type == .other {
                size = 8
                pyx_type = other_type
                objc_type = other_type
            } else {
                size = TYPE_SIZES[type.rawValue]!
                pyx_type = convertPythonType(type: type, options: pyx_type_options)
                objc_type = convertPythonType(type: type, options: objc_type_options)
            }
        }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try! container.decode(String.self, forKey: .name)
        idx = try! container.decode(Int.self, forKey: .idx)
        do {
            type = try container.decode(PythonType.self, forKey: .type)
        } catch {
            type = .other
        }
        if container.contains(.other_type) {
            other_type = try container.decode(String.self, forKey: .other_type)
        } else {
            other_type = try container.decode(String.self, forKey: .type)
        }
        if container.contains(.is_data) {
            is_data = try! container.decode(Bool.self, forKey: .is_data)
        } else {
            is_data = false
        }
        if container.contains(.is_json) {
            is_json = try container.decode(Bool.self, forKey: .is_json)
        } else {
            is_json = false
        }
        if container.contains(.is_list) {
            is_list = try container.decode(Bool.self, forKey: .is_list)
        } else {
            is_list = false
        }
        if container.contains(.is_return) {
            is_return = try container.decode(Bool.self, forKey: .is_return)
        } else {
            is_return = false
        }
        if container.contains(.is_tuple) {
            is_tuple = try container.decode(Bool.self, forKey: .is_tuple)
        } else {
            is_tuple = false
        }
        if container.contains(.is_enum) {
            is_enum = try container.decode(Bool.self, forKey: .is_enum)
        } else {
            is_enum = false
        }
        
        pyx_name = name
        objc_name = "arg\(idx)"
        
        var pyx_type_options: [PythonTypeConvertOptions] = []
        var objc_type_options: [PythonTypeConvertOptions] = [.objc]
        if is_list {
            pyx_type_options.append(.is_list)
            objc_type_options.append(.is_list)
        }
        if type == .other {
            size = 8
            pyx_type = other_type
            objc_type = other_type
        } else {
            size = TYPE_SIZES[type.rawValue]!
            pyx_type = convertPythonType(type: type, options: pyx_type_options)
            objc_type = convertPythonType(type: type, options: objc_type_options)
        }
        
                
    }
    
    static func ==(lhs: WrapArg , rhs: WrapArg) -> Bool {
            return lhs.type == lhs.type
        }

    
    
    func export(options: [PythonTypeConvertOptions]) -> String! {
        var options = options
        var _name: String
        if options.contains(.use_names) {
            _name = name
        } else {
            _name = objc_name
        }
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



extension WrapArg {
    
//    convenience init(name: String, type: PythonType, other_type: String, idx: Int, is_return: Bool, is_list: Bool, is_json: Bool, is_data: Bool, is_tuple: Bool, is_enum: Bool) {
//        self.init()
//        self.name = name
//        self.type = type
//        self.other_type = other_type
//        self.idx = idx
//        self.is_return = is_return
//        self.is_list = is_list
//        self.is_json = is_json
//        self.is_data = is_data
//        self.is_tuple = is_tuple
//        self.is_enum = is_enum
//
//        pyx_name = name
//        objc_name = "arg\(idx)"
//
//        var pyx_type_options: [PythonTypeConvertOptions] = []
//        var objc_type_options: [PythonTypeConvertOptions] = [.objc]
//        if is_list {
//            pyx_type_options.append(.is_list)
//            objc_type_options.append(.is_list)
//        }
//        if type == .other {
//            size = 8
//            pyx_type = other_type
//            objc_type = other_type
//        } else {
//            size = TYPE_SIZES[type.rawValue]!
//            pyx_type = convertPythonType(type: type, options: pyx_type_options)
//            objc_type = convertPythonType(type: type, options: objc_type_options)
//        }
//    }
   
}
