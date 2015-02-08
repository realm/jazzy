//
//  DocCommand.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-07.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SourceKittenFramework

// MARK: Extend module

extension Module {
    /// Documentation for this Module, computed by spawning new sourcekitten processes.
    var docsBySpawningNewProcesses: [NSDictionary] {
        var fileIndex = 1
        let sourceFilesCount = sourceFiles.count
        let args = compilerArguments
        return compact(sourceFiles.map({ filePath in
            fputs("Parsing \(filePath.lastPathComponent) (\(fileIndex++)/\(sourceFilesCount))\n", stderr)
            if let selfOutput = runSelf(["doc", "--single-file", filePath] + args) {
                if countElements(selfOutput) > 0 {
                    if let outputData = selfOutput.dataUsingEncoding(NSUTF8StringEncoding) {
                        var error: NSError? = nil
                        let jsonObject = NSJSONSerialization.JSONObjectWithData(outputData, options: nil, error: &error) as NSDictionary?
                        if error == nil {
                            if let jsonObject = jsonObject {
                                return jsonObject
                            }
                        }
                    }
                }
            }
            fputs("Could not parse `\(filePath.lastPathComponent)`. Please open an issue at https://github.com/jpsim/SourceKitten/issues with the file contents.\n", stderr)
            return nil
        }))
    }
}

/**
Run sourcekitten as a new process.

:param: processArguments arguments to pass to new sourcekitten process.

:returns: sourcekitten STDOUT output.
*/
func runSelf(processArguments: [String]) -> String? {
    let task = NSTask()
    task.launchPath = NSBundle.mainBundle().executablePath! // Safe to force unwrap
    task.arguments = processArguments

    let pipe = NSPipe()
    task.standardOutput = pipe

    task.launch()

    let file = pipe.fileHandleForReading
    let output = NSString(data: file.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)
    file.closeFile()

    return output
}
