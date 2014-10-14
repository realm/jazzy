# SourceKitten

***Work In Progress: Only use for research purposes for now. Requires Xcode 6.1 GM 2.***

An adorable little command line tool for interacting with [SourceKit][uncovering-sourcekit].

## Usage

Just call `SourceKitten` in the root of your Xcode project's directory. Some more complex projects may have to pass in `-project`, `-workspace`, `-scheme` or other `xcodebuild` arguments to help SourceKitten determine what to document.

Install it by running `sh install.sh`, first making sure that Xcode6.1-GM2 is set in `xcode-select`.

## How it works

SourceKitten links and communicates with `sourcekitd.framework` to generate parsable docs in an XML format for your Swift projects.

## License

MIT licensed.

[uncovering-sourcekit]: http://jpsim.com/uncovering-sourcekit
