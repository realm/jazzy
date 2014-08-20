# SourceKitten

***Work In Progress: Only use for research purposes for now. Requires Xcode6-Beta6.***

An adorable little framework for interacting with [SourceKit][uncovering-sourcekit].

## Usage

To use SourceKitten in your OSX project, drag `SourceKitten.framework` into your project, link it and add it to your target's Copy Files build phase.

## How it works

SourceKitten links and communicates with `sourcekitd.framework`, exposing SourceKit XPC calls through traditional method calls.

## License

MIT licensed.

[uncovering-sourcekit]: http://jpsim.com/uncovering-sourcekit
