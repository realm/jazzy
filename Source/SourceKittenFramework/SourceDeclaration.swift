//
//  SourceDeclaration.swift
//  SourceKitten
//
//  Created by JP Simard on 7/15/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

public func insertMarks(declarations: [SourceDeclaration], limitRange: NSRange? = nil) -> [SourceDeclaration] {
    guard declarations.count > 0 else { return [] }
    guard let path = declarations.first?.location.file, let file = File(path: path) else {
        fatalError("can't extract marks without a file.")
    }
    let currentMarks = file.contents.pragmaMarks(path, excludeRanges: declarations.map({ $0.range }), limitRange: limitRange)
    let newDeclarations: [SourceDeclaration] = declarations.map { declaration in
        var varDeclaration = declaration
        varDeclaration.children = insertMarks(declaration.children, limitRange: declaration.range)
        return varDeclaration
    }
    return (newDeclarations + currentMarks).sort()
}

/// Represents a source code declaration.
public struct SourceDeclaration {
    let type: ObjCDeclarationKind
    let location: SourceLocation
    let extent: (start: SourceLocation, end: SourceLocation)
    let name: String?
    let usr: String?
    let declaration: String?
    let documentation: Documentation?
    let commentBody: String?
    var children: [SourceDeclaration]

    /// Range
    var range: NSRange {
        return extent.start.rangeToEndLocation(extent.end)
    }

    /// Returns the USR for the auto-generated getter for this property.
    ///
    /// - warning: can only be invoked if `type == .Property`.
    var getterUSR: String {
        return generateAccessorUSR(getter: true)
    }

    /// Returns the USR for the auto-generated setter for this property.
    ///
    /// - warning: can only be invoked if `type == .Property`.
    var setterUSR: String {
        return generateAccessorUSR(getter: false)
    }

    private func generateAccessorUSR(getter getter: Bool) -> String {
        assert(type == .Property)
        guard let usr = usr else {
            fatalError("Couldn't extract USR")
        }
        guard let declaration = declaration else {
            fatalError("Couldn't extract declaration")
        }
        let pyStartIndex = usr.rangeOfString("(py)")!.startIndex
        let usrPrefix = usr.substringToIndex(pyStartIndex)
        let fullDeclarationRange = NSRange(location: 0, length: (declaration as NSString).length)
        let regex = try! NSRegularExpression(pattern: getter ? "getter\\s*=\\s*(\\w+)" : "setter\\s*=\\s*(\\w+:)", options: [])
        let matches = regex.matchesInString(declaration, options: [], range: fullDeclarationRange)
        if matches.count > 0 {
            let accessorName = (declaration as NSString).substringWithRange(matches[0].rangeAtIndex(1))
            return usrPrefix + "(im)\(accessorName)"
        } else if getter {
            return usr.stringByReplacingOccurrencesOfString("(py)", withString: "(im)")
        }
        // Setter
        let capitalFirstLetter = String(usr.characters[pyStartIndex.advancedBy(4)]).capitalizedString
        let restOfSetterName = usr.substringFromIndex(pyStartIndex.advancedBy(5))
        return "\(usrPrefix)(im)set\(capitalFirstLetter)\(restOfSetterName):"
    }
}

extension SourceDeclaration {
    init?(cursor: CXCursor) {
        guard cursor.shouldDocument() else {
            return nil
        }
        type = cursor.objCKind()
        location = cursor.location()
        extent = cursor.extent()
        name = cursor.name()
        usr = cursor.usr()
        declaration = cursor.declaration()
        documentation = Documentation(comment: cursor.parsedComment())
        commentBody = cursor.commentBody()
        children = cursor.flatMap(SourceDeclaration.init).rejectPropertyMethods()
    }
}

extension SequenceType where Generator.Element == SourceDeclaration {
    /// Removes implicitly generated property getters & setters
    func rejectPropertyMethods() -> [SourceDeclaration] {
        let propertyGetterSetterUSRs = filter {
            $0.type == .Property
        }.flatMap {
            [$0.getterUSR, $0.setterUSR]
        }
        return filter { !propertyGetterSetterUSRs.contains($0.usr!) }
    }
}

extension SourceDeclaration: Hashable {
    public var hashValue: Int {
        return usr?.hashValue ?? 0
    }
}

public func ==(lhs: SourceDeclaration, rhs: SourceDeclaration) -> Bool {
    return lhs.usr == rhs.usr &&
        lhs.location == rhs.location
}

// MARK: Comparable

extension SourceDeclaration: Comparable {}

/// A [strict total order](http://en.wikipedia.org/wiki/Total_order#Strict_total_order)
/// over instances of `Self`.
public func <(lhs: SourceDeclaration, rhs: SourceDeclaration) -> Bool {
    return lhs.location < rhs.location
}
