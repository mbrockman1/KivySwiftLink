//
//  CLI_Functions.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 18/10/2021.
//

import Foundation



enum PyTypes: PythonObject {
    case str
}

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


func copyItem(from: String, to: String, force: Bool=false) {
    let fileman = FileManager()
    if fileman.fileExists(atPath: to) && !force{
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
            if force {
                try fileman.removeItem(atPath: to)
            }
            try fileman.copyItem(atPath: from, toPath: to)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
}

enum ToolchainCommands: String {
    case create
    case xcode
    case clean
    case build
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

func _toolchain(command: ToolchainCommands, args: [String]) {
    toolchain_venv(command: command.rawValue, args: args)
}

@discardableResult
func toolchain_venv(command: String, args: [String]) -> Int32 {
    //print("toolchain_venv running")
    //var targs: [String] = ["-c","source venv/bin/activate", "&&", "python --version"]
    let targs = ["-c", """
    source venv/bin/activate
    toolchain \(command) \(args.joined(separator: " "))
    """]
    //targs.append(contentsOf: args)
    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = targs
    task.standardOutput = nil
    //task.terminationHandler = terminationHandler
    
    let outputPipe = Pipe()
    //task.standardOutput = outputPipe
    //task.standardError = outputPipe
    let outputHandle = outputPipe.fileHandleForReading
    outputHandle.waitForDataInBackgroundAndNotify()
    var start_write = false
    var output = ""
    let debug = false
    
    outputHandle.readabilityHandler = { pipe in
        
        guard let currentOutput = String(data: pipe.availableData, encoding: .utf8) else {
            print("Error decoding data: \(pipe.availableData)")
            return
        }
        if currentOutput.contains("Error compiling Cython file:" ) {
            print(currentOutput)
            start_write = true
        }
        
        if currentOutput.contains("  STDERR:") {return}
        guard !currentOutput.isEmpty else {
            return
        }
        
        if start_write {output = output + currentOutput}
        
            
            if debug {
                DispatchQueue.main.async {
                    print(currentOutput)
                }
            }
    }
    //let pipe = Pipe()
    //task.standardOutput = pipe
    //print(pipe.fileHandleForReading)
    task.launch()
    task.waitUntilExit()
    print(output)
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
    let fileman = FileManager()
    do {
        //try fileman.removeItem(atPath: "KivySwiftLink")
        try fileman.removeItem(atPath: "KivySwiftSupportFiles")
    } catch {
        print("cant delete folders")
    }
    _toolchain(command: .build, args: ["python3", "kivy"])
    //toolchain(command: "build", args: ["kivy"])
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

    _toolchain(command: .clean, args: [py_name, "--add-custom-recipe" ,recipe_dir.path])
    _toolchain(command: .build, args: [py_name, "--add-custom-recipe" ,recipe_dir.path])
    update_project()
}

func update_project() {
    let p_dict = get_project()!
    let project = ProjectManager(title: p_dict["project_name"] as! String, site_path: site_path)
    project.update_frameworks_lib_a()
    
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
