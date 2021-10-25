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
