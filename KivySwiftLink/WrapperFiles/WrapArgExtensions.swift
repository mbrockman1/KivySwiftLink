
import Foundation

var convertPythonListType_count = 0

extension WrapArg {
    
    func convertPythonType( options: [PythonTypeConvertOptions]) -> String {
        let list = has_option(.list)
        let array = has_option(.array)
        if options.contains(.protocols) {
//            if options.contains(.is_list) {
            if list || array {
                return "[\(pyType2Swift)]"
            }
            return pyType2Swift
        }
        if list {
            return convertPythonListType(options: options)
        }
        if self.options.contains(.array) {
            return "\(arrayPtrType())"
        }
        return pythonType2pyx(options: options)
    }

    func convertPythonListType(options: [PythonTypeConvertOptions]) -> String {
        convertPythonListType_count += 1
        if options.contains(.objc) {
    //        return "PythonList_\(SWIFT_TYPES[type]!) _Nonnull"
            return "PythonList_\(SWIFT_TYPES[type.rawValue]!)"
        }
        if options.contains(.protocols) {
            return "[\(pyType2Swift)]"
        }
        if has_option(.codable) {
            return "[\(pyType2Swift)]"
        }
        return "PythonList_\(pyType2Swift)"
    }
    
    
    var convertPythonCallArg: String {
        //let is_return = arg.is_return
        let is_list_data = has_option(.list)
        let name = objc_name
        //let size_arg_name = "arg\(arg.idx + 1)"
        let size_arg_name = "arg\(idx).size"
        
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
            return convertOtherCallArg
        default:
            if is_list_data {return "[\(name).ptr[x].decode('utf8') for x in range(\(size_arg_name))]"}
            return name
        }
    }

    var convertOtherCallArg: String{
        if has_option(.enum_) {
            if let cls = cls {
                return "\(cls.title)_events[\(objc_name)]"
            }
            return objc_name
        }
        return objc_name
    }
   
    
    
    var swiftCallArgs: String {
        let list = has_option(.list)
        let codable = has_option(.codable)
        switch type {
        case .str:
            return "String(cString: \(name))"
        case .jsondata, .data:
            return "\(name).data"
        case .other:
            if codable {
                return other_type.titleCase()
            }
            return name
        default:
            if list {
                return "pointer2array(data: \(name).ptr, count: \(name).size)"
            }
            return name
        }
    }

    var swiftCallbackArgs: String {
        //let list = has_option(.list)
        let codable = has_option(.codable)
        switch type {
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

    var pyType2Swift: String {
        switch type {
        case .str:
            return "String"
        case .bytes:
            return "[Int8]"
        case .data, .jsondata:
            return "Data"
        case .other:
            return other_type
        default:
            if let value = SWIFT_TYPES[type.rawValue] {
                return value
            } else {
                print(type.rawValue,"missing")
                fatalError()
            }
            
        }
        
    }
    
    func arrayPtrType() -> String {
        var output = ""
        switch type {
        case .int8, .char:
            output = "char"
        case .uint8, .uchar:
            output = "uchar"
        case .int16, .short:
            output = "short"
        case .uint16, .ushort:
            output = "ushort"
        case .int32:
            output = "int"
        case .uint32:
            output = "uint"
        case .long, .int:
            output = "long"
        case .ulong, .uint:
            output = "ulong"
        default:
            output = type.rawValue
        }
        return output
    }
    
    func pythonType2pyx(options: [PythonTypeConvertOptions]) -> String {
        var objc = false
        var c_types = false
        if options.contains(.objc) {objc = true}
        if options.contains(.c_type) {c_types = true}
        if options.contains(.swift) {
            if let value = SWIFT_TYPES[type.rawValue] {
                return value
            }
            return other_type
        }
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
    
    func export_tuple(options: [PythonTypeConvertOptions]) -> String {
        let py_mode = options.contains(.py_mode)
        //let objc_mode = options.contains(.objc)
        //let c_mode = options.contains(.c_type)
        
        if has_option(.tuple) == true {
            if py_mode {
                return "tuple[\(tuple_types!.map{PurePythonTypeConverter(type: $0.type)})]"
            }
        }
        return "TUPLE_ERROR_TYPE"
    }
    
    
    func convertPythonSendArg(options: [PythonSendArgTypes]) -> String {
        let list = has_option(.list)
        let array = has_option(.array)
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
            return "json.dumps(\(name)).encode()"
        case .jsondata:
            return "j_\(name)"
        case .object:
            if list {return "\(name)_struct"}
            return "<PythonObject>\(name)"
        default:
            if list {return "\(name)_struct"}
            if array {return "\(name).data.as_\(arrayPtrType())s"}
            return name
        }
    }
    
    
    var strlistFunctionLine: String {
        let arg_type = convertPythonType(options: [])
        let decode = ""
        return """
                \(name)_bytes = [x.encode() for x in \(name)]
                cdef int \(name)_size = len(\(name))
                cdef \(arg_type)*\(name)_array = <\(arg_type) *> malloc(\(name)_size  * \(size))
                cdef int \(name)_i
                for \(name)_i in range(\(name)_size):
                    \(name)_array[\(name)_i] = \(decode)\(name)_bytes[\(name)_i]
        """}
    
    var dataFunctionLine: String {
        let arg = name
        let arg_type = convertPythonType(options: [])
        let type_size = size
        let decode = ""
        return """
                cdef int \(arg)_size = len(\(arg))
                cdef \(arg_type)* \(arg)_array = <\(arg_type)*> malloc(\(arg)_size  * \(type_size))
                cdef int \(arg)_i
                for \(arg)_i in range(\(arg)_size):
                    \(arg)_array[\(arg)_i] = \(decode)\(arg)[\(arg)_i]
        """
    }
    
    var listFunctionLine: String {
        let arg_type = convertPythonType(options: [])
        let malloc_type = pythonType2pyx(options: [.c_type])
        //if let size = wrap_arg.size {} else {print(wrap_arg.type)}
        let decode = "\(if: (type == .object) , "<PythonObject>")"
        return """
                cdef int \(name)_size = len(\(name))
                cdef \(malloc_type)* \(name)_array = <\(malloc_type)*> malloc(\(name)_size  * \(size))
                cdef int \(name)_i
                for \(name)_i in range(\(name)_size):
                    \(name)_array[\(name)_i] = \(decode)\(name)[\(name)_i]
                cdef \(pyx_type) \(name)_struct = [\(name)_array, \(name)_size]
        """
    }
}
