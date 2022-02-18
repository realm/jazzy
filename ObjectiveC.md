This document is about Jazzy's Objective-C documentation generation.

It's intended for users who are having problems after trying to follow the 
examples in the [README](README.md#objective-c). It gives some solutions to
common problems and explains how the system works to help users work through
uncommon problems.

* [How it works](#how-objective-c-docs-generation-works)
* Common problems:
    * [Apple SDK include failure](#problem-apple-sdk-importinclude-failure)
    * [Non-SDK include failure](#problem-non-sdk-include-failure)
    * [Argument list too long](#problem-argument-list-too-long-e2big-and-more)
    * [Enum cases with wrong doc comment](#problem-enum-cases-have-the-wrong-doc-comment)
    * [Swift API versions missing](#problem-swift-api-versions-are-all-missing)
    * [Swift API versions use `Any`](#problem-swift-api-versions-have-any-instead-of-type-name)
    * [Structural `NS_SWIFT_NAME` not working](#problem-structural-ns_swift_name-not-working)

# How Objective-C docs generation works

Jazzy uses `libclang` to generate docs for Objective-C projects. You can think
of this as running some parts of the `clang` compiler against a header file.
Jazzy refers to this header file as the _umbrella header_ but it does not have
to be the umbrella header from a Clang module: it's just the header file that
includes everything to be documented.

This means there are two problems to solve:
1. What `clang` flags are required; and
2. How to pass them to the tools.

Jazzy has two modes here: a smart mode that covers 90% of projects and a direct mode where the user provides all the flags.

> *Important*: Jazzy does _not_ use any Objective-C build settings from your
  Xcode project or `Package.swift`. If your project needs special settings
  such as `#define`s then you need to repeat those in the Jazzy invocation.

## Direct mode

Passing a basic set of `clang` flags looks like this:

```shell
jazzy ...
      --objc
      --build-tool-arguments
          --objc,MyProject/MyProject.h,--,-x,objective-c,
          -isysroot,$(xcrun --show-sdk-path),
          -I,$(pwd),
          -fmodules
```
The `--build-tool-arguments` are arguments to `sourcekitten`. Everything after
the `--` are the `clang` flags that will be used with the header file given 
before the `--`.

You can try these flags outside of Jazzy's environment:
```shell
clang -c -x objective-c -isysroot $(xcrun --show-sdk-path) -I $(pwd) MyProject/MyProject.h -fmodules
```
(The `-c` stops `clang` from trying to link an executable.)

This is a good method of experimenting with compiler flags to get a working
build without getting bogged down in the Jazzy and SourceKitten layers.

## Smart mode

The smart mode takes the variable parts of the basic set of flags and maps
them from Jazzy flags:
```shell
jazzy ...
      --objc
      --umbrella-header MyProject/MyProject.h
      --framework-root $(pwd)
     [--sdk <sdk name>]
```

The `--umbrella-header` maps directly to the file passed to `sourcekitten`.

The `--framework-root` is used for the `-I` include path, as well as every
directory beneath it, recursively. So if your project structure looks like:
```
MyProject/
         Sources/
                Main/
                Extension/
```
... and you pass `--framework-root MyProject`, then the `-I` flags passed to
`clang` are `-I MyProject -I MyProject/Sources -I MyProject/Sources/Main -I
MyProject/Sources/Extension`. This feature helps some projects resolve
`#include` directives.

Finally the `--sdk` option is passed through instead of the default `macosx` to
find the SDK.

## Mixing modes

Do not mix modes. For example do not set both `--umbrella-header` and
`--build-tool-arguments`. Jazzy does not flag this as an error for
historical compatibility reasons, but the results are at best confusing.

# Problem: Apple SDK import/include failure

For example `fatal error: module 'UIKit' not found`.

This means Jazzy is using the wrong SDK: the default is for macOS which does
not have `UIKit`. Use `--sdk iphonesimulator`.

# Problem: Non-SDK include failure

For example `fatal error: 'MyModule/SomeHeader.h' file not found`.

This means `clang` is not being passed the right flags to resolve a `#include` /
`#import`.

Start by finding the header file in the filesystem. You might be able to fix
the problem just by adding extra `-I <path>` flags.

Usually though the problem is that Xcode has done something clever that needs
to be worked around or replicated.

Xcode uses technology including Clang header maps to let files be found using
lines like `#import <ModuleName/Header.h>` even when there is no such
filesystem directory.

To make the Jazzy build work you need to make these `#include`s work. The
solution depends on your project structure. Some suggestions in rough order
of complexity:
* Use symlinks to create an equivalent directory tree. For example if
  `Header.h` is inside `Sources/include` then symlink that directory to
  `ModuleName` and pass `-I $(pwd)`.

* Copy/link your header files into a throwaway directory tree that matches
  the required structure and is used just for building docs.

* Create a 'docs header file' separate to the framework's regular umbrella
  header that contains only filesystem-correct `#import`s.

* If you are happy to build the framework project before generating docs and
  all the problematic paths have the form `ModuleName/PublicHeader.h` then
  have `clang` resolve those includes to the built framework by passing
  `-F <path of directory containing ModuleName.framework>`.

* If you are happy to build the project before generating docs then you may
  be able to use the header maps Xcode has generated. Check the build log in
  Xcode to find them and the invocation syntax.

* Manually construct an equivalent header map. This is complex not least
  because Apple does not make tools or proper documentation available.
  [An open-source starting point](https://milen.me/writings/swift-module-maps-vfs-overlays-header-maps/).

# Problem: Argument list too long `E2BIG` (and more...)

For example ``...open4.rb:49:in `exec': Argument list too long - [...]/bin/sourcekitten (Errno::E2BIG)``

Can also manifest as 'generally weird' errors such as `sourcekitten` just
crashing and `fatal error: could not build module 'Foundation'`.

This means `--framework-root` is trying to add too many include directories:
there are too many subdirectories of its parameter. If you cannot change this
to something more specific that works then you need to use Jazzy's
[direct mode](#direct-mode) to pass in the correct directories.

# Problem: Enum cases have the wrong doc comment

If you write an enum case with a doc comment followed by an enum case without
a doc comment, then both get the same doc comment.

This seems to be a bug in `libclang`. The only workaround is to add the missing
doc comment.

# Problem: Swift API versions are all missing

This usually means the `clang` flags are malformed in a way that is ignored by
`libclang` but not by the Swift Objective-C importer.

One easy way to accidentally do this is passing `-I` without a path, for
example `--build-tool-flags ...,-I,-I,Headers`,....

This also sometimes happens if you are frequently switching back and forth
between some Swift / Xcode versions -- it's a bug somewhere in the Apple tools.
The bad state goes away with time / reboot.

# Problem: Swift API versions have `Any` instead of type name

Jazzy finds the Swift version of an Objective-C API using the SourceKit
`source.request.editor.open.interface.header` request on the header file that
contains the declaration, passing in the same `clang` flags used for the
umbrella header. [See the code](https://github.com/jpsim/SourceKitten/blob/bed112c313ca8c3c149f8cb84069f1c080e86a7e/Source/SourceKittenFramework/Clang%2BSourceKitten.swift#L202).

This means that each header file needs to compile standalone, without
any implicit dependencies. For example:
```
 MyModule.h      // umbrella, includes MyClass.h then Utils.h
    MyClass.h    // @interface MyClass ... @end
    Utils.h      // void my_function( MyClass * myClass);
```
Here, `Utils.h` has an implicit dependency on `MyClass.h` that is normally
satisfied by the include order of `MyModule.h`. One fix that allows `Utils.h`
to compile standalone is to add `@class MyClass;`.

# Problem: Structural `NS_SWIFT_NAME` not working

The `NS_SWIFT_NAME` macro is mostly used to give an Objective-C API a
different name in Swift. There are no known problems with this part.

The macro can also be used to change the 'structure' of an API, for example
make a C global function appear as a member function in Swift, or make a C
class appear as a nested type in Swift.

Jazzy doesn't understand or communicate these structural changes: you'll need
to explain it in doc comments.
