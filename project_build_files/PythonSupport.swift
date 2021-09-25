
import Foundation


extension UnsafePointer where Pointee == UInt8 {
    func asArray(count: Int) -> [UInt8] {
        return Array(UnsafeBufferPointer(start: self, count: count))
        
    }
    func asData(count: Int) -> Data {
        return Data(UnsafeBufferPointer(start: self, count: count))
    }
}

func pointer2array<T>(data: UnsafePointer<T>,count: Int) -> [T] {
    let buffer = UnsafeBufferPointer(start: data, count: count);
    return Array<T>(buffer)
}

extension Data {
    var bytes_array : [UInt8] {
        return [UInt8](self)
    }
    
    var bytes : UnsafePointer<UInt8> {
        self.withUnsafeBytes { (unsafeBytes) in
            let bytes = unsafeBytes.bindMemory(to: UInt8.self).baseAddress!
            return bytes
        }
    }
}






//Python/C Types

extension PythonString {
    func asString() -> String {
        return String(cString: self )
    }
}

extension PythonBytes {

}


extension PythonData {
    func asData(python_data length: Int) -> Data {
        return Data(UnsafeBufferPointer(start: self, count: length))
    }
}



extension PythonJsonData {
    func asDictionary(count: Int, options: JSONSerialization.ReadingOptions = []) -> [String:Any]! {
        let data = self.asData(count: count)
        do {
            let dict = try JSONSerialization.jsonObject(with: data, options: options) as? [String:Any]
            return dict
        } catch let error as NSError {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func asArray(count: Int, options: JSONSerialization.ReadingOptions = []) -> [Any]! {
        let data = self.asData(count: count)
        do {
            let array = try JSONSerialization.jsonObject(with: data, options: options) as? [Any]
            return array
        } catch let error as NSError{
            print(error.localizedDescription)
            return nil
        }
    }
}


func pythonJSONBytes(object: Any) -> UnsafePointer<UInt8>? {
    do {
        let bytes = try JSONSerialization.data(withJSONObject: object, options: .fragmentsAllowed).bytes
        return bytes
    } catch {
        print(error.localizedDescription)
    }
    return nil
}
