//
//  SourceDeclaration.swift
//  SourceKitten
//
//  Created by JP Simard on 7/15/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

/// Represents a source code declaration.
public struct SourceDeclaration {
    let type: ObjCDeclarationKind
    let location: SourceLocation
    let name: String?
    let usr: String?
    let declaration: String?
    let mark: String?
    let documentation: Documentation?
    let commentBody: String?
    let children: [SourceDeclaration]
}

extension SourceDeclaration {
    init?(cursor: CXCursor) {
        guard clang_isDeclaration(cursor.kind) != 0 else {
            return nil
        }
        let comment = cursor.parsedComment()
        guard comment.kind() != CXComment_Null else {
            return nil
        }
        type = cursor.objCKind()
        location = cursor.location()
        name = cursor.name()
        usr = cursor.usr()
        declaration = cursor.declaration()
        mark = cursor.mark()
        documentation = Documentation(comment: comment)
        commentBody = cursor.commentBody()
        children = cursor.flatMap(SourceDeclaration.init).rejectPropertyMethods()
    }
}

extension SequenceType where Generator.Element == SourceDeclaration {
    /// Removes implicitly generated property getters & setters
    func rejectPropertyMethods() -> [SourceDeclaration] {
        let tmpChildren = Array(self)
        let properties = tmpChildren.filter { $0.type == .Property }
        let propertyGetterSetterUSRs = properties.flatMap { property -> [String] in
            let usr = property.usr!
            let pyStartIndex = usr.rangeOfString("(py)")!.startIndex
            let usrPrefix = usr.substringToIndex(pyStartIndex)
            let declaration = property.declaration!
            let getterRegex = try! NSRegularExpression(pattern: "getter=(\\w+)", options: [])
            let fullDeclarationRange = NSRange(location: 0, length: (declaration as NSString).length)
            let getterMatches = getterRegex.matchesInString(declaration, options: [], range: fullDeclarationRange)
            let getter: String
            if getterMatches.count > 0 {
                let getterName = (declaration as NSString).substringWithRange(getterMatches[0].rangeAtIndex(1))
                getter = usrPrefix + "(im)\(getterName)"
            } else {
                getter = usr.stringByReplacingOccurrencesOfString("(py)", withString: "(im)")
            }
            let setterRegex = try! NSRegularExpression(pattern: "setter=(\\w+:)", options: [])
            let setterMatches = setterRegex.matchesInString(declaration, options: [], range: fullDeclarationRange)
            let setter: String
            if setterMatches.count > 0 {
                let setterName = (declaration as NSString).substringWithRange(setterMatches[0].rangeAtIndex(1))
                setter = usrPrefix + "(im)\(setterName)"
            } else {
                let capitalFirstLetter = String(usr.characters[pyStartIndex.advancedBy(4)]).capitalizedString
                let restOfSetterName = usr.substringFromIndex(pyStartIndex.advancedBy(5))
                setter = "\(usrPrefix)(im)set\(capitalFirstLetter)\(restOfSetterName):"
            }
            return [getter, setter]
        }
        return tmpChildren.filter { !propertyGetterSetterUSRs.contains($0.usr!) }
    }
}

extension SourceDeclaration: Hashable {
    public var hashValue: Int {
        return usr?.hashValue ?? 0
    }
}

public func ==(lhs: SourceDeclaration, rhs: SourceDeclaration) -> Bool {
    return lhs.usr == rhs.usr
}

// MARK: Comparable

extension SourceDeclaration: Comparable {}

/// A [strict total order](http://en.wikipedia.org/wiki/Total_order#Strict_total_order)
/// over instances of `Self`.
public func <(lhs: SourceDeclaration, rhs: SourceDeclaration) -> Bool {
    // Sort by file path.
    switch lhs.location.file.compare(rhs.location.file) {
    case .OrderedDescending:
        return false
    case .OrderedAscending:
        return true
    case .OrderedSame:
        break
    }

    // Then line.
    if lhs.location.line > rhs.location.line {
        return false
    } else if lhs.location.line < rhs.location.line {
        return true
    }

    // Then column.
    if lhs.location.column > rhs.location.column {
        return false
    }

    return true
}
