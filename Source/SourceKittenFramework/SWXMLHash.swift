//
//  SWXMLHash.swift
//
//  Copyright (c) 2014 David Mohundro
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

let rootElementName = "SWXMLHash_Root_Element"

/// Simple XML parser.
public class SWXMLHash {
    /**
    Method to parse XML passed in as a string.

    :param: xml The XML to be parsed

    :returns: An XMLIndexer instance that is used to look up elements in the XML
    */
    class public func parse(xml: String) -> XMLIndexer {
        return parse((xml as NSString).dataUsingEncoding(NSUTF8StringEncoding)!)
    }

    /**
    Method to parse XML passed in as an NSData instance.

    :param: xml The XML to be parsed

    :returns: An XMLIndexer instance that is used to look up elements in the XML
    */
    class public func parse(data: NSData) -> XMLIndexer {
        var parser = XMLParser()
        return parser.parse(data)
    }
}

struct Stack<T> {
    var items = [T]()
    mutating func push(item: T) {
        items.append(item)
    }
    mutating func pop() -> T {
        return items.removeLast()
    }
    mutating func removeAll() {
        items.removeAll(keepCapacity: false)
    }
    func top() -> T {
        return items[items.count - 1]
    }
}

/// The implementation of NSXMLParserDelegate and where the parsing actually happens.
class XMLParser : NSObject, NSXMLParserDelegate {
    override init() {
        super.init()
    }

    var root = XMLElement(name: rootElementName)
    var parentStack = Stack<XMLElement>()

    func parse(data: NSData) -> XMLIndexer {
        // clear any prior runs of parse... expected that this won't be necessary, but you never know
        parentStack.removeAll()

        parentStack.push(root)

        let parser = NSXMLParser(data: data)
        parser.delegate = self
        parser.parse()

        return XMLIndexer(root)
    }

    func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName: String!, attributes attributeDict: NSDictionary!) {

        let currentNode = parentStack.top().addElement(elementName, withAttributes: attributeDict)
        parentStack.push(currentNode)
    }

    func parser(parser: NSXMLParser!, foundCharacters string: String!) {
        let current = parentStack.top()
        if current.text? == nil {
            current.text = ""
        }

        parentStack.top().text! += string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }

    func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        parentStack.pop()
    }
}

/// Returned from SWXMLHash, allows easy element lookup into XML data.
public enum XMLIndexer : SequenceType {
    case Element(XMLElement)
    case List([XMLElement])
    case Error(NSError)

    /// The underlying XMLElement at the currently indexed level of XML.
    public var element: XMLElement? {
        get {
            switch self {
            case .Element(let elem):
                return elem
            default:
                return nil
            }
        }
    }

    /// All elements at the currently indexed level
    public var all: [XMLIndexer] {
        get {
            switch self {
            case .List(let list):
                var xmlList = [XMLIndexer]()
                for elem in list {
                    xmlList.append(XMLIndexer(elem))
                }
                return xmlList
            case .Element(let elem):
                return [XMLIndexer(elem)]
            default:
                return []
            }
        }
    }

    /// All child elements from the currently indexed level
    public var children: [XMLIndexer] {
        get {
            var list = [XMLIndexer]()
            for elem in all.map({ $0.element! }) {
                for elem in elem.children {
                    list.append(XMLIndexer(elem))
                }
            }
            return list
        }
    }

    /**
    Allows for element lookup by matching attribute values.

    :param: attr should the name of the attribute to match on
    :param: _ should be the value of the attribute to match on

    :returns: instance of XMLIndexer
    */
    public func withAttr(attr: String, _ value: String) -> XMLIndexer {
        let attrUserInfo = [NSLocalizedDescriptionKey: "XML Attribute Error: Missing attribute [\"\(attr)\"]"]
        let valueUserInfo = [NSLocalizedDescriptionKey: "XML Attribute Error: Missing attribute [\"\(attr)\"] with value [\"\(value)\"]"]
        switch self {
        case .List(let list):
            if let elem = list.filter({$0.attributes[attr] == value}).first {
                return .Element(elem)
            }
            return .Error(NSError(domain: "SWXMLDomain", code: 1000, userInfo: valueUserInfo))
        case .Element(let elem):
            if let attr = elem.attributes[attr] {
                if attr == value {
                    return .Element(elem)
                }
                return .Error(NSError(domain: "SWXMLDomain", code: 1000, userInfo: valueUserInfo))
            }
            return .Error(NSError(domain: "SWXMLDomain", code: 1000, userInfo: attrUserInfo))
        default:
            return .Error(NSError(domain: "SWXMLDomain", code: 1000, userInfo: attrUserInfo))
        }
    }

    /**
    Initializes the XMLIndexer

    :param: _ should be an instance of XMLElement, but supports other values for error handling

    :returns: instance of XMLIndexer
    */
    public init(_ rawObject: AnyObject) {
        switch rawObject {
        case let value as XMLElement:
            self = .Element(value)
        default:
            self = .Error(NSError(domain: "SWXMLDomain", code: 1000, userInfo: nil))
        }
    }

    /**
    Find an XML element at the current level by element name

    :param: key The element name to index by

    :returns: instance of XMLIndexer to match the element (or elements) found by key
    */
    public subscript(key: String) -> XMLIndexer {
        get {
            let userInfo = [NSLocalizedDescriptionKey: "XML Element Error: Incorrect key [\"\(key)\"]"]
            switch self {
            case .Element(let elem):
                let match = elem.children.filter({ $0.name == key })
                if match.count > 0 {
                    if match.count == 1 {
                        return .Element(match[0])
                    }
                    else {
                        return .List(match)
                    }
                }
                return .Error(NSError(domain: "SWXMLDomain", code: 1000, userInfo: userInfo))
            default:
                return .Error(NSError(domain: "SWXMLDomain", code: 1000, userInfo: userInfo))
            }
        }
    }

    /**
    Find an XML element by index within a list of XML Elements at the current level

    :param: index The 0-based index to index by

    :returns: instance of XMLIndexer to match the element (or elements) found by key
    */
    public subscript(index: Int) -> XMLIndexer {
        get {
            let userInfo = [NSLocalizedDescriptionKey: "XML Element Error: Incorrect index [\"\(index)\"]"]
            switch self {
            case .List(let list):
                if index <= list.count {
                    return .Element(list[index])
                }
                return .Error(NSError(domain: "SWXMLDomain", code: 1000, userInfo: userInfo))
            case .Element(let elem):
                if index == 0 {
                    return .Element(elem)
                }
                else {
                    return .Error(NSError(domain: "SWXMLDomain", code: 1000, userInfo: userInfo))
                }
            default:
                return .Error(NSError(domain: "SWXMLDomain", code: 1000, userInfo: userInfo))
            }
        }
    }

    typealias GeneratorType = XMLIndexer

    public func generate() -> IndexingGenerator<[XMLIndexer]> {
        return all.generate()
    }
}

/// XMLIndexer extensions
extension XMLIndexer: BooleanType {
    /// True if a valid XMLIndexer, false if an error type
    public var boolValue: Bool {
        get {
            switch self {
            case .Error:
                return false
            default:
                return true
            }
        }
    }
}

extension XMLIndexer: Printable {
    public var description: String {
        get {
            switch self {
            case .List(let list):
                return "\n".join(list.map { $0.description })
            case .Element(let elem):
                if elem.name == rootElementName {
                    return "\n".join(elem.children.map { $0.description })
                }

                return elem.description
            default:
                return ""
            }
        }
    }
}

/// Models an XML element, including name, text and attributes
public class XMLElement {
    /// The name of the element
    public let name: String
    /// The inner text of the element, if it exists
    public var text: String?
    /// The attributes of the element
    public var attributes = [String:String]()

    var children = [XMLElement]()
    var count: Int = 0
    var index: Int

    /**
    Initialize an XMLElement instance

    :param: name The name of the element to be initialized

    :returns: a new instance of XMLElement
    */
    init(name: String, index: Int = 0) {
        self.name = name
        self.index = index
    }

    /**
    Adds a new XMLElement underneath this instance of XMLElement

    :param: name The name of the new element to be added
    :param: withAttributes The attributes dictionary for the element being added

    :returns: The XMLElement that has now been added
    */
    func addElement(name: String, withAttributes attributes: NSDictionary) -> XMLElement {
        let element = XMLElement(name: name, index: count)
        count++

        children.append(element)

        for (keyAny,valueAny) in attributes {
            let key = keyAny as String
            let value = valueAny as String
            element.attributes[key] = value
        }

        return element
    }
}

extension XMLElement: Printable {
    public var description:String {
        get {
            var attributesStringList = [String]()
            if !attributes.isEmpty {
                for (key, val) in attributes {
                    attributesStringList.append("\(key)=\"\(val)\"")
                }
            }

            var attributesString = " ".join(attributesStringList)
            if (!attributesString.isEmpty) {
                attributesString = " " + attributesString
            }

            if children.count > 0 {
                var xmlReturn = [String]()
                xmlReturn.append("<\(name)\(attributesString)>")
                for child in children {
                    xmlReturn.append(child.description)
                }
                xmlReturn.append("</\(name)>")
                return "\n".join(xmlReturn)
            }

            if text != nil {
                return "<\(name)\(attributesString)>\(text!)</\(name)>"
            }
            else {
                return "<\(name)\(attributesString)/>"
            }
        }
    }
}
