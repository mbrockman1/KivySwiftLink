//
//  CLI_Functions.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 18/10/2021.
//

import Foundation

import AppKit

enum PyTypes: PythonObject {
    case str
}

import PythonKit








enum ToolchainCommands: String {
    case create
    case xcode
    case clean
    case build
    case update
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

func _toolchain(path: String, command: ToolchainCommands, args: [String]) {
    toolchain_venv(path: path, command: command.rawValue, args: args)
}






@discardableResult
func pkg_install(path: String) -> Int32 {

    let task = Process()
    task.launchPath = "/usr/sbin/installer"
    task.arguments = ["-pkg","-file", path]
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
    
}

@discardableResult
func toolchain_venv(path: String, command: String, args: [String]) -> Int32 {
    //print("toolchain_venv running")
    //var targs: [String] = ["-c","source venv/bin/activate", "&&", "python --version"]
    let targs = ["-c", """
    source \(path)/venv/bin/activate
    toolchain \(command) \(args.joined(separator: " "))
    """]
    //targs.append(contentsOf: args)
    let task = Process()
    task.launchPath = "/bin/zsh"
    task.arguments = targs
    //task.standardOutput = nil
    //task.terminationHandler = terminationHandler
    
//    let outputPipe = Pipe()
//    //task.standardOutput = outputPipe
//    //task.standardError = outputPipe
//    let outputHandle = outputPipe.fileHandleForReading
//    outputHandle.waitForDataInBackgroundAndNotify()
//    var start_write = false
//    var output = ""
//    let debug = false
    
//    outputHandle.readabilityHandler = { pipe in
//        var currentInfo = ""
//        guard let _currentInfo = String(data: pipe.availableData[...7], encoding: .utf8) else {return}
//        currentInfo = _currentInfo
//        guard let currentOutput = String(data: pipe.availableData, encoding: .utf8) else {
//            print("Error decoding data: \(pipe.availableData)")
//            return
//        }
//        print(currentInfo)
//        if currentOutput.contains("Error compiling Cython file:" ) {
//            print(currentOutput)
//            start_write = true
//        }
//
//
//        if currentOutput.contains("  STDERR:") {return}
//        guard !currentOutput.isEmpty else {
//            return
//        }
//
//        if start_write {output = output + currentOutput}
//
//
//            if debug {
//                DispatchQueue.main.async {
//                    print(currentOutput)
//                }
//            }
//    }
    //let pipe = Pipe()
    //task.standardOutput = pipe
    //print(pipe.fileHandleForReading)
    task.launch()
    task.waitUntilExit()
    //print(output)
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
    if !checkPythonVersion() {
        downloadPython()
        return
    }
    
    //try! Process().clone(repo: "https://github.com/psychowasp/KivySwiftLink.git", path: "KivySwiftLinkPack")
    try! Process().clone(repo: "https://github.com/psychowasp/KivySwiftSupportFiles.git", path: "KivySwiftSupportFiles")
    //try! Process().clone(repo: "https://github.com/meow464/kivy-ios.git", path: "kivy-ios-modded")
    
    create_venv()
    //pip_install(arg: "git+\(toolchain_py_url)")
    //https://github.com/kivy/kivy-ios
    //https://github.com/meow464/kivy-ios.git@custom_recipes
    //return
    for pip in ["wheel","cython", "kivy","git+https://github.com/garrik/mod-pbxproj@develop" ,"git+https://github.com/kivy/kivy-ios.git", "astor"] {
        pip_install(arg: pip)
    }
    //copyItem(from: "KivySwiftSupportFiles/toolchain.py", to: "venv/lib/python3.9/site-packages/kivy_ios/toolchain.py", force: true)
    
    copyItem(from: "KivySwiftSupportFiles/swift_types.py", to: "venv/lib/python3.9/site-packages/swift_types.py")

    copyItem(from: "KivySwiftSupportFiles/project_support_files", to: "project_support_files")
    copyItem(from: "KivySwiftSupportFiles/pythoncall_builder.py", to: "venv/lib/python3.9/site-packages/pythoncall_builder.py")
    createFolder(name: "wrapper_sources")
    createFolder(name: "wrapper_builds")
    createFolder(name: "wrapper_headers")
    copyItem(from: "KivySwiftSupportFiles/project_support_files/wrapper_typedefs.h", to: "wrapper_headers/wrapper_typedefs.h")
    copyItem(from: "KivySwiftSupportFiles/swift_types.py", to: "venv/lib/python3.9/site-packages/swift_types.py")
    let fileman = FileManager()
    do {
        //try fileman.removeItem(atPath: "KivySwiftLink")
        try fileman.removeItem(atPath: "KivySwiftSupportFiles")
    } catch {
        print("cant delete folders")
    }
    _toolchain(path: root_path, command: .build, args: ["python3==3.9.2", "kivy"])
    //toolchain(command: "build", args: ["kivy"])
    print("Setup done")

}

func UpdateWorkingFolder() {
    let fm = FileManager()
    try! Process().clone(repo: "https://github.com/psychowasp/KivySwiftSupportFiles.git", path: "KivySwiftSupportFiles")
    
    copyItem(from: "KivySwiftSupportFiles/swift_types.py", to: "venv/lib/python3.9/site-packages/swift_types.py",force: true)
    
    copyItem(from: "KivySwiftSupportFiles/project_support_files", to: "project_support_files",force: true)
    copyItem(from: "KivySwiftSupportFiles/pythoncall_builder.py", to: "venv/lib/python3.9/site-packages/pythoncall_builder.py", force: true)
    
    copyItem(from: "KivySwiftSupportFiles/project_support_files/wrapper_typedefs.h", to: "wrapper_headers/wrapper_typedefs.h", force: true)
    copyItem(from: "KivySwiftSupportFiles/swift_types.py", to: "venv/lib/python3.9/site-packages/swift_types.py", force: true)
    do {
        try fm.removeItem(atPath: "KivySwiftSupportFiles")
    } catch {
        print("cant delete folders")
    }
}






func update_project(files: [String]) {
    let p_dict = get_project()!
    let project = ProjectManager(title: p_dict["project_name"] as! String, site_path: site_path)
    project.update_frameworks_lib_a()
    project.update_bridging_header(keys: files)
    
}


func get_project() -> [String:Any]! {
    if let project_dict = JsonStorage().current_project() {
        //let project = ProjectManager(title: project_name, site_path: site_path)
        //exit(1)
        return project_dict
    }
    
    //exit(1)
    return nil
}
func resourceURL(to path: String) -> URL? {
    return URL(string: path, relativeTo: Bundle.main.resourceURL)
}

func buildWrapper(name: String) {
    //if JsonStorage().current_project() != nil {
    if ProjectHandler(db_path: nil).current_project != nil {
        print("building \(name).pyi")
        let file_man = FileManager()
        let file_url = URL(fileURLWithPath: file_man.currentDirectoryPath).appendingPathComponent("wrapper_sources").appendingPathComponent("\(name).pyi")
        guard file_man.fileExists(atPath: file_url.path) else {
            print("\(file_url.path) dont exist")
            return
        }
        BuildWrapperFile(root_path: root_path, site_path: site_path, py_name: name)
        update_project(files: [name])
        print("Done")
    } else {
        print("No Project Selected - use 'ksl project select <project name (no -ios)>'")
    }
}

func buildAllWrappers() {
    if JsonStorage().current_project() != nil {
        let file_man = FileManager()
        let wrapper_sources = URL(fileURLWithPath: file_man.currentDirectoryPath).appendingPathComponent("wrapper_sources")
        print("building all")
        let files = try! file_man.contentsOfDirectory(atPath: wrapper_sources.path).map{$0.fileName()}
        for file in files {
            print(file)
            BuildWrapperFile(root_path: root_path, site_path: site_path, py_name: file )
        }
        if files.count != 0 {
            update_project(files: files)
        }
    }
}

func updateWrappers(path: String! = nil) {
    let file_man = FileManager()
    var wrapper_sources: URL
    var lib_sources: URL
    var rpath: String
    var spath: String
    
    
    if let p = path {
        print("p = path")
        wrapper_sources = URL(fileURLWithPath: p).appendingPathComponent("wrapper_sources")
        lib_sources = URL(fileURLWithPath: p).appendingPathComponent("dist/lib")
        rpath = p
        spath = URL(fileURLWithPath: p).appendingPathComponent("/venv/lib/python3.9/site-packages").path
    } else {
        wrapper_sources = URL(fileURLWithPath: file_man.currentDirectoryPath).appendingPathComponent("wrapper_sources")
        lib_sources = URL(fileURLWithPath: file_man.currentDirectoryPath).appendingPathComponent("dist/lib")
        rpath = root_path
        spath = site_path
    }
    
    let wrapper_files = try! file_man.contentsOfDirectory(at: wrapper_sources, includingPropertiesForKeys: [], options: .skipsHiddenFiles)
    let lib_files = try! file_man.contentsOfDirectory(at: lib_sources, includingPropertiesForKeys: [], options: .skipsHiddenFiles)
    //print(wrapper_files)
    
    for file in wrapper_files {
        print(file)
        let file_date = fileModificationDate(url: file)!
        let filename = file.path.fileName()
        let lib_file = lib_sources.appendingPathComponent("lib\(file.path.fileName()).a")
        if file_man.fileExists(atPath: lib_file.path) {
            let lib_file_date = fileModificationDate(url: lib_file)!
            if lib_file_date < file_date {
                print(filename, file_date, lib_file_date)
                BuildWrapperFile(root_path: rpath, site_path: spath, py_name: filename )
            }
        }
        
    }
}
