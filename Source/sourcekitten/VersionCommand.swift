//
//  Version.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-07.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Commandant
import Result

private let version = "0.5.2"

struct VersionCommand: CommandType {
    let verb = "version"
    let function = "Display the current version of SourceKitten"

    func run(mode: CommandMode) -> Result<(), CommandantError<SourceKittenError>> {
        switch mode {
        case .Arguments:
            print(version)

        default:
            break
        }
        return .Success()
    }
}
