//
//  Converters.swift
//  KivySwiftLink2
//
//  Created by MusicMaker on 15/10/2021.
//

import Foundation
let tab = "\t"
let tabNewLine = "\t\n"
let newLine = "\n"
let newLineTab = "\n\t"
let newLineTabTab = "\n\t\t"


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
    "jsondata": MemoryLayout<CUnsignedChar>.size,
    "json": MemoryLayout<CChar>.size,
    "bool": MemoryLayout<CBool>.size,
    "str": MemoryLayout<CChar>.size,
    "void": MemoryLayout<Void>.size
    
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
    "bool": "Bool",
    "void": "Void"
]

let MALLOC_TYPES = [
    "PythonCallback": "PythonCallback",
    "int": "int",
    "long": "long",
    "ulong": "unsigned ",
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


let TYPEDEF_BASETYPES: [String:String] = [:]


func get_typedef_types() -> [String: String]  {
    var types = TYPEDEF_BASETYPES
    
    for type in PythonType.allCases {
        switch type {
        case .list, .void:
            continue
        default:
            //types.append((type.rawValue,convertPythonListType(type: type.rawValue)))
            types[type.rawValue] = convertPythonListType_(type: type, options: [.c_type])
        }
        
    }
    
    
    return types
}



func PurePythonTypeConverter(type: PythonType) -> String{
    
    switch type {
    case .int, .int16, .int8 ,.short, .int32, .long, .longlong, .uint, .uint8, .uint16, .ushort, .uint32, .ulong, .ulonglong:
        return "int"
    case .float, .float32, .double:
        return "float"
        
    case .bytes, .char, .data, .uchar:
        return "bytes"
        
    case .str:
        return "str"
    
    case .json, .jsondata, .object:
        return "object"
    
    case .void:
        return "None"
    case .bool, .tuple, .list, .None, .other:
        return type.rawValue
    }
}







func convertPythonListType_(type: PythonType, options: [PythonTypeConvertOptions]) -> String {
    if options.contains(.objc) {
//        return "PythonList_\(SWIFT_TYPES[type]!) _Nonnull"
        return "PythonList_\(SWIFT_TYPES[type.rawValue]!)"
    }
    
    return "PythonList_\(SWIFT_TYPES[type.rawValue]!)"
}




//if list {return "\(name)_array, \(name)_size"}
//if list {return "\(name)_array"}






extension String.StringInterpolation {
    mutating func appendInterpolation(if condition: @autoclosure () -> Bool, _ literal: StringLiteralType) {
        guard condition() else { return }
        appendLiteral(literal)
    }
    
    mutating func appendInterpolation(if condition: @autoclosure () -> Bool) {
        guard condition() else { return }
        appendLiteral("")
    }
    
    mutating func appendInterpolation(if condition: @autoclosure () -> Bool, _ literal: StringLiteralType,_ else_literal: StringLiteralType) {
        if condition() { appendLiteral(literal) } else { appendLiteral(else_literal) }
    }
}
