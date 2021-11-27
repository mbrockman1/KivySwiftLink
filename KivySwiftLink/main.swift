//
//  main.swift
//  KivySwiftLink2
//
//  Created by MusicMaker on 14/10/2021.
//

import Foundation

//PythonLibrary.useLibrary(at: root_path + "venv/bin/python")
//RunPythonScript()




let root_path = FileManager().currentDirectoryPath
let site_path = root_path + "/venv/lib/python3.9/site-packages/"

import ArgumentParser

struct KivySwiftLink: ParsableCommand {
    
    static let configuration = CommandConfiguration(
            abstract: "KivySwiftLink",
        subcommands: [Setup.self,SelectProject.self,Build.self,BuildAll.self,Create.self, Toolchain.self,Install.self, RunTest.self]
    )
    
}
extension KivySwiftLink {
    
    struct Install: ParsableCommand {
        @Option(name: .shortAndLong, help: "overwrite ksl if it already exist")
        var forced: Bool?
        
        func run() {
            if let forced = self.forced {
                copyItem(from: "./KivySwiftLink", to: "/usr/local/bin/ksl",force: forced)
            } else {
                print("Do you wish to copy KivySwiftLink as ksl to /usr/local/bin/")
                if let str = readLine() {
                    if str == "y" {
                        print("copied file to /usr/local/bin/ksl")
                        copyItem(from: "./KivySwiftLink", to: "/usr/local/bin/ksl")
                    }
                }
            }
            
        }
    }
    
    
    struct Setup: ParsableCommand {
        
        
        func run() {
            print("Installing KivySwiftLink Components")
            InitWorkingFolder()
        }
    }
    
    struct Build: ParsableCommand {
        
        @Argument() var filename: String
        
        func run() {
            
            if JsonStorage().current_project() != nil {
                print("building \(filename).pyi")
                let file_man = FileManager()
                let file_url = URL(fileURLWithPath: file_man.currentDirectoryPath).appendingPathComponent("wrapper_sources").appendingPathComponent("\(filename).pyi")
                guard file_man.fileExists(atPath: file_url.path) else {
                    print("\(file_url.path) dont exist")
                    return
                }
                BuildWrapperFile(root_path: root_path, site_path: site_path, py_name: filename)
                update_project(files: [filename])
                print("Done")
            } else {
                print("No Project Selected - use 'ksl select-project <project name (no -ios)>'")
            }
            
        }
    }
    
    struct BuildAll: ParsableCommand {
            
            func run() {
                if JsonStorage().current_project() != nil {
                    let file_man = FileManager()
                    let wrapper_sources = URL(fileURLWithPath: file_man.currentDirectoryPath).appendingPathComponent("wrapper_sources")
                    print("building all")
                    let files = try! file_man.contentsOfDirectory(atPath: wrapper_sources.path).map{$0.replacingOccurrences(of: ".py", with: "")}
                    for file in files {
                        print(file)
                        BuildWrapperFile(root_path: root_path, site_path: site_path, py_name: file )
                    }
                    if files.count != 0 {
                        update_project(files: files)
                    }
                }
                
                
            }
        }
    
    struct SelectProject: ParsableCommand {
            
            @Argument() var project_name: String
            
            func run() {
                //let path = URL(fileURLWithPath: root_path, isDirectory: true).appendingPathComponent("\(project_name)-ios", isDirectory: true)
                
                print("using \(project_name)-ios")
                let jsondb = JsonStorage()
                jsondb.set_project(name: project_name)
            }
        }
    
    struct Create: ParsableCommand {
        
        @Argument() var project_name: String
        @Argument() var python_source_folder: String
        func run() {
            print("creating \(project_name)-ios")
            let project = ProjectManager(title: project_name, site_path: site_path)
            project.create_project(title: project_name, py_src: python_source_folder)
            project.load_xcode_project()
            
        }
    }
    
    struct Update: ParsableCommand {
        
        @Argument() var project_name: String
        @Argument() var python_source_folder: String
        func run() {
            print("creating \(project_name)-ios")
            let project = ProjectManager(title: project_name, site_path: site_path)
            //project.create_project(title: project_name, py_src: python_source_folder)
            //project.load_xcode_project()
            
        }
    }
    
    
    
    struct RunTest: ParsableCommand {
        
        func run() {
            //let file_man = FileManager()
            //let wrapper_sources = URL(fileURLWithPath: file_man.currentDirectoryPath).appendingPathComponent("wrapper_sources")
            //buildTestWrapper()
            //for file in try! file_man.contentsOfDirectory(atPath: wrapper_sources.path) {
            //    BuildWrapperFile(root_path: root_path, site_path: site_path, py_name: file.replacingOccurrences(of: ".py", with: "")  )
            //}
            show_buildins()
            
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
            toolchain_venv(command: command!, args: args)
        }
    }
}


KivySwiftLink.main()
