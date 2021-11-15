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


func show_buildins() {
    print(python_buildins)
    print(isinstance("",_: str))
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
    
    func generateModule() -> WrapModule {
        let cur_dir = FileManager().currentDirectoryPath
        let wrap_file = try! String.init(contentsOfFile: cur_dir + "/wrapper_sources/" + filename + ".py").replacingOccurrences(of: "List[", with: "list[")
        //let module = ast.parse(wrap_file)
        let wrap_module_string = pyWrapClass.json_export(filename ,wrap_file)
        let data = String(wrap_module_string)?.data(using: .utf8)
        let decoder = JSONDecoder()
        let wrap_module = try! decoder.decode(WrapModule.self, from: data!)
        return wrap_module
    }
    

}
