//
//  main.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Commandant
import Foundation

let registry = CommandRegistry()
registry.register(DocCommand())
registry.register(SyntaxCommand())
registry.register(StructureCommand())
registry.register(VersionCommand())

let helpCommand = HelpCommand(registry: registry)
registry.register(helpCommand)

registry.main(defaultCommand: helpCommand) { error in
    fputs("\(error.localizedDescription)\n", stderr); return
}
