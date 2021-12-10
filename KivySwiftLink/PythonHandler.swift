//
//  PythonHandler.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 25/10/2021.
//

import Foundation
import PythonKit

let python_buildins = Python.builtins

let isinstance = python_buildins["isinstance"]
let str = python_buildins["str"]


let ast = Python.import("ast")
let ast_Subscript = ast.Subscript
let ast_FunctionDef = ast.FunctionDef

enum astTypes: PythonObject {
    case list
}

func pyiConversion() -> [PythonObject:PythonObject] {
    var out: [PythonObject:PythonObject] = [:]
    
    for key in PythonType.allCases {
        out[key.rawValue.pythonObject] = PurePythonTypeConverter(type: key).pythonObject
    }
    return out
}

let pyiTypes = pyiConversion()

func show_buildins() {
    print(python_buildins)
    print(isinstance("",_: str))
}

func checkPythonVersion() -> Bool {
    let fileman = FileManager()
    let python39_exist = fileman.fileExists(atPath: "/usr/local/bin/python3.9")
    //print("python3.9 found",python39_exist)
    if !python39_exist {return false}
    let sys = Python.import("sys")
    let vinfo = sys.version_info
    let version = [vinfo.major, vinfo.minor]
    //print(version,version == [3,9,2])
    return version == [3,9]
}


class PythonASTconverter {
    
    let filename: String
    
    let pyWrapClass: PythonObject
    let pbuilder: PythonObject
    
    init(filename: String, site_path: String) {
        self.filename = filename
        let sys = Python.import("sys")
        
        sys.path.append(site_path)
        //sys.path.append(py_path!)
        //sys.path.append(site_path + "KivySwiftLink")
        pbuilder = Python.import("pythoncall_builder")
        pyWrapClass = pbuilder.PyWrapClass
    }
    
    func generateModule(root: String) -> WrapModule {
        let cur_dir = root
        let wrap_file = try! String.init(contentsOfFile: cur_dir + "/wrapper_sources/" + filename + ".pyi").replacingOccurrences(of: "List[", with: "list[")
        //let module = ast.parse(wrap_file)
        let wrap_module_string = pyWrapClass.json_export(filename ,wrap_file)
        let data = String(wrap_module_string)?.data(using: .utf8)
        let decoder = JSONDecoder()
        let wrap_module = try! decoder.decode(WrapModule.self, from: data!)
        return wrap_module
    }
    
    func generatePYI(code: String) -> String {
        let pyi_parse = pbuilder.parse_helper
        let pyi_types: PythonObject = pyiTypes.pythonObject
        return String(pyi_parse(code, pyi_types))!
        
    }

}
