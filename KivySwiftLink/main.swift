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
        subcommands: [Setup.self,SelectProject.self,Build.self,Create.self, Toolchain.self,Install.self]
    )
    
}
extension KivySwiftLink {
    
    struct Install: ParsableCommand {
        
        
        func run() {
            print("Do you wish to copy KivySwiftLink as ksl to /usr/local/bin/")
            if let str = readLine() {
                if str == "y" {
                    print("copied file to /usr/local/bin/ksl")
                    copyItem(from: "./KivySwiftLink", to: "/usr/local/bin/ksl")
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
