# SourceKitten

An adorable little framework and command line tool for interacting with [SourceKit][uncovering-sourcekit].

SourceKitten links and communicates with `sourcekitd.framework` to parse the Swift AST, extract comment docs for Swift or Objective-C projects, get syntax data for a Swift file and lots more!

![Test Status](https://travis-ci.org/jpsim/SourceKitten.svg?branch=master)

## Installation

If you need to use SourceKitten with Swift 1.2, please use SourceKitten 0.4.5. For Swift 2.0, build from source from the `master` branch.

### Homebrew

Run `brew install sourcekitten`. Make sure that Xcode 6.4 is set in `xcode-select`.

### Source

Run `git clone` for this repo followed by `make install` in the root directory. Make sure that Xcode 7 Beta 6 is set in `xcode-select` before running `make`.

### Package

Download and open SourceKitten.pkg from the [releases tab](/jpsim/SourceKitten/releases).

## Command Line Usage

Once SourceKitten is installed, you may use it from the command line.

```
$ sourcekitten help
Available commands:

   complete    Generate code completion options.
   doc         Print Swift docs as JSON or Objective-C docs as XML
   help        Display general or command-specific help
   structure   Print Swift structure information as JSON
   syntax      Print Swift syntax information as JSON
   version     Display the current version of SourceKitten
```

## Complete

Running `sourcekitten complete --file file.swift --offset 123` or
`sourcekitten complete --text "0." --offset 2` will print out code completion
options for the offset in the file/text provided:

```json
[{
  "descriptionKey" : "advancedBy(n: Distance)",
  "associatedUSRs" : "s:FSi10advancedByFSiFSiSi s:FPSs21RandomAccessIndexType10advancedByuRq_S__Fq_Fqq_Ss16ForwardIndexType8Distanceq_ s:FPSs16ForwardIndexType10advancedByuRq_S__Fq_Fqq_S_8Distanceq_ s:FPSs10Strideable10advancedByuRq_S__Fq_Fqq_S_6Strideq_ s:FPSs11_Strideable10advancedByuRq_S__Fq_Fqq_S_6Strideq_",
  "kind" : "source.lang.swift.decl.function.method.instance",
  "sourcetext" : "advancedBy(<#T##n: Distance##Distance#>)",
  "context" : "source.codecompletion.context.thisclass",
  "typeName" : "Int",
  "moduleName" : "Swift",
  "name" : "advancedBy(n: Distance)"
},
{
  "descriptionKey" : "advancedBy(n: Self.Distance, limit: Self)",
  "associatedUSRs" : "s:FeRq_Ss21RandomAccessIndexType_SsS_10advancedByuRq_S__Fq_FTqq_Ss16ForwardIndexType8Distance5limitq__q_",
  "kind" : "source.lang.swift.decl.function.method.instance",
  "sourcetext" : "advancedBy(<#T##n: Self.Distance##Self.Distance#>, limit: <#T##Self#>)",
  "context" : "source.codecompletion.context.superclass",
  "typeName" : "Self",
  "moduleName" : "Swift",
  "name" : "advancedBy(n: Self.Distance, limit: Self)"
},
...
]
```

## Doc

Running `sourcekitten doc` will pass all arguments after what is parsed to
`xcodebuild` (or directly to the compiler, SourceKit/clang, in the
`--single-file` mode).

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

Running `sourcekitten syntax --file file.swift` or `sourcekitten syntax --text "import Foundation // Hello World"` will return a JSON array of syntax highlighting information:

```json
[
  {
    "offset" : 0,
    "length" : 6,
    "type" : "source.lang.swift.syntaxtype.keyword"
  },
  {
    "offset" : 7,
    "length" : 10,
    "type" : "source.lang.swift.syntaxtype.identifier"
  },
  {
    "offset" : 18,
    "length" : 14,
    "type" : "source.lang.swift.syntaxtype.comment"
  }
]
```

## License

MIT licensed.

[uncovering-sourcekit]: http://jpsim.com/uncovering-sourcekit
