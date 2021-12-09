//
//  DB_Items.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 08/12/2021.
//

import Foundation
import RealmSwift


class KslProject: Object {
    @Persisted var name: String
    @Persisted var path: String
}

class GlobalSettings: Object {
    @Persisted var root_path: String
    @Persisted var site_path: String
    @Persisted var current: KslProject!
    let projects = List<KslProject>()
}

func load_global(realm: Realm) -> GlobalSettings {
    if let global = realm.objects(GlobalSettings.self).first {
        return global
    }
    print("loading global")
    let global = GlobalSettings()
    global.root_path = root_path
    global.site_path = site_path
    print("global loaded")
    RealmService.shared.create(in: realm, object: global)
    print("global written")
    return global
}

class ProjectHandler {
    let realm: Realm
    let service = RealmService.shared
    var global: GlobalSettings
    init(db_path: String!) {
        var url: URL
        if let path = db_path {
            url = URL(fileURLWithPath: path).appendingPathComponent("project_support_files/db.realm")
        } else {
            url = URL(fileURLWithPath: root_path).appendingPathComponent("project_support_files/db.realm")
        }
        
        realm = (service.newRealm(url: url, types: [KslProject.self,GlobalSettings.self]))!
        global = load_global(realm: realm)
    }
    
    var current_project: KslProject! {
        set {
            print("current_project",newValue.name)
            try! realm.write {
                global.current = newValue
            }
        }
        
        get {
            return global.current
        }
    }
    
    func add_project(name: String, path: String) -> KslProject {
        let project = KslProject()
        project.name = name
        project.path = path
        service.create(in: realm, object: project)
        return project
    }
    
    func get_project(name: String) -> KslProject! {
        realm.objects(KslProject.self).first { (project) -> Bool in
            project.name == name
        }
    }
    
    func set_current_project(project: KslProject) {
        global.current = project
    }
    
    func save(){
        print("saving")
        service.update(in: realm, object: global)
    }
}
