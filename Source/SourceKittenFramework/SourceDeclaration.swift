//
//  SourceDeclaration.swift
//  SourceKitten
//
//  Created by JP Simard on 7/15/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

import SWXMLHash

public struct SourceLocation {
    let file: String
    let line: UInt32
    let column: UInt32
    let offset: UInt32
}

public enum Text {
    case Para(String, String?)
    case Verbatim(String)
}

public struct Parameter {
    let name: String
    let discussion: [Text]

    init(comment: CXComment) {
        name = comment.paramName() ?? "<none>"
        discussion = comment.paragraph().paragraphToString()
    }
}

public struct Documentation {
    let parameters: [Parameter]
    let discussion: [Text]
    let returnDiscussion: [Text]

    init(comment: CXComment) {
        var params = [Parameter]()
        var d = [Text]()
        var r = [Text]()

        for i in 0..<comment.count() {
            let c = comment[i]
            switch c.kind().rawValue {
            case CXComment_Text.rawValue:
                d += c.paragraphToString()
                break
            case CXComment_InlineCommand.rawValue:
                break
            case CXComment_HTMLStartTag.rawValue: break
            case CXComment_HTMLEndTag.rawValue: break
            case CXComment_Paragraph.rawValue:
                d += c.paragraphToString()
                break
            case CXComment_BlockCommand.rawValue:
                let command = c.commandName()
                if command == "return" {
                    r += c.paragraphToString()
                }
                else {
                    d += c.paragraphToString(command)
                }
                break
            case CXComment_ParamCommand.rawValue:
                params.append(Parameter(comment: c))
                break
            case CXComment_VerbatimBlockCommand.rawValue: break
            case CXComment_VerbatimBlockLine.rawValue: break
            case CXComment_VerbatimLine.rawValue:
                d += c.paragraphToString()
                break
            default: break
            }
        }

        parameters = params
        discussion = d
        returnDiscussion = r
    }
}

/// Represents a source code declaration.
public struct SourceDeclaration {
    let type: ObjCDeclarationKind
    let location: SourceLocation

    let name: String?
    let usr: String?
    let declaration: String?
    let mark: String?
    let documentation: Documentation?
    let rawDocumentation: String?
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

        let rawComment = clang_Cursor_getRawCommentText(cursor).str()
        let replacements = [
            "@param ": "- parameter: ",
            "@return ": "- returns: ",
            "@warning ": "- warning: ",
            "@see ": "- see: ",
            "@note ": "- note: ",
        ]
        var varRawDocumentation = rawComment?.commentBody()
        for (original, replacement) in replacements {
            varRawDocumentation = varRawDocumentation?.stringByReplacingOccurrencesOfString(original, withString: replacement)
        }
        rawDocumentation = varRawDocumentation
        if let rawComment = rawComment where rawComment.containsString("@name") {
            let nsString = rawComment as NSString
            let regex = try! NSRegularExpression(pattern: "@name +(.*)", options: [])
            let range = NSRange(location: 0, length: nsString.length)
            let matches = regex.matchesInString(rawComment, options: [], range: range)
            if matches.count > 0 {
                mark = nsString.substringWithRange(matches[0].rangeAtIndex(1))
            }
            else {
                mark = nil
            }
        }
        else {
            mark = nil
        }

        location = cursor.location()
        type = ObjCDeclarationKind.fromClang(cursor.kind)
        usr = cursor.usr()
        if let usrNSString = usr as NSString? where type == .Category {
            let regex = try! NSRegularExpression(pattern: "(\\w+)@(\\w+)", options: [])
            let range = NSRange(location: 0, length: usrNSString.length)
            let matches = regex.matchesInString(usrNSString as String, options: [], range: range)
            if matches.count > 0 {
                let categoryOn = usrNSString.substringWithRange(matches[0].rangeAtIndex(1))
                let categoryName = usrNSString.substringWithRange(matches[0].rangeAtIndex(2))
                name = "\(categoryOn)(\(categoryName))"
            } else {
                name = cursor.name()
            }
        } else {
            if type == .MethodInstance {
                name = "-" + cursor.name()
            } else if type == .MethodClass {
                name = "+" + cursor.name()
            } else {
                name = cursor.name()
            }
        }
        let commentXML = String.fromCString(clang_getCString(clang_FullComment_getAsXML(clang_Cursor_getParsedComment(cursor)))) ?? ""
        guard let rootXML = SWXMLHash.parse(commentXML).children.first else {
            fatalError("couldn't parse XML")
        }
        declaration = rootXML["Declaration"].element?.text?
            .stringByReplacingOccurrencesOfString("\n@end", withString: "")
            .stringByReplacingOccurrencesOfString("@property(", withString: "@property (")
        documentation = Documentation(comment: comment)
        // Remove implicitly generated property getters & setters
        let tmpChildren = cursor.flatMap(SourceDeclaration.init)
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
        children = tmpChildren.filter { !propertyGetterSetterUSRs.contains($0.usr!) }
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
