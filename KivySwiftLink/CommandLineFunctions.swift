
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
    echo "path: \(path)"
    source \(path)/venv/bin/activate
    toolchain \(command) \(args.joined(separator: " "))
    """]
    let debug_args = ["-c", """
    #source \(path)/venv/bin/activate
    #toolchain \(command) \(args.joined(separator: " "))
    echo "path: \(path)"
    echo $PWD
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
func create_venv(python: String) -> Int32 {
    let task = Process()
    task.launchPath = python
    //task.launchPath = "/usr/local/bin/python3"
    task.arguments = ["-m","venv", "venv"]
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}


func InitWorkingFolder(python_path: String!, python_version: String!) {
    var py_path = "/usr/local/bin/python3"
    var py_version_major = "3.9"
    var py_version_full = "3.9.2"
    if let ppath = python_path {py_path = ppath}
    if let pversion = python_version {
        py_version_full = pversion
        py_version_major = python_version.split(separator: ".")[0...1].joined(separator: ".")
    }

//    if !checkPythonVersion() {
//        downloadPython()
//        return
//    }
    //return
    //try! Process().clone(repo: "https://github.com/psychowasp/KivySwiftLink.git", path: "KivySwiftLinkPack")
    try! Process().clone(repo: "https://github.com/psychowasp/KivySwiftSupportFiles.git", path: "KivySwiftSupportFiles")
    //try! Process().clone(repo: "https://github.com/meow464/kivy-ios.git", path: "kivy-ios-modded")
    
    create_venv(python: py_path)
    //pip_install(arg: "git+\(toolchain_py_url)")
    //https://github.com/kivy/kivy-ios
    //https://github.com/meow464/kivy-ios.git@custom_recipes
    //return
    for pip in ["wheel","cython", "kivy","git+https://github.com/garrik/mod-pbxproj@develop" ,"git+https://github.com/kivy/kivy-ios.git", "astor"] {
        pip_install(arg: pip)
    }
    //copyItem(from: "KivySwiftSupportFiles/toolchain.py", to: "venv/lib/python3.9/site-packages/kivy_ios/toolchain.py", force: true)
    
    //copyItem(from: "KivySwiftSupportFiles/swift_types.py", to: "venv/lib/python\(py_version_major)/site-packages/swift_types.py")

    copyItem(from: "KivySwiftSupportFiles/project_support_files", to: "project_support_files")
    copyItem(from: "KivySwiftSupportFiles/pythoncall_builder.py", to: "venv/lib/python\(py_version_major)/site-packages/pythoncall_builder.py")
    copyItem(from: "KivySwiftSupportFiles/swift_types.pyi", to: "venv/lib/python\(py_version_major)/site-packages/swift_types.pyi")
    createFolder(name: "wrapper_sources")
    createFolder(name: "wrapper_builds")
    createFolder(name: "wrapper_headers")
    createFolder(name: "wrapper_headers/c")
    createFolder(name: "wrapper_headers/swift")
    copyItem(from: "KivySwiftSupportFiles/project_support_files/wrapper_typedefs.h", to: "wrapper_headers/c/wrapper_typedefs.h")
    
    let fileman = FileManager()
    do {
        //try fileman.removeItem(atPath: "KivySwiftLink")
        try fileman.removeItem(atPath: "KivySwiftSupportFiles")
    } catch {
        print("cant delete folders")
    }
    _toolchain(path: root_path, command: .build, args: ["python3==\(py_version_full)", "kivy"])
    //toolchain(command: "build", args: ["kivy"])
    let proj_settings = ProjectHandler(db_path: nil)
    proj_settings.current_python_path = py_path
    proj_settings.current_python_version = py_version_full.split(separator: ".").map{Int($0)!}
    proj_settings.save()
    print("Setup done")

}

func UpdateWorkingFolder() {
    let fm = FileManager()
    if fm.fileExists(atPath: "KivySwiftSupportFiles") {try! fm.removeItem(atPath: "KivySwiftSupportFiles")}
    try! Process().clone(repo: "https://github.com/psychowasp/KivySwiftSupportFiles.git", path: "KivySwiftSupportFiles")
    let proj_settings = ProjectHandler(db_path: nil)
    let py_major = proj_settings.python_major_version
    //copyItem(from: "KivySwiftSupportFiles/swift_types.py", to: "venv/lib/python3.9/site-packages/swift_types.py",force: true)
    
    copyItem(from: "KivySwiftSupportFiles/project_support_files", to: "project_support_files",force: true)
    copyItem(from: "KivySwiftSupportFiles/pythoncall_builder.py", to: "venv/lib/python\(py_major)/site-packages/pythoncall_builder.py", force: true)
    copyItem(from: "KivySwiftSupportFiles/swift_types.pyi", to: "venv/lib/python\(py_major)/site-packages/swift_types.pyi", force: true)
    if !fm.fileExists(atPath: "wrapper_headers/c") {createFolder(name: "wrapper_headers/c")}
    if !fm.fileExists(atPath: "wrapper_headers/swift") {createFolder(name: "wrapper_headers/swift")}
    copyItem(from: "KivySwiftSupportFiles/project_support_files/wrapper_typedefs.h", to: "wrapper_headers/c/wrapper_typedefs.h", force: true)
    do {
        try fm.removeItem(atPath: "KivySwiftSupportFiles")
    } catch {
        print("cant delete folders")
    }
}


func update_project(files: [String]) {
    let db = ProjectHandler(db_path: nil)
    if let p = db.global.current {
        let project = ProjectManager(title: p.name, site_path: site_path)
        project.update_frameworks_lib_a()
        project.update_bridging_header(keys: files)
    }
    else {
        print("No Project Selected - use 'ksl project select <project name (no -ios)>'")
    }

}

func resourceURL(to path: String) -> URL? {
    return URL(string: path, relativeTo: Bundle.main.resourceURL)
}

func buildWrapper(name: String) {
    //if JsonStorage().current_project() != nil {
    let p_handler = ProjectHandler(db_path: nil)
    if p_handler.current_project != nil {
        print("building \(name).pyi")
        let file_man = FileManager()
        let file_url = URL(fileURLWithPath: file_man.currentDirectoryPath).appendingPathComponent("wrapper_sources").appendingPathComponent("\(name).pyi")
        guard file_man.fileExists(atPath: file_url.path) else {
            print("\(file_url.path) dont exist")
            return
        }
        let site_path = root_path + "/venv/lib/python\(p_handler.python_major_version)/site-packages/"
        BuildWrapperFile(root_path: root_path, site_path: site_path, py_name: name)
        update_project(files: [name])
        print("Done")
    } else {
        print("No Project Selected - use 'ksl project select <project name (no -ios)>'")
    }
}

func buildAllWrappers() {
    let p_handler = ProjectHandler(db_path: nil)
    if p_handler.current_project != nil {
        let fm = FileManager()
        let wrapper_sources = URL(fileURLWithPath: fm.currentDirectoryPath).appendingPathComponent("wrapper_sources")
        print("building all")
        let files = try! fm.contentsOfDirectory(atPath: wrapper_sources.path).map{$0.fileName()}.filter{!$0.fileName().contains(".DS_Store")}
        print(files)
        let site_path = root_path + "/venv/lib/python\(p_handler.python_major_version)/site-packages/"
        print(site_path)
        for file in files {
            print(file)
            BuildWrapperFile(root_path: root_path, site_path: site_path, py_name: file )
        }
        if files.count != 0 {
            update_project(files: files)
        }
    } else {
        print("No Project Selected - use 'ksl project select <project name (no -ios)>'")
    }
}

func updateWrappers(path: String! = nil) {
    let fm = FileManager()
    var wrapper_sources: URL
    var lib_sources: URL
    var rpath: String
    var spath: String
    
    
    if let p = path {
        wrapper_sources = URL(fileURLWithPath: p).appendingPathComponent("wrapper_sources")
        lib_sources = URL(fileURLWithPath: p).appendingPathComponent("dist/lib")
        rpath = p
        spath = URL(fileURLWithPath: p).appendingPathComponent("/venv/lib/python3.9/site-packages").path
    } else {
        wrapper_sources = URL(fileURLWithPath: fm.currentDirectoryPath).appendingPathComponent("wrapper_sources")
        lib_sources = URL(fileURLWithPath: fm.currentDirectoryPath).appendingPathComponent("dist/lib")
        rpath = root_path
        spath = site_path
    }
    let wrapper_files = try! fm.contentsOfDirectory(at: wrapper_sources, includingPropertiesForKeys: [], options: .skipsHiddenFiles)
    
    for file in wrapper_files {
        let file_date = fileModificationDate(url: file)!
        let filename = file.path.fileName()
        let lib_file = lib_sources.appendingPathComponent("lib\(file.path.fileName()).a")
        if fm.fileExists(atPath: lib_file.path) {
            let lib_file_date = fileModificationDate(url: lib_file)!
            if lib_file_date < file_date {
                print(filename)
                BuildWrapperFile(root_path: rpath, site_path: spath, py_name: filename )
            }
        } else {
            //print(filename)
            //BuildWrapperFile(root_path: rpath, site_path: spath, py_name: filename )
        }
        
    }
}
