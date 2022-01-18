//
//  version.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 06/12/2021.
//

import Foundation

public struct versionTuple {
    let major: Int
    let minor: Int
    let micro: Int
}




extension versionTuple {
    
    var string: String {
        "\(AppVersion.major).\(AppVersion.minor).\(AppVersion.micro)"
    }
    
    func compareVersionWithString(string: String) -> Bool {
        let string_ver = string.split(separator: ".").map{Int($0)!}
        if self.major < string_ver[0] {return true}
        if self.minor < string_ver[1] {return true}
        if self.micro < string_ver[2] {return true}
        return false
    }
    
    static func == (lhs: versionTuple, rhs: versionTuple) -> Bool {
        if lhs.major < rhs.major { return true}
        if lhs.minor < rhs.minor { return true}
        if lhs.micro < rhs.major { return true}
        return false
        }
}


public let AppVersion = versionTuple(major: 0, minor: 2, micro: 1)

