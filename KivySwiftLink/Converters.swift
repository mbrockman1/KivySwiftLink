//
//  Converters.swift
//  KivySwiftLink2
//
//  Created by MusicMaker on 15/10/2021.
//

import Foundation

enum PythonType: String, CaseIterable {
    case int
    case long
    case ulong
    case uint
    case int32
    case uint32
    case int8
    case char
    case uint8
    case uchar
    case ushort
    case short
    case int16
    case uint16
    case longlong
    case ulonglong
    case float
    case double
    case float32
    case str
    case bytes
    case data
    case json
    case jsondata
    case list
    case object
    case bool
    case void
}



enum pyx_types: String {
    case int32
    case uint32
}
let TYPE_SIZES: [String:Int] = [
    "PythonCallback": 0,
    "int": MemoryLayout<CLong>.size,
    "long": MemoryLayout<CLong>.size,
    "ulong": MemoryLayout<CUnsignedLong>.size,
    "uint": MemoryLayout<CUnsignedLong>.size,
    "int32": MemoryLayout<CInt>.size,
    "uint32": MemoryLayout<CUnsignedInt>.size,
    "int8": MemoryLayout<CChar>.size,
    "char": MemoryLayout<CChar>.size,
    "uint8": MemoryLayout<CUnsignedChar>.size,
    "uchar": MemoryLayout<CUnsignedChar>.size,
    "short": MemoryLayout<CShort>.size,
    "ushort": MemoryLayout<CUnsignedShort>.size,
    "int16": MemoryLayout<CShort>.size,
    "uint16": MemoryLayout<CUnsignedShort>.size,
    "longlong": MemoryLayout<CLongLong>.size,
    "ulonglong": MemoryLayout<CUnsignedLongLong>.size,
    "float": MemoryLayout<CDouble>.size,
    "double": MemoryLayout<CDouble>.size,
    "float32": MemoryLayout<CFloat>.size,
    "object": MemoryLayout<UnsafeRawPointer>.size,
    "data": MemoryLayout<CUnsignedChar>.size,
    "bytes": MemoryLayout<CChar>.size,
    
]

let PYCALL_TYPES = [
    "PythonCallback": "PythonCallback",
    "int": "Int",
    "long": "Int",
    "ulong": "UInt",
    "uint": "UInt",
    "int32": "Int32",
    "uint32": "UInt32",
    "int8": "Int8",
    "char": "Int8",
    "short": "Int16",
    "uint8": "UInt8",
    "uchar": "UInt8",
    "ushort": "UInt16",
    "int16": "Int16",
    "uint16": "UInt16",
    "longlong": "Int64",
    "ulonglong": "UInt64",
    "float": "Double",
    "double": "Double",
    "float32": "Float",
    "object": "PythonObject",
    "data": "PythonData",
    "bytes": "PythonBytes",
    "jsondata": "PythonJsonData",
    "str": "PythonString"
]



let SWIFT_TYPES = [
    "PythonCallback": "PythonCallback",
    "int": "Int",
    "long": "Int",
    "ulong": "UInt",
    "uint": "UInt",
    "int32": "Int32",
    "uint32": "UInt32",
    "int8": "Int8",
    "char": "Int8",
    "short": "Int16",
    "uint8": "UInt8",
    "uchar": "UInt8",
    "ushort": "UInt16",
    "int16": "Int16",
    "uint16": "UInt16",
    "longlong": "Int64",
    "ulonglong": "UInt64",
    "float": "Double",
    "double": "Double",
    "float32": "Float",
    "object": "PythonObject",
    "data": "PythonData",
    "jsondata": "PythonJsonData",
    "json": "PythonJsonString",
    "bytes": "PythonBytes",
    "str": "PythonString",
    "bool": "Bool"
]


let TYPEDEF_BASETYPES = [
    "PythonObject",
    "PythonData",
    "PythonJsonData",
    "PythonBytes",
    "PythonString"
]

func get_typedef_types() -> [String]  {
    var types = TYPEDEF_BASETYPES
    
    for type in PythonType.allCases {
        switch type {
        case .list, .void:
            ""
        default:
            types.append(convertPythonListType(type: type.rawValue))
        }
        
    }
    
    
    return types
}


func pythonType2pyx(type: String, objc: Bool = false, header: Bool = false) -> String {
    var export: String
    var nonnull = false
    switch PythonType(rawValue: type) {
    
    case .bool:
        if objc {
            export = "BOOL"
        } else {
            export = "bint"
        }
    
    case .long, .int:
        export = "long"
        
    case .ulong, .uint:
        export = "unsigned long"
        
    case .int32:
        if objc {
            export = "int"
        } else {
            export = type
        }
        
    case .uint32:
        export = "unsigned int"
        
    case .int8, .char:
        export = "char"
        
    case .uint8, .uchar:
        export = "unsigned char"
    
    case .int16, .short:
        export = "short"
    case .uint16, .ushort:
        export = "unsigned short"

    case .float, .double:
        export = "double"
    case .float32:
        export = "float"
    //plain python types
    case .object:
        export = "PythonObject"
        nonnull = true
    case .str:
        export = "PythonString"
        nonnull = true
    case .bytes:
        export = "PythonBytes"
        nonnull = true
        
    //special types
    case .data:
        export = "PythonData"
        nonnull = true
    case .json:
        export = "PythonJsonString"
        nonnull = true
    case .jsondata:
        export = "PythonJsonData"
        nonnull = true
    case .void:
        export = "void"
    default:
        print("\(type) is not supported")
        fatalError()
    }
    if objc {
        if header {
            if nonnull {
                return "\(export) _Nonnull"
            }
            return export
            
        } else {
            if nonnull {
                return "\(export) _Nonnull"
            }
            return export
        }
    } else {
        return export
    }
    
}

func convertPythonType(type: String, is_list: Bool = false, objc: Bool = false, header: Bool = false) -> String {
    if is_list {
        return convertPythonListType(type: type, objc: objc, header: header)
    }
    return pythonType2pyx(type: type, objc: objc, header: header)
}

func convertPythonListType(type: String, objc: Bool = false, header: Bool = false) -> String {
    return "PythonList_\(SWIFT_TYPES[type]!)"
}


func convertPythonCallArg(type: String, name: String, is_list_data: Bool = false) -> String {
    
    switch PythonType(rawValue: type) {
    case .str:
        if is_list_data {return "[\(name)[x].decode('utf8') for x in range(\(name)_size)]"}
        return "\(name).decode('utf-8')"
    case .data:
        if is_list_data {return "\(name)[:\(name)_size]"}
        return "<bytes>\(name)[0:\(name)_size]"
    case .json:
        return "json.loads(\(name))"
    case .jsondata:
        return "json.loads(\(name)[:\(name)_size])"
    case .object:
        if is_list_data {return "[<object>\(name)[x] for x in range(\(name)_size)]"}
        return "<object>\(name)"
    default:
        if is_list_data {return "[\(name)[x].decode('utf8') for x in range(\(name)_size)]"}
        return name
    }
}



func convertPythonSendArg(type: String, name: String, is_list_data: Bool = false) -> String {
    
    switch PythonType(rawValue: type) {
    case .str:
        if is_list_data {return "\(name)_array, \(name)_size"}
        return "\(name).encode('utf-8')"
    case .data:
        if is_list_data {return "\(name)_array, \(name)_size"}
        return "<bytes>\(name)[0:\(name)_size]"
    case .json:
        return "json.dumps(\(name)).encode('utf-8')"
    case .jsondata:
        return "json.dumps(\(name)).encode('utf-8')"
    case .object:
        if is_list_data {return "\(name)_array, \(name)_size"}
        return "<PythonObject>\(name)"
    default:
        if is_list_data {return "\(name)_array, \(name)_size"}
        return name
    }
}
