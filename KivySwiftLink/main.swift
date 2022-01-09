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
        version: AppVersion.string,
        subcommands: [Setup.self,Build.self, Toolchain.self,Install.self, UpdateApp.self, Project.self, Helper.self].sorted(by: {$0._commandName < $1._commandName})
    )
    
}
extension KivySwiftLink {
    
    struct Install: ParsableCommand {
        static let configuration = CommandConfiguration(
                abstract: "Copy KivySwftLink as ksl to /usr/local/bin")
        @Flag(name: .shortAndLong, help: "overwrite ksl if it already exist")
        var forced = false
        
        func run() {
            InstallKSL(forced: forced)
        }
    }
    
    
    struct Setup: ParsableCommand {
        static let configuration = CommandConfiguration(
                abstract: "Setup working folder")
        @Flag(name: .shortAndLong, help: "overwrite ksl if it already exist")
        var update_only = false
        
        func run() {
            
            if update_only {
                print("Updating KivySwiftLink Components")
                UpdateWorkingFolder()
            } else {
                print("Installing KivySwiftLink Components")
                InitWorkingFolder()
            }
        }
    }
    
    
    
    
    
    
    
    
    
    struct UpdateApp: ParsableCommand {
        static let configuration = CommandConfiguration(
                abstract: "Download/install newest release of KivySwftLink from github")
        func run() {
            let release = getKslReleases().first!
            if AppVersion.compareVersionWithString(string: release.name) {
                downloadKslRelease(release: release, forced: false)
            }
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
            updateWrappers()
            //show_buildins()
            
        }
    }
    
    struct Toolchain: ParsableCommand {
        
        static let configuration = CommandConfiguration(
                    abstract: "Run toolchain commands")
        
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
            toolchain_venv(path: root_path ,command: command!, args: args)
        }
    }
    
}









struct Project: ParsableCommand {
    static let configuration = CommandConfiguration(
                abstract: "Project options",
        subcommands: [Create.self, Select.self, Update.self]
                )
    struct Select: ParsableCommand {
        static let configuration = CommandConfiguration(
                        abstract: "select project target, when using build <commands> / project update")
        @Argument() var project_name: String
                    
        func run() {
            //let path = URL(fileURLWithPath: root_path, isDirectory: true).appendingPathComponent("\(project_name)-ios", isDirectory: true)
            
            print("using \(project_name)-ios")
            let fileman = FileManager()
            let path = URL(fileURLWithPath: root_path, isDirectory: true).appendingPathComponent("\(project_name)-ios", isDirectory: true)
            if !fileman.fileExists(atPath: path.path) {fatalError("\(path.path) doesnt exist")}
            let db = ProjectHandler(db_path: nil)
            if let ksl_proj = db.get_project(name: project_name) {
                db.current_project = ksl_proj
            } else {
                let ksl_proj = db.add_project(name: project_name, path: path.path)
                db.current_project = ksl_proj
            }
            
        }
    }
    
    struct Create: ParsableCommand {
        static let configuration = CommandConfiguration(
                        abstract: "Create new ios project")
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
        static let configuration = CommandConfiguration(
                        abstract: "Update ios project = toolchain update <project>-ios")
        func run() {
            let db = ProjectHandler(db_path: nil)
            if let current = db.current_project {
                _toolchain(path:root_path , command: .update, args: ["\(current.name)-ios"])
            }
        }
    }
    
}









struct Build: ParsableCommand {
    static let configuration = CommandConfiguration(
                    abstract: "Build Wrapper Files",
                    subcommands: [File.self, All.self],
                    defaultSubcommand: File.self
        
                )
    
    struct File: ParsableCommand {
        @Argument() var filename: String
        func run() {
            buildWrapper(name: filename)
        }
    }
    
    
    struct All: ParsableCommand {
        @Flag(name: .shortAndLong, help: "Build Changes Only")
        var update = false
        func run() {
            print("building all command used", update)
            if update {
                updateWrappers()
            } else {
                buildAllWrappers()
            }
            
        }
    }
}



struct Helper: ParsableCommand {
    static let configuration = CommandConfiguration(
                    abstract: "Xcode Helper - Use Xcode Build to update Wrappers",
                    subcommands: [Script.self, Update.self]
                )
    
    struct Script: ParsableCommand {
        
        func run() throws {
            
        }
    }
    
    struct Update: ParsableCommand {
        @Argument() var path: String
        
        func run() throws {
            updateWrappers(path: path)
        }
    }
}


KivySwiftLink.main()
