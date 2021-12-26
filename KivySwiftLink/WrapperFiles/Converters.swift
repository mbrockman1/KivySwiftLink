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

enum PythonType: String, CaseIterable,Codable {
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
    case tuple
    case object
    case bool
    case void
    case None
    case other
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
    //"const void*":"PythonObject",
    //"const unsigned char*":"PythonData",
    //"const unsigned char*":"PythonJsonData",
    //"const char*":"PythonBytes",
    //"const char*":"PythonString"
//]

func get_typedef_types() -> [String: String]  {
    var types = TYPEDEF_BASETYPES
    
    for type in PythonType.allCases {
        switch type {
        case .list, .void:
            continue
        default:
            //types.append((type.rawValue,convertPythonListType(type: type.rawValue)))
            types[type.rawValue] = convertPythonListType(type: type, options: [.c_type])
        }
        
    }
    
    
    return types
}

enum PythonTypeConvertOptions {
    case objc
    case header
    case c_type
    case swift
    case is_list
    case py_mode
    case use_names
    case dispatch
    case protocols
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

func export_tuple(arg: WrapArg, options: [PythonTypeConvertOptions]) -> String {
    let py_mode = options.contains(.py_mode)
    //let objc_mode = options.contains(.objc)
    //let c_mode = options.contains(.c_type)
    
    if arg.has_option(.tuple) == true {
        if py_mode {
            return "tuple[\(arg.tuple_types!.map{PurePythonTypeConverter(type: $0.type)})]"
        }
    }
    return "TUPLE_ERROR_TYPE"
}

func pythonType2pyx(type: PythonType, options: [PythonTypeConvertOptions]) -> String {
    var objc = false
    var c_types = false
    if options.contains(.objc) {objc = true}
    if options.contains(.c_type) {c_types = true}
    if options.contains(.swift) {return SWIFT_TYPES[type.rawValue]!}
    var export: String
    var nonnull = false
    switch type {
    
    case .bool:
        if objc {
            export = "bool"
        } else {
            export = "bint"
        }
    
    case .long, .int:
        export = "long"
        
    case .ulong, .uint:
        export = "unsigned long"
    
    case .longlong:
        export = "longlong"
    case .ulonglong:
        export = "unsigned longlong"
    case .int32:
        if objc {
            export = "int"
        } else {
            export = "int"
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
        if c_types {
            export = "const void*"
        } else {
            export = "PythonObject"
        }
        
        nonnull = true
    case .str:
        if c_types {
            export = "const char*"
        } else {
            export = "PythonString"
        }
        nonnull = true
    case .bytes:
        if c_types {
            export = "const char*"
        } else {
            export = "PythonBytes"
        }
        nonnull = true
        
    //special types
    case .data:
        if c_types {
            export = "const unsigned char*"
        } else {
            export = "PythonData"
        }
        //nonnull = true
    case .json:
        if c_types {
            export = "const char*"
        } else {
            export = "PythonJsonString"
        }
        nonnull = true
    case .jsondata:
        if c_types {
            export = "const unsigned char*"
        } else {
            export = "PythonJsonData"
        }
        //nonnull = true
    case .void:
        export = "void"
    case .tuple:
        export = "tuple"
    case .None:
        export = type.rawValue
    case .other:
        export = type.rawValue
    default:
        if type.rawValue.contains("SwiftFuncs") {
            return type.rawValue
        }
        print("<\(type)> is not a supported type or is not defined")
        print("""
            use "TypeVar" to define new types - the wrapper_file's global space

            more info about it here:
                https://docs.python.org/3/library/typing.html

            """)
        exit(1)
    }
    if objc {
        if options.contains(.header) {
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

func pyType2Swift(type: PythonType) -> String {
    switch type {
    case .str:
        return "String"
    case .bytes:
        return "[Int8]"
    case .data, .jsondata:
        return "Data"
    default:
        return SWIFT_TYPES[type.rawValue]!
        
    }
    
}

func swiftCallArgs(arg: WrapArg) -> String {
    let name = arg.name
    let list = arg.has_option(.list)
    switch arg.type {
    case .str:
        return "String(cString: \(name))"
    case .jsondata, .data:
        return "\(name).data"
    default:
        if list {
            return "pointer2array(data: \(name).ptr, count: \(name).size)"
        }
        return name
    }
}

func swiftCallbackArgs(arg: WrapArg) -> String {
    let name = arg.name
    let list = arg.has_option(.list)
    
    switch arg.type {
    case .str:
        return "\(name).pythonString"
    case .data:
        return "\(name).pythonData"
    case .jsondata:
        return "\(name).pythonJsonData"
    default:
        return name
    }
}

func convertPythonType(type: PythonType, options: [PythonTypeConvertOptions]) -> String {
    if options.contains(.protocols) {
        if options.contains(.is_list) {
            return "[\(pyType2Swift(type: type))]"
        }
        return pyType2Swift(type: type)
    }
    if options.contains(.is_list) {
        return convertPythonListType(type: type, options: options)
    }
    
    return pythonType2pyx(type: type, options: options)
}

func convertPythonListType(type: PythonType, options: [PythonTypeConvertOptions]) -> String {
    if options.contains(.objc) {
//        return "PythonList_\(SWIFT_TYPES[type]!) _Nonnull"
        return "PythonList_\(SWIFT_TYPES[type.rawValue]!)"
    }
    if options.contains(.protocols) {
        return "[\(pyType2Swift(type: type))]"
    }
    return "PythonList_\(SWIFT_TYPES[type.rawValue]!)"
}


func convertPythonCallArg(arg: WrapArg) -> String {
    //let is_return = arg.is_return
    let type = arg.type
    let is_list_data = arg.has_option(.list)
    let name = arg.objc_name
    //let size_arg_name = "arg\(arg.idx + 1)"
    let size_arg_name = "arg\(arg.idx).size"
    
    switch type {
    case .str:
        if is_list_data {return "[\(name).ptr[x].decode('utf8') for x in range(\(size_arg_name))]"}
        return "\(name).decode('utf-8')"
    case .data:
        if is_list_data {return "\(name).ptr[:\(size_arg_name)]"}
        //return "<bytes>\(name)[0:\(name)_size]"
        return "\(name).ptr[:\(size_arg_name)]"
    case .json:
        return "json.loads(\(name))"
    case .jsondata:
        return "json.loads(\(name).ptr[:\(size_arg_name)])"
    case .object:
        if is_list_data {return "[<object>\(name).ptr[x] for x in range(\(size_arg_name))]"}
        return "<object>\(name)"
    case .other:
        return convertOtherCallArg(arg: arg)
    default:
        if is_list_data {return "[\(name).ptr[x].decode('utf8') for x in range(\(size_arg_name))]"}
        return name
    }
}

func convertOtherCallArg(arg: WrapArg) -> String{
    if arg.has_option(.enum_) {
        if let cls = arg.cls {
            return "\(cls.title)_events[<int>\(arg.objc_name)]"
        }
        return arg.objc_name
    }
    return arg.objc_name
}

func convertReturnSend(f: WrapFunction, rname: String, code: String) -> String {
    let returns = f.returns
    let rtype = f.returns.type
    
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

enum PythonSendArgTypes {
    case list
    case data
}
//if list {return "\(name)_array, \(name)_size"}
//if list {return "\(name)_array"}
func convertPythonSendArg(type: PythonType, name: String, options: [PythonSendArgTypes]) -> String {
    let list = options.contains(.list)
    switch type {
    case .str:
        if list {return "\(name)_struct"}
        return "\(name).encode()"
    case .data:
        if list {return "\(name)_struct"}
        //return "<bytes>\(name)[0:\(name)_size]"
        return name
        //return "\(name), \(name)_size"
    case .json:
        return "json.dumps(\(name)).encode('utf-8')"
    case .jsondata:
        return "j_\(name)"
    case .object:
        if list {return "\(name)_struct"}
        return "<PythonObject>\(name)"
    default:
        if list {return "\(name)_struct"}
        return name
    }
}





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
