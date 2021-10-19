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
    
    //toolchain(command: "build", args: ["python"])
    //toolchain(command: "build", args: ["kivy"])
    print("Done")

}


func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}



func BuildWrapperFile(root_path: String, site_path: String, py_name: String) {
    
    
    let py_ast = PythonASTconverter(filename: py_name, site_path: site_path)
    let wrap_module = py_ast.generateModule()
    let export_dir = getDocumentsDirectory().appendingPathComponent("ksl_exports")
    let pyxfile = export_dir.appendingPathComponent("\(py_name).pyx")
    let h_file = export_dir.appendingPathComponent("_\(py_name).h")
    let m_file = export_dir.appendingPathComponent("_\(py_name).m")
    
    do {
        try wrap_module.pyx.write(to: pyxfile, atomically: true, encoding: .utf8)
        try wrap_module.h.write(to: h_file, atomically: true, encoding: .utf8)
        try wrap_module.m.write(to: m_file, atomically: true, encoding: .utf8)
    } catch {
        // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        print(error.localizedDescription)
    }

    //toolchain(command: "clean", args: [py_name, "wrapper_builds/\(py_name)/"])
    //toolchain(command: "build", args: [py_name])
}



func resourceURL(to path: String) -> URL? {
    return URL(string: path, relativeTo: Bundle.main.resourceURL)
}

class PythonASTconverter {
    
    let filename: String
    
    let WrapClass: PythonObject
    let pbuilder: PythonObject
    
    init(filename: String, site_path: String) {
        self.filename = filename
        let sys = Python.import("sys")
        
        sys.path.append(site_path)
        //sys.path.append(py_path!)
        //sys.path.append(site_path + "KivySwiftLink")
        pbuilder = Python.import("pythoncall_builder")
        WrapClass = pbuilder.WrapClass2
    }
    
    func generateModule() -> WrapModule {
        let cur_dir = FileManager().currentDirectoryPath
        let wrap_file = try! String.init(contentsOfFile: cur_dir + "/wrapper_sources/" + filename + ".py")
        //let module = ast.parse(wrap_file)
        let wrap_module_string = WrapClass.json_export(filename ,wrap_file)
        let data = String(wrap_module_string)?.data(using: .utf8)
        let decoder = JSONDecoder()
        let wrap_module = try! decoder.decode(WrapModule.self, from: data!)
        return wrap_module
    }
    
    
    
    
}
