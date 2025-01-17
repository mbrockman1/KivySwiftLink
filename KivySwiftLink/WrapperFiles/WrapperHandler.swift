//
//  WrapperHandler.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 25/10/2021.
//

import Foundation


func BuildWrapperFile(root_path: String, site_path: String, py_name: String) {
    
    
    let file_man = FileManager()
    let cur_dir = URL(fileURLWithPath: root_path)
//    let site_manager = cur_dir.appendingPathComponent("venv/lib/python3.9/site-packages", isDirectory: true)
    let site_manager = URL(fileURLWithPath: site_path)
    let py_file = cur_dir.appendingPathComponent("wrapper_sources").appendingPathComponent("\(py_name).pyi")
    if !file_man.fileExists(atPath: py_file.path) {
        print("no wrapper file named: \(py_name).pyi")
        return
    }
    let wrapper_builds_path = cur_dir.appendingPathComponent("wrapper_builds", isDirectory: true)
    let wrapper_headers_path = cur_dir.appendingPathComponent("wrapper_headers", isDirectory: true)
    let c_headers = wrapper_headers_path.appendingPathComponent("c", isDirectory: true)
    let swift_headers = wrapper_headers_path.appendingPathComponent("swift", isDirectory: true)
    let recipe_dir = wrapper_builds_path.appendingPathComponent(py_name, isDirectory: true)
    let src_path = recipe_dir.appendingPathComponent("src", isDirectory: true)
    if !file_man.fileExists(atPath: src_path.path){
        try! file_man.createDirectory(atPath: src_path.path, withIntermediateDirectories: true, attributes: [:])
    }
    let py_ast = PythonASTconverter(filename: py_name, site_path: site_path)
    let wrap_module = py_ast.generateModule(root: root_path)
    //let export_dir = getDocumentsDirectory().appendingPathComponent("ksl_exports")
    let pyxfile = src_path.appendingPathComponent("\(py_name).pyx")
    let h_file = src_path.appendingPathComponent("_\(py_name).h")
    //let m_file = src_path.appendingPathComponent("_\(py_name).m")
    let swift_file = swift_headers.appendingPathComponent("\(py_name).swift")
    let setup_file = src_path.appendingPathComponent("setup.py")
    let recipe_file = recipe_dir.appendingPathComponent("__init__.py")
    do {
        try wrap_module.pyx.write(to: pyxfile, atomically: true, encoding: .utf8)
        try wrap_module.h.write(to: h_file, atomically: true, encoding: .utf8)
        //try wrap_module.m.write(to: m_file, atomically: true, encoding: .utf8)
        try wrap_module.swift.write(to: swift_file, atomically: true, encoding: .utf8)
        try py_ast.generatePYI(code: String(contentsOf: py_file)).write(to: site_manager.appendingPathComponent("\(py_name).pyi"), atomically: true, encoding: .utf8)
        try createSetupPy(title: py_name).write(to: setup_file, atomically: true, encoding: .utf8)
        try createRecipe(title: py_name).write(to: recipe_file, atomically: true, encoding: .utf8)
    } catch {
        // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        print(error.localizedDescription)
    }
    let wrapper_typedefs = cur_dir.appendingPathComponent("project_support_files/wrapper_typedefs.h")
    let typedefs_dst = src_path.appendingPathComponent("wrapper_typedefs.h")
    let wrapper_header = c_headers.appendingPathComponent("\(wrap_module.filename).h")
    
    //if !file_man.fileExists(atPath: typedefs_dst.path){
        copyItem(from: wrapper_typedefs.path, to: typedefs_dst.path, force: true)
    //}

    _toolchain(path: root_path, command: .clean, args: [py_name, "--add-custom-recipe" ,recipe_dir.path])
    _toolchain(path: root_path, command: .build, args: [py_name, "--add-custom-recipe" ,recipe_dir.path])

    copyItem(from: h_file.path, to: wrapper_header.path, force: true)

    
}
