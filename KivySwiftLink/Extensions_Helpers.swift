//
//  Extensions_Helpers.swift
//

import Foundation
import AppKit


let ANSWERS = ["y","yes"]


func getVersion(string: String) -> versionTuple {
    let ver = string.split(separator: ".").map{Int($0)!}
    return versionTuple(major: ver[0], minor: ver[1], micro: ver[2])
}


func makeExecutable(file: String) {
    let fm = FileManager()
    var attributes = [FileAttributeKey : Any]()
    attributes[.posixPermissions] = 0o755
    try! fm.setAttributes(attributes, ofItemAtPath: file)
}

extension String {

    func fileName() -> String {
        return URL(fileURLWithPath: self).deletingPathExtension().lastPathComponent
    }

    func fileExtension() -> String {
        return URL(fileURLWithPath: self).pathExtension
    }
}

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
        print("<\(to)> already exist do you wish to overwrite it ?")
        print("enter y or yes: ", separator: "", terminator: " ")
        if let input_string = readLine()?.lowercased() {
            let input = input_string.trimmingCharacters(in: .whitespaces)
            
            if ANSWERS.contains(input) {
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


func downloadPython() {
    let url = URL(string: "https://www.python.org/ftp/python/3.9.2/python-3.9.2-macosx10.9.pkg")
    print("""
        Python 3.9 not found, do you wish for KivySwiftLink to download <python-3.9.2-macosx10.9.pkg>
        from \(url!) ?
    """)
    print("enter y or yes:", separator: "", terminator: " ")
    if let input = readLine()?.lowercased() {
        if ANSWERS.contains(input) {
            FileDownloader.loadFileSync(url: url!) { (path, error) in
                
                print("\nPython 3.9.2 downloaded to : \(path!)")
                
                showInFinder(url: path!)
                print("\nrun <python-3.9.2-macosx10.9.pkg> in the finder window")
                    //readLine()
                print("run \"/Applications/Python 3.9/Install Certificates.command\"\n")
                }
        }
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


func fileModificationDate(url: URL) -> Date? {
    do {
        let attr = try FileManager.default.attributesOfItem(atPath: url.path)
        return attr[FileAttributeKey.modificationDate] as? Date
    } catch {
        return nil
    }
}

fileprivate func showInFinderAndSelectLastComponent(of url: URL) {
    NSWorkspace.shared.activateFileViewerSelecting([url])
}


func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}




extension Collection {
@inlinable
public __consuming func split_(
    maxSplits: Int = Int.max,
    omittingEmptySubsequences: Bool = true,
    includeSeparator: Bool = false,
    whereSeparator isSeparator: (Element) throws -> Bool
) rethrows -> [SubSequence] {
    var result: [SubSequence] = []
    var subSequenceStart: Index = startIndex

    func appendSubsequence(end: Index) -> Bool {
        if subSequenceStart == end && omittingEmptySubsequences {
            return false
        }
        result.append(self[subSequenceStart..<end])
        return true
    }

    if maxSplits == 0 || isEmpty {
        _ = appendSubsequence(end: endIndex)
        return result
    }

    var subSequenceEnd = subSequenceStart
    let cachedEndIndex = endIndex
    while subSequenceEnd != cachedEndIndex {
        if try isSeparator(self[subSequenceEnd]) {
            let didAppend = appendSubsequence(end: subSequenceEnd)
            if includeSeparator {
                subSequenceStart = subSequenceEnd
                formIndex(after: &subSequenceEnd)
            } else {
                formIndex(after: &subSequenceEnd)
                subSequenceStart = subSequenceEnd
            }

            if didAppend && result.count == maxSplits {
                break
            }
            continue
        }
        formIndex(after: &subSequenceEnd)
    }

    if subSequenceStart != cachedEndIndex || !omittingEmptySubsequences {
        result.append(self[subSequenceStart..<cachedEndIndex])
    }

    return result
}

}


extension String {
    func titleCase() -> String {
        return self
            .replacingOccurrences(of: "([A-Z])",
                                  with: "_$1",
                                  options: .regularExpression,
                                  range: range(of: self))
            // If input is in llamaCase
            .lowercased()
    }
}


extension String {
    func lowercaseFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func lowercaseFirstLetter() {
        self = self.lowercaseFirstLetter()
    }
}
