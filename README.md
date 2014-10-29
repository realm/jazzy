# sourcekitten

An adorable little command line tool for interacting with [SourceKit][uncovering-sourcekit]. Written in Swift.

## Usage

Just call `sourcekitten` in the root of your Xcode project's directory. Some more complex projects may have to pass in `-project`, `-workspace`, `-scheme` or other `xcodebuild` arguments to help sourcekitten determine what to document.

Install it by running `sh install.sh`, first making sure that Xcode 6.1 is set in `xcode-select`.

By default, sourcekitten will use the copy of `sourcekitd.framework` under `/Applications/Xcode.app` (preferrably Xcode 6.1 or later).

## How it works

sourcekitten links and communicates with `sourcekitd.framework` to generate parsable docs in an XML format for your Swift projects or print syntax highlighting information for a Swift file.

## Syntax Highlighting

Calling `sourcekitten --syntax /absolute/path/to/file.swift` will return a JSON array of syntax highlighting information:

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
