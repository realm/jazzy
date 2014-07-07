# Building jazzy

jazzy is composed of two parts: the parser (written in C++) and the site generator (written in ruby). This guide will allow you to build both components.

## Requirements

* [Xcode 6 (Beta 2)](https://developer.apple.com/xcode)
* `xcode-select -p` should print Xcode 6's path. If it doesn't, run `sudo xcode-select -s /Applications/Xcode6-Beta2.app/Contents/Developer`
* [bundler](http://rubygems.org/gems/bundler)

## Building ASTDump

Unlike many other tools built using Clang, ASTDump doesn't require building the entirety of LLVM and Clang from source. Instead, ASTDump links against libclang, so builds take seconds, not hours.

To build ASTDump, open `parser/ASTDump.xcodeproj` and hit `⌘+B`.

Then, move the resulting ASTDump binary to `bin/ASTDump`. This will make it available to the site generator portion of jazzy.

## Building & Running jazzy

Run `bundle install` from the command line. This will install all the gems required to run jazzy.

To run jazzy locally, use the following command: `ruby -Ilib bin/jazzy`. This instructs ruby to load the local `lib` directory, which will cause jazzy to find all its necessary file dependencies.
