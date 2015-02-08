//
//  Version.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-07.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Commandant
import LlamaKit

private let version = "0.3.0"

struct VersionCommand: CommandType {
    let verb = "version"
    let function = "Display the current version of SourceKitten"

    func run(mode: CommandMode) -> Result<()> {
        switch mode {
        case let .Arguments:
            println(version)

        default:
            break
        }
        
        return success(())
    }
}
