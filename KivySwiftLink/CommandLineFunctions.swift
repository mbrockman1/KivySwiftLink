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
                if fileman.fileExists(atPath: to) {
                    try fileman.removeItem(atPath: to)
                }
                
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

func downloadPython() {
    let url = URL(string: "https://www.python.org/ftp/python/3.9.2/python-3.9.2-macosx10.9.pkg")
    print("\nPython 3.9.2 not found, downloading <python-3.9.2-macosx10.9.pkg>")
    FileDownloader.loadFileSync(url: url!) { (path, error) in
        
        print("\nPython 3.9.2 downloaded to : \(path!)")
        
        showInFinder(url: URL(fileURLWithPath: path!))
        print("\nrun <python-3.9.2-macosx10.9.pkg> in the finder window")
            //readLine()
        print("run \"/Applications/Python 3.9/Install Certificates.command\"\n")
        }
        
        
        
    
}
func showInFinder(url: URL?) {
    guard let url = url else { return }
    
    if url.hasDirectoryPath {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
    }
    else {
        showInFinderAndSelectLastComponent(of: url)
    }
}

fileprivate func showInFinderAndSelectLastComponent(of url: URL) {
    NSWorkspace.shared.activateFileViewerSelecting([url])
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
func toolchain_venv(command: String, args: [String]) -> Int32 {
    //print("toolchain_venv running")
    //var targs: [String] = ["-c","source venv/bin/activate", "&&", "python --version"]
    let targs = ["-c", """
    source venv/bin/activate
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

