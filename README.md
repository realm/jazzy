# SourceKitten

An adorable little framework and command line tool for interacting with [SourceKit][uncovering-sourcekit].

SourceKitten links and communicates with `sourcekitd.framework` to parse the Swift AST, extract comment docs for Swift or Objective-C projects, get syntax data for a Swift file and lots more!

![Test Status](https://travis-ci.org/jpsim/sourcekitten.svg?branch=master)

## Command Line Usage

Install the `sourcekitten` command line tool by running `make install`, first making sure that Xcode 6.1 is set in `xcode-select`.

By default, SourceKitten will use the copy of `sourcekitd.framework` under `/Applications/Xcode.app` (preferrably Xcode 6.1 or later).

```
$ sourcekitten help
Available commands:

   doc         Print Swift docs as JSON or Objective-C docs as XML
   help        Display general or command-specific help
   structure   Print Swift structure information as JSON
   syntax      Print Swift syntax information as JSON
   version     Display the current version of SourceKitten
```

## Doc

Calling `sourcekitten doc` will pass all arguments after what is parsed to `xcodebuild` (or directly to the compiler, SourceKit/clang, if the `--single-file` mode).

### Example usage

1. `sourcekitten doc -workspace SourceKitten.xcworkspace -scheme SourceKittenFramework`
2. `sourcekitten doc --single-file file.swift -j4 file.swift`
3. `sourcekitten doc --module-name Alamofire -project Alamofire.xcodeproj`
4. `sourcekitten doc -workspace Haneke.xcworkspace -scheme Haneke`
5. `sourcekitten doc --objc Realm/*.h*`

## Structure

Running `sourcekitten structure --file file.swift` or `sourcekitten structure --text "struct A { func b() {} }"` will return a JSON array of structure information:

```json
{
  "key.substructure" : [
    {
      "key.kind" : "source.lang.swift.decl.struct",
      "key.offset" : 0,
      "key.nameoffset" : 7,
      "key.namelength" : 1,
      "key.bodyoffset" : 10,
      "key.bodylength" : 13,
      "key.length" : 24,
      "key.substructure" : [
        {
          "key.kind" : "source.lang.swift.decl.function.method.instance",
          "key.offset" : 11,
          "key.nameoffset" : 16,
          "key.namelength" : 3,
          "key.bodyoffset" : 21,
          "key.bodylength" : 0,
          "key.length" : 11,
          "key.substructure" : [

          ],
          "key.name" : "b()"
        }
      ],
      "key.name" : "A"
    }
  ],
  "key.offset" : 0,
  "key.diagnostic_stage" : "source.diagnostic.stage.swift.parse",
  "key.length" : 24
}
```

## Syntax

Running `sourcekitten syntax --file file.swift` or `sourcekitten syntax --text "import Foundation"` will return a JSON array of syntax highlighting information:

```json
[
  {
    "type": "source.lang.swift.syntaxtype.comment",
    "offset": 0,
    "length": 14
  },
  {
    "type": "source.lang.swift.syntaxtype.keyword",
    "offset": 14,
    "length": 6
  },
  {
    "type": "source.lang.swift.syntaxtype.identifier",
    "offset": 21,
    "length": 10
  }
]
```

## License

MIT licensed.

[uncovering-sourcekit]: http://jpsim.com/uncovering-sourcekit
