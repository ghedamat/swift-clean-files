//
//  main.swift
//  list files and remove them
//
//  Created by Mattia Gheda on 14-12-14.
//  Copyright (c) 2014 Mattia Gheda. All rights reserved.
//

import Foundation

struct File: Printable {
    var path: String = ""
    var attrs: [NSObject: AnyObject] = NSDictionary()
    
    var isDirectory: Bool {
        if self.attrs[NSFileType] as String == NSFileTypeDirectory {
            return true
        } else {
            return false
        }
    }
    
    var createdAt: NSDate {
        let d: AnyObject? = self.attrs[NSFileCreationDate]
        return d as NSDate
    }
    
    var description: String {
        return "\nFile:\npath: \(path)\nisDirectory: \(isDirectory)\ncreatedAt: \(createdAt)\n"
    }
}


func getFiles(basepath: String) -> [File]{
    var error: NSError?;
    let m = NSFileManager.defaultManager()
    let enumerator: NSDirectoryEnumerator? = m.enumeratorAtPath(basepath)
    var arr: [File] = Array()
    while let e = enumerator?.nextObject() as? String {
        var p = e;
        if !Path(e).isAbsolute() {
           p = basepath + "/" + e
        }
        let a = m.attributesOfItemAtPath(p, error: &error)
        var myp = File(path: p, attrs: a!)
        arr.append(myp)
    }
    return arr
}

func filterOldFiles(files: [File], days: Double) -> [File] {
    let start_date = NSDate(timeIntervalSinceNow: -(60 * 60 * 24 * days))

    let filtered = files.filter({a in
        a.createdAt.compare(start_date) == NSComparisonResult.OrderedAscending
    })
    
    return filtered
}

func deleteFiles(files: [File]) {
    var error: NSError?;
    let m = NSFileManager.defaultManager()
    for file in files {
       m.removeItemAtPath(file.path, error: &error)
    }
}


// main
let cli = CommandLine()

let dirPath = StringOption(shortFlag: "p", longFlag: "path", required: true, helpMessage: "Path to the directory to clean.")
let days = IntOption(shortFlag: "d", longFlag: "days",required: true, helpMessage: "Dry run" )
let dryRun = BoolOption(shortFlag: "n", longFlag: "dry-run", helpMessage: "Dry run")
let verbose = BoolOption(shortFlag: "v", longFlag: "verbose", helpMessage: "List files that will be deleted")
let help = BoolOption(shortFlag: "h", longFlag: "help", helpMessage: "Prints a help message.")

cli.addOptions(dirPath, days, dryRun, verbose, help)


let (success, error) = cli.parse()
if !success {
  println(error!)
  cli.printUsage()
  exit(EX_USAGE)
}

if let basepath = dirPath.value {
    var files = getFiles(basepath)
    let filtered = filterOldFiles(files, Double(days.value!));
    let m = NSFileManager.defaultManager()
    if verbose.value {
        println(filtered)
    }
    if !dryRun.value {
        deleteFiles(filtered);
    }
}
