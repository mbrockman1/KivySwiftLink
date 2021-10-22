//
//  CLI_Functions.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 18/10/2021.
//

import Foundation


import PythonKit

extension Process {

    private static let gitExecURL = URL(fileURLWithPath: "/usr/bin/git")

    public func clone(repo: String, path: String) throws {
        executableURL = Process.gitExecURL
        arguments = ["clone", repo, path]
        try run()
        self.waitUntilExit()
    }

}

func createFolder(name: String) {
    do {
        try FileManager().createDirectory(atPath: name, withIntermediateDirectories: false, attributes: [:])
    } catch let error {
        print(error.localizedDescription)
    }
}


func copyItem(from: String, to: String) {
    let fileman = FileManager()
    if fileman.fileExists(atPath: to) {
        print("file already exist do you wish to overwrite it ?")
        if let input_string = readLine() {
            let input = input_string.trimmingCharacters(in: .whitespaces)
            if input == "y" {
                do {
                    try fileman.removeItem(atPath: to)
                    try fileman.copyItem(atPath: from, toPath: to)
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }
    } else {
        do {
            try fileman.copyItem(atPath: from, toPath: to)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
}


@discardableResult
func toolchain(command: String, args: [String]) -> Int32 {
    var targs: [String] = [command]
    targs.append(contentsOf: args)
    let task = Process()
    task.launchPath = "venv/bin/toolchain"
    task.arguments = targs
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

@discardableResult
func toolchain_venv(command: String, args: [String]) -> Int32 {
    print("toolchain_venv running")
    //var targs: [String] = ["-c","source venv/bin/activate", "&&", "python --version"]
    let targs = ["-c", """
    source venv/bin/activate
    toolchain \(command) \(args.joined(separator: " "))
    """]
    //targs.append(contentsOf: args)
    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = targs
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

@discardableResult
func pip_install(arg: String) -> Int32 {
    let task = Process()
    task.launchPath = "venv/bin/pip"
    task.arguments = ["install",arg]
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

@discardableResult
func create_venv() -> Int32 {
    let task = Process()
    task.launchPath = "/usr/local/bin/python3"
    task.arguments = ["-m","venv", "venv"]
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}


func InitWorkingFolder() {
    
    try! Process().clone(repo: "https://github.com/psychowasp/KivySwiftLink.git", path: "KivySwiftLink")
    try! Process().clone(repo: "https://github.com/psychowasp/KivySwiftSupportFiles.git", path: "KivySwiftSupportFiles")
    create_venv()
    for pip in ["cython", "kivy", "git+https://github.com/meow464/kivy-ios.git@custom_recipes", "astor"] {
        pip_install(arg: pip)
    }
    
    copyItem(from: "KivySwiftLink/src/swift_types.py", to: "venv/lib/python3.9/site-packages/swift_types.py")

    copyItem(from: "KivySwiftSupportFiles/project_support_files", to: "project_support_files")
    copyItem(from: "KivySwiftSupportFiles/pythoncall_builder.py", to: "venv/lib/python3.9/site-packages/pythoncall_builder.py")
    createFolder(name: "wrapper_sources")
    createFolder(name: "wrapper_builds")
    createFolder(name: "wrapper_headers")
    let fileman = FileManager()
    do {
        try fileman.removeItem(atPath: "KivySwiftLink")
        try fileman.removeItem(atPath: "KivySwiftSupportFiles")
    } catch {
        print("cant delete folders")
    }
    toolchain(command: "build", args: ["python"])
    toolchain(command: "build", args: ["kivy"])
    print("Done")

}


func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}



func BuildWrapperFile(root_path: String, site_path: String, py_name: String) {
    let file_man = FileManager()
    let cur_dir = URL(fileURLWithPath: file_man.currentDirectoryPath)
    let py_file = cur_dir.appendingPathComponent("wrapper_sources").appendingPathComponent("\(py_name).py")
    if !file_man.fileExists(atPath: py_file.path) {
        print("no wrapper file named: \(py_name).py")
        return
    }
    let wrapper_builds_path = cur_dir.appendingPathComponent("wrapper_builds", isDirectory: true)
    let recipe_dir = wrapper_builds_path.appendingPathComponent(py_name, isDirectory: true)
    let src_path = recipe_dir.appendingPathComponent("src", isDirectory: true)
    if !file_man.fileExists(atPath: src_path.path){
        try! file_man.createDirectory(atPath: src_path.path, withIntermediateDirectories: true, attributes: [:])
    }
    print(src_path)
    let py_ast = PythonASTconverter(filename: py_name, site_path: site_path)
    let wrap_module = py_ast.generateModule()
    //let export_dir = getDocumentsDirectory().appendingPathComponent("ksl_exports")
    let pyxfile = src_path.appendingPathComponent("\(py_name).pyx")
    let h_file = src_path.appendingPathComponent("_\(py_name).h")
    let m_file = src_path.appendingPathComponent("_\(py_name).m")
    let setup_file = src_path.appendingPathComponent("setup.py")
    let recipe_file = recipe_dir.appendingPathComponent("__init__.py")
    print(pyxfile)
    do {
        try wrap_module.pyx.write(to: pyxfile, atomically: true, encoding: .utf8)
        try wrap_module.h.write(to: h_file, atomically: true, encoding: .utf8)
        try wrap_module.m.write(to: m_file, atomically: true, encoding: .utf8)
        try createSetupPy(title: py_name).write(to: setup_file, atomically: true, encoding: .utf8)
        try createRecipe(title: py_name).write(to: recipe_file, atomically: true, encoding: .utf8)
    } catch {
        // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        print(error.localizedDescription)
    }
    let wrapper_typedefs = cur_dir.appendingPathComponent("project_support_files/wrapper_typedefs.h")
    let typedefs_dst = src_path.appendingPathComponent("wrapper_typedefs.h")
    if !file_man.fileExists(atPath: typedefs_dst.path){
        copyItem(from: wrapper_typedefs.path, to: typedefs_dst.path)
    }
    

    toolchain(command: "clean", args: [py_name, "wrapper_builds/\(py_name)/"])
    toolchain_venv(command: "build", args: [py_name, "--add-custom-recipe" ,recipe_dir.path])
}



func resourceURL(to path: String) -> URL? {
    return URL(string: path, relativeTo: Bundle.main.resourceURL)
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
        let wrap_file = try! String.init(contentsOfFile: cur_dir + "/wrapper_sources/" + filename + ".py")
        //let module = ast.parse(wrap_file)
        let wrap_module_string = pyWrapClass.json_export(filename ,wrap_file)
        let data = String(wrap_module_string)?.data(using: .utf8)
        let decoder = JSONDecoder()
        let wrap_module = try! decoder.decode(WrapModule.self, from: data!)
        return wrap_module
    }
    
    
    
    
}
