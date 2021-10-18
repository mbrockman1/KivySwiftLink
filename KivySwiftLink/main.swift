//
//  main.swift
//  KivySwiftLink2
//
//  Created by MusicMaker on 14/10/2021.
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
    
    do {
        try FileManager().copyItem(atPath: from, toPath: to)
    } catch let error {
        print(error.localizedDescription)
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
    
    create_venv()
    for pip in ["cython", "kivy", "git+https://github.com/meow464/kivy-ios.git@custom_recipes", "astor"] {
        pip_install(arg: pip)
    }
    
    copyItem(from: "KivySwiftLink/src/swift_types.py", to: "venv/lib/python3.9/site-packages/swift_types.py")

    copyItem(from: "KivySwiftLink/project_support_files", to: "project_support_files")

    createFolder(name: "wrapper_sources")
    createFolder(name: "wrapper_builds")
    createFolder(name: "wrapper_headers")
    
    toolchain(command: "build", args: ["python"])
    toolchain(command: "build", args: ["kivy"])
    print("Done")

}


func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}



func BuildWrapperFile(root_path: String, site_path: String, py_name: String) {
    
    let sys = Python.import("sys")
    sys.path.append(site_path)
    sys.path.append(site_path + "KivySwiftLink")
    
    let file = Python.import("pythoncall_builder")
    let wrap_class = file.WrapClass2
    
    let wrap_file = try! String.init(contentsOfFile: root_path + "wrapper_sources/" + py_name + ".py")
    let wrap_module_string = wrap_class.json_export(wrap_file)
    let data = String(wrap_module_string)?.data(using: .utf8)
    
    let decoder = JSONDecoder()
    let wrap_module = try! decoder.decode(WrapModule.self, from: data!)
    let export_dir = getDocumentsDirectory().appendingPathComponent("ksl_exports")
    let pyxfile = export_dir.appendingPathComponent("\(py_name).pyx")
    let h_file = export_dir.appendingPathComponent("_\(py_name).h")
    //wrap_module.build()
    do {
        try wrap_module.pyx.write(to: pyxfile, atomically: true, encoding: .utf8)
        try wrap_module.h.write(to: h_file, atomically: true, encoding: .utf8)
    } catch {
        // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        print(error.localizedDescription)
    }
    toolchain(command: "clean", args: [py_name, "wrapper_builds/\(py_name)/"])
    //toolchain(command: "build", args: [py_name])
}

//PythonLibrary.useLibrary(at: root_path + "venv/bin/python")
//RunPythonScript()



let py_file = "python_coremidi.py"
let root_path = "/Volumes/WorkSSD/touchbay_client_py39/"
let site_path = root_path + "venv/lib/python3.9/site-packages/"
let app_path = root_path + "venv/lib/python3.9/site-packages/KivySwiftLink/"

import ArgumentParser

struct KivySwiftLink: ParsableCommand {
    
    static let configuration = CommandConfiguration(
            abstract: "KivySwiftLink",
        subcommands: [Init.self,SelectProject.self,Build.self,Create.self, Toolchain.self]
    )
    
}
extension KivySwiftLink {
    
    
    struct Init: ParsableCommand {
        
        
        func run() {
            print("Installing KivySwiftLink Components")
            InitWorkingFolder()
        }
    }
    
    struct Build: ParsableCommand {
        
        @Argument() var filename: String
        
        func run() {
            print("building \(filename).py")
            BuildWrapperFile(root_path: root_path, site_path: site_path, py_name: filename)
        }
    }
    struct SelectProject: ParsableCommand {
            
            @Argument() var project_name: String
            
            func run() {
                print("using \(project_name)-ios")
            }
        }
    
    struct Create: ParsableCommand {
        
        @Argument() var project_name: String
        
        func run() {
            print("creating \(project_name)-ios")
        }
    }
    
    struct Toolchain: ParsableCommand {
        
        @Argument() var command: String?
        @Argument() var arg1: String?
        @Argument() var arg2: String?
        @Argument() var arg3: String?
        @Argument() var arg4: String?

        func run() {
            if command == nil {
                toolchain(command: "--help", args: [])
                return
            }
            let args: [String] = [arg1,arg2,arg3,arg4].filter{$0 != nil}.map{$0!}
            toolchain(command: command!, args: args)
        }
    }
}


KivySwiftLink.main()
