
import SwiftyJSON
import Foundation
import PythonKit
import RealmSwift



class JsonStorage {
    private var data: JSON!
    
    init() {
        load()
    }
    
    func load() {
        let fileman = FileManager()
        let file = URL(fileURLWithPath: fileman.currentDirectoryPath).appendingPathComponent("project_support_files", isDirectory: true).appendingPathComponent("db.json")
        if fileman.fileExists(atPath: file.path) {
            let jdata = try! Data.init(contentsOf: file)
            data = try! JSON(data: jdata)
        }
    }
    
    func save() {
        let fileman = FileManager()
        let file = URL(fileURLWithPath: fileman.currentDirectoryPath).appendingPathComponent("project_support_files", isDirectory: true).appendingPathComponent("db.json")
        try! data.rawData().write(to: file)
    }
    
    
    func current_project() -> [String : Any]! {
        if let result = data {
            if let project = result.dictionaryObject {
                return project
            }
        }
        
        return nil
    }
    
    func set_project(name: String){
        let path = URL(fileURLWithPath: root_path, isDirectory: true).appendingPathComponent("\(name)-ios", isDirectory: true)
        if data == nil {data = [:]}
        data["project_name"].string = name
        data["project_path"].string = path.path
        
        save()
    }
    
}
let BRIDGE_STRING = """
#import \"runMain.h\"
#include \"Python.h\"
//#Wrappers Start"
#include "wrapper_typedefs.h"
//#Wrappers End
//Insert Other OBJ-C Headers Here:
"""

class ProjectManager {
    private var bridge_header: URL!
    private var project_target: URL
    private let root_path = URL(fileURLWithPath: FileManager().currentDirectoryPath)
    private let site_path: String
    private let project_title: String
    private let project_dir: URL
    private let pbxproj: PythonObject
    private var XcodeProject: PythonObject!
    
    var project: PythonObject!
    
    init(title: String, site_path: String) {
        project_title = title
        project_dir = root_path.appendingPathComponent("\(project_title)-ios", isDirectory: true)
        self.site_path = site_path
        let sys = Python.import("sys")
        sys.path.append(site_path)
        pbxproj = Python.import("pbxproj")
        XcodeProject = pbxproj.XcodeProject
        
        self.project_target = root_path.appendingPathComponent("\(title)-ios", isDirectory: true)
        
    }
    
    func load_xcode_project() {
        //let target = project_target
        let project_path = project_dir.appendingPathComponent("\(project_title).xcodeproj", isDirectory: true).appendingPathComponent("project.pbxproj")
        project = XcodeProject.load(project_path.path)
        
        bridge_header = project_dir.appendingPathComponent("\(project_title)-Bridging-Header.h")
        
        
    }
    
    func create_project(title: String, py_src: String) {
        _toolchain(path: root_path.path, command: .create, args: [title, py_src])
        bridge_header = project_dir.appendingPathComponent("\(project_title)-Bridging-Header.h")
        
        let file_man = FileManager()
        if !file_man.fileExists(atPath: bridge_header.path) {
            let bridge_string = BRIDGE_STRING
            try! bridge_string.write(to: bridge_header, atomically: true, encoding: .utf8)
        }
        
        update_classes_group()
    }
    
    func get_keys() {
    }
    
    func update_classes_group() {
        load_xcode_project()
        let file_man = FileManager()
        let cur_dir = URL(fileURLWithPath: file_man.currentDirectoryPath)
        let support_files = cur_dir.appendingPathComponent("project_support_files")
        if let project = self.project {
            project.remove_framework_search_paths([
                "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator14.4.sdk/System/Library/Frameworks",
                
            ])
            project.remove_library_search_paths(["/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator14.4.sdk/usr/lib"])
            let sources = project.get_or_create_group("Sources")
            //let sources_list = sources.children.map{String($0._get_comment())!}
            for src in sources.children {
                let ID = src
                let file = String(src._get_comment())!
                if file.contains("main.m") {
                    project.remove_file_by_id(ID)
                }
            }
            
            
            project.remove_group_by_name("Classes")
            
            //let support_files_path = cur_dir.appendingPathComponent("project_support_files")
            let classes = project.get_or_create_group("Objc-Classes")
            //let classes_list = Array(classes).map{$0._get_comment()}
            
            
            let main_m = try! String(contentsOfFile: project_dir.appendingPathComponent("main.m").path)
            let run_main_path = project_dir.appendingPathComponent("runMain.m")
            //write runMain.m
            do { try main_m.replacingOccurrences(of: "int main(int argc, char *argv[]) {", with: "int run_main(int argc, char *argv[]) {").write(to: run_main_path, atomically: true, encoding: .utf8) } catch { print(error.localizedDescription)}
            do { try "int run_main(int argc, char *argv[]);".write(to: project_dir.appendingPathComponent("runMain.h"), atomically: true, encoding: .utf8) } catch  { print(error.localizedDescription) }
            
            for item in ["runMain.h","runMain.m"] {
                project.add_file(project_dir.appendingPathComponent(item).path, parent: classes)
            }
            
            for item in try! file_man.contentsOfDirectory(atPath: support_files.path) {
                if item != "old_PythonSupport.swift" {
                    if item != ".DS_Store" && item.lowercased().contains(".swift") {
                        copyItem(from: support_files.appendingPathComponent(item).path, to: project_dir.appendingPathComponent(item).path)
                        project.add_file(project_dir.appendingPathComponent(item).path, parent: sources)
                    }
                }
            }
            
            project.set_flags("SWIFT_OBJC_BRIDGING_HEADER",bridge_header.path)
            project.set_flags("SWIFT_VERSION","5.0")
            project.set_flags("IPHONEOS_DEPLOYMENT_TARGET","11.0")
            project.add_file(bridge_header.path, parent: classes, force: false)
            project.add_header_search_paths(cur_dir.appendingPathComponent("wrapper_headers/c").path, false)
            
            
            //update_bridging_header(keys: ["joe", "says", "hallo", "fuckers"])
            
            project.backup()
            project.save()
        }
    }
    
    func update_bridging_header(keys: [String]) {
        var header_strings = try! String(contentsOfFile: bridge_header.path).split(separator: "\n")
        //let wrap_start = header_strings.firstIndex(where: {$0.contains("//#Wrappers Start")})!
        let wrap_end = header_strings.firstIndex(where: {$0.contains("//#Wrappers End")})!
        for key in keys {
            if !header_strings.contains("#include \"\(key).h\"") {
                if let _ = header_strings.firstIndex(where: {$0.contains("//#Wrappers Start")} ) {
                    header_strings.insert("#include \"\(key).h\"", at: wrap_end)
                }
            }
            
        }
        let bridge_export = header_strings.joined(separator: "\n")
        try! bridge_export.write(to: bridge_header, atomically: true, encoding: .utf8)
    }
    
    func update_frameworks_lib_a() {
        load_xcode_project()
        var updated = false
        let file_man = FileManager()
        let cur_dir = URL(fileURLWithPath: file_man.currentDirectoryPath)
        let root_lib_path = cur_dir.appendingPathComponent("dist/lib", isDirectory: true)
        let root_lib_files_a = try! file_man.contentsOfDirectory(atPath: root_lib_path.path).filter{$0.contains(".a")}
        
        if let project = self.project {
            let frameworks = project.get_or_create_group("Frameworks")
            let libs = frameworks.children.map{String($0._get_comment())!}.filter{$0.contains(".a")}
            for lib in root_lib_files_a.find_missing_lib_a(compare_array: libs) {
                if !updated { updated = true }
                project.add_file(root_lib_path.appendingPathComponent(lib).path, parent: frameworks, force: true)
            }
            update_swift_wrapper_group(project: project, updated: &updated)
        if updated {
            project.backup()
            project.save()
            }
        } else {print("no project selected")}
        
        
    }
    
    func update_swift_wrapper_group(project: PythonObject, updated: inout Bool) {
        let fm = FileManager()
        //let proj_dir = self.project_dir
        let cur_dir = URL(fileURLWithPath: fm.currentDirectoryPath)
        
        let wrap_dir = cur_dir.appendingPathComponent("wrapper_headers/swift", isDirectory: true)
        let wrap_dir_files = try! fm.contentsOfDirectory(atPath: wrap_dir.path).filter{$0 != ".DS_Store"}
        
        let sources = project.get_or_create_group("Sources")
        let swift_wrappers = project.get_or_create_group("SwiftWrappers",parent: sources)
        let swift_wraps = swift_wrappers.children.map{String($0._get_comment())!}

        for wrap in wrap_dir_files.find_missing(compare_array: swift_wraps) {
            if !updated { updated = true }
            project.add_file(wrap_dir.appendingPathComponent(wrap).path, parent: swift_wrappers, force: true)
        }
        
    }
    
    
}


extension Array where Element == String {
    func find_missing_lib_a(compare_array: [String]) -> [String]{
        return Array(Set(self).subtracting(compare_array))
    }
    
    func find_missing(compare_array: [String]) -> [String]{
        return Array(Set(self).subtracting(compare_array))
    }
}

