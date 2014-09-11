# SourceKitten

***Work In Progress: Only use for research purposes for now. Requires Xcode 6 GM.***

An adorable little command line tool for interacting with [SourceKit][uncovering-sourcekit].

## Usage

```
Usage: SourceKitten [--swift_file swift_file_path] [--file objc_header_path] [--module module_name --framework_dir /absolute/path/to/framework] [--help]
```

## How it works

SourceKitten links and communicates with `sourcekitd.framework`, exposing SourceKit XPC calls through traditional method calls.

## License

MIT licensed.

[uncovering-sourcekit]: http://jpsim.com/uncovering-sourcekit
