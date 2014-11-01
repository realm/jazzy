## jazzy <sup>♪♫</sup>
**a soulful way to generate docs for Swift & Objective-C**
![analytics](https://ga-beacon.appspot.com/UA-50247013-2/jazzy/README?pixel)

jazzy is a command-line utility that generates documentation for your Swift or
Objective-C projects.

Only Swift projects are currently supported, but Objective-C support is coming
soon!

Instead of parsing your source files, jazzy hooks into [Clang][clang] and
[SourceKit][sourcekit] to use the [AST][ast] representation of your code and
its comments for more accurate results.

jazzy’s output matches the look & feel of Apple’s official reference
documentation, post WWDC 2014.

![Screenshot](screenshot.jpg)

### Requirements

* [Xcode 6.1][xcode], installed in `/Applications/Xcode.app`
* `xcode-select -p` should print Xcode 6.1's path. If it doesn't, run
`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

### Installing

To install jazzy, run `[sudo] gem install jazzy` from your command line.

### Usage

Run `jazzy` from your command line. Run `jazzy -h` for a list of additional
options.

### Design Goals

jazzy's main design goals are:

- Generate source code docs matching Apple's official reference documentation
- Support for standard Objective-C and Swift documentation comment syntax
- Leverage modern HTML templating ([Mustache][mustache])
- Leverage the power and accuracy of the [Clang AST][ast] and [SourceKit][sourcekit]
- Support for Xcode and Dash docsets (*work in progress*)
- Support Swift, Objective-C or mixed projects (*work in progress*)

### License

This project is under the MIT license.

[clang]: http://clang.llvm.org "Clang"
[sourcekit]: http://www.jpsim.com/uncovering-sourcekit "Uncovering SourceKit"
[ast]: http://clang.llvm.org/docs/IntroductionToTheClangAST.html "Introduction To The Clang AST"
[xcode]: https://developer.apple.com/xcode "Xcode"
[mustache]: http://mustache.github.io "Mustache"
