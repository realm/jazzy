![jazzy](images/logo.jpg)

[![Build Status](https://github.com/realm/jazzy/actions/workflows/Tests.yml/badge.svg)](https://github.com/realm/jazzy/actions/workflows/Tests.yml)

*jazzy is a command-line utility that generates documentation for Swift or Objective-C*

## About

Both Swift and Objective-C projects are supported.

Instead of parsing your source files, `jazzy` hooks into [Clang][clang] and
[SourceKit][sourcekit] to use the [AST][ast] representation of your code and
its comments for more accurate results. The output matches the look and feel
of Apple’s official reference documentation, post WWDC 2014.

Jazzy can also generate documentation from compiled Swift modules [using their
symbol graph](#docs-from-swiftmodules-or-frameworks) instead of source code.

![Screenshot](images/screenshot.jpg)

This project adheres to the [Contributor Covenant Code of Conduct](https://realm.io/conduct).
By participating, you are expected to uphold this code. Please report
unacceptable behavior to [info@realm.io](mailto:info@realm.io).

## Requirements

You need development tools to build the project you wish to document.  Jazzy supports
both [Xcode][xcode] and [Swift Package Manager][spm] projects.

Jazzy expects to be running on __macOS__.  See [below](#linux) for tips to run Jazzy
on Linux.

## Installation

```shell
[sudo] gem install jazzy
```

See [Installation Problems](#installation-problems) for solutions to some
common problems.

## Usage

Run `jazzy` from your command line. Run `jazzy -h` for a list of additional options.

If your Swift module is the first thing to build, and it builds fine when running
`xcodebuild` or `swift build` without any arguments from the root of your project, then
just running `jazzy` (without any arguments) from the root of your project should
succeed too!

If Jazzy generates docs for the wrong module then use `--module` to tell it which
one you'd prefer.  If this doesn't help, and you're using Xcode, then try passing
extra arguments to `xcodebuild`, for example
`jazzy --build-tool-arguments -scheme,MyScheme,-target,MyTarget`.

You can set options for your project’s documentation in a configuration file,
`.jazzy.yaml` by default. For a detailed explanation and an exhaustive list of
all available options, run `jazzy --help config`.

### Supported documentation keywords

Swift documentation is written in markdown and supports a number of special keywords.
Here are some resources with tutorials and examples, starting with the most modern:
* Apple's [Writing Symbol Documentation in Your Source Files](https://developer.apple.com/documentation/xcode/writing-symbol-documentation-in-your-source-files) article.
* Apple's [Formatting Your Documentation Content](https://developer.apple.com/documentation/xcode/formatting-your-documentation-content) article.
* Apple's [Xcode Markup Formatting Reference](https://developer.apple.com/library/content/documentation/Xcode/Reference/xcode_markup_formatting_ref/).
* Erica Sadun's [Swift header documentation in Xcode 7](https://ericasadun.com/2015/06/14/swift-header-documentation-in-xcode-7/) post and her [book on Swift Documentation Markup](https://itunes.apple.com/us/book/swift-documentation-markup/id1049010423).

For Objective-C documentation the same keywords are supported, but note that the format
is slightly different. In Swift you would write `- returns:`, but in Objective-C you write `@return`. See Apple's [*HeaderDoc User Guide*](https://developer.apple.com/legacy/library/documentation/DeveloperTools/Conceptual/HeaderDoc/tags/tags.html) for more details. **Note: `jazzy` currently does not support _all_ Objective-C keywords listed in this document, only @param, @return, @warning, @see, @note, @code, @endcode, and @c.**

Jazzy can also generate cross-references within your documentation. A symbol name in
backticks generates a link, for example:
* \`MyClass\` - a link to documentation for `MyClass`.
* \`MyClass.method(param1:)\` - a link to documentation for that method.
* \`MyClass.method(...)\` - shortcut syntax for the same thing.
* \`method(...)\` - shortcut syntax to link to `method` from the documentation of another
  method or property in the same class.
* \`[MyClass method1]\` - a link to an Objective-C method.
* \`-[MyClass method2:param1]\` - a link to another Objective-C method.

Jazzy understands Apple's DocC-style links too, for example:
* \`\`MyClass/method(param1:)\`\` - a link to the documentation for that method
  that appears as just `method(param1:)` in the rendered page.
* \`\`\<doc:method(_:)-e873\>\`\` - a link to a specific overload of `method(_:)`.
  Jazzy can't tell which overload you intend and links to the first one.

### Math

Jazzy can render math equations written in LaTeX embedded in your markdown:
* `` `$equation$` `` renders the equation in an inline style.
* `` `$$equation$$` `` renders the equation in a display style, centered on a
  line of its own.

For example, the markdown:
```markdown
Inline: `$ax^2+bx+c=0$`

Block: `$$x={\frac {-b\pm {\sqrt {b^{2}-4ac}}}{2a}}$$`
```
..renders as:

![math](images/math.png)

Math support is provided by [KaTeX](https://katex.org).

### Swift

Swift documentation is generated by default.

##### Example

This is how Realm Swift docs are generated:

```shell
jazzy \
  --clean \
  --author Realm \
  --author_url https://realm.io \
  --source-host github \
  --source-host-url https://github.com/realm/realm-cocoa \
  --source-host-files-url https://github.com/realm/realm-cocoa/tree/v0.96.2 \
  --module-version 0.96.2 \
  --build-tool-arguments -scheme,RealmSwift \
  --module RealmSwift \
  --root-url https://realm.io/docs/swift/0.96.2/api/ \
  --output docs/swift_output \
  --theme docs/themes
```

This is how docs are generated for a project that uses the Swift Package Manager:

```shell
jazzy \
  --module DeckOfPlayingCards \
  --swift-build-tool spm \
  --build-tool-arguments -Xswiftc,-swift-version,-Xswiftc,5
```

### Objective-C

To generate documentation for a simple Objective-C project, you must pass the
following parameters:
* `--objc`
* `--umbrella-header ...`
* `--framework-root ...`

...and optionally:
* `--sdk [iphone|watch|appletv][os|simulator]|macosx` (default value
   of `macosx`)
* `--hide-declarations [objc|swift]` (hides the selected language declarations)

For example, this is how the `AFNetworking` docs are generated:

```shell
jazzy \
  --objc \
  --author AFNetworking \
  --author_url http://afnetworking.com \
  --source-host github \
  --source-host-url https://github.com/AFNetworking/AFNetworking \
  --source-host-files-url https://github.com/AFNetworking/AFNetworking/tree/2.6.2 \
  --module-version 2.6.2 \
  --umbrella-header AFNetworking/AFNetworking.h \
  --framework-root . \
  --module AFNetworking
```

For a more complicated Objective-C project, instead use `--build-tool-arguments`
to pass arbitrary compiler flags.  For example, this is how Realm Objective-C
docs are generated:

```shell
jazzy \
  --objc \
  --clean \
  --author Realm \
  --author_url https://realm.io \
  --source-host github \
  --source-host-url https://github.com/realm/realm-cocoa \
  --source-host-files-url https://github.com/realm/realm-cocoa/tree/v2.2.0 \
  --module-version 2.2.0 \
  --build-tool-arguments --objc,Realm/Realm.h,--,-x,objective-c,-isysroot,$(xcrun --show-sdk-path),-I,$(pwd) \
  --module Realm \
  --root-url https://realm.io/docs/objc/2.2.0/api/ \
  --output docs/objc_output \
  --head "$(cat docs/custom_head.html)"
```

See [the Objective-C docs](ObjectiveC.md) for more information and some tips
on troubleshooting.

### Mixed Objective-C / Swift

*This feature is new and has some rough edges.*

To generate documentation for a mixed Swift and Objective-C project you must first
generate two [SourceKitten][sourcekitten] files: one for Swift and one for Objective-C.

Then pass these files to Jazzy together using `--sourcekitten-sourcefile`.

#### Example

This is how docs are generated from an Xcode project for a module containing both
Swift and Objective-C files:

```shell
# Generate Swift SourceKitten output
sourcekitten doc -- -workspace MyProject.xcworkspace -scheme MyScheme > swiftDoc.json

# Generate Objective-C SourceKitten output
sourcekitten doc --objc $(pwd)/MyProject/MyProject.h \
      -- -x objective-c  -isysroot $(xcrun --show-sdk-path --sdk iphonesimulator) \
      -I $(pwd) -fmodules > objcDoc.json

# Feed both outputs to Jazzy as a comma-separated list
jazzy --module MyProject --sourcekitten-sourcefile swiftDoc.json,objcDoc.json
```

### Docs from `.swiftmodule`s or frameworks

*This feature is new: there may be crashes and mistakes. Reports welcome.*

Swift 5.3 added support for symbol graph generation from `.swiftmodule` files.

Jazzy can use this to generate API documentation.  This is faster than using
the source code directly but does have limitations: for example documentation
comments are available only for `public` declarations, and the presentation of
Swift extensions may not match the way they are written in code.

Some examples:

1. Generate docs for the Apple Combine framework for macOS:
   ```shell
   jazzy --module Combine --swift-build-tool symbolgraph
   ```
   The SDK's library directories are included in the search path by
   default.
2. Same but for iOS:
   ```shell
   jazzy --module Combine --swift-build-tool symbolgraph
         --sdk iphoneos
         --build-tool-arguments -target,arm64-apple-ios14.1
   ```
   The `target` is the LLVM target triple and needs to match the SDK.  The
   default here is the target of the host system that Jazzy is running on,
   something like `x86_64-apple-darwin19.6.0`.
3. Generate docs for a personal `.swiftmodule`:
   ```shell
   jazzy --module MyMod --swift-build-tool symbolgraph
         --build-tool-arguments -I,/Build/Products
   ```
   This implies that `/Build/Products/MyMod.swiftmodule` exists.  Jazzy's
   `--source-directory` (default current directory) is searched by default,
   so you only need the `-I` override if that's not enough.
4. For a personal framework:
   ```shell
   jazzy --module MyMod --swift-build-tool symbolgraph
         --build-tool-arguments -F,/Build/Products
   ```
   This implies that `/Build/Products/MyMod.framework` exists and contains
   a `.swiftmodule`.  Again the `--source-directory` is searched by default
   if `-F` is not passed in.
5. With pre-generated symbolgraph files:
    ```shell
    jazzy --module MyMod --swift-build-tool symbolgraph
          --symbolgraph-directory Build/symbolgraphs
    ```
    If you've separately generated symbolgraph files by the use of 
    `-emit-symbol-graph`, you can pass the location of these files using
    `--symbolgraph-directory` from where they can be parsed directly.

See `swift symbolgraph-extract -help` for all the things you can pass via
`--build-tool-arguments`: if your module has dependencies then you may need
to add various search path options to let Swift load it.

### Themes

Three themes are provided with jazzy: `apple` (default), `fullwidth` and `jony`.

* `apple` example: <https://realm.io/docs/swift/latest/api/>
* `fullwidth` example: <https://reduxkit.github.io/ReduxKit/>
* `jony` example: <https://harshilshah.github.io/IGListKit/>

You can specify which theme to use by passing in the `--theme` option. You can
also provide your own custom theme by passing in the path to your theme
directory.

### Guides

| Description | Command |
| ---         | ---     |
| Command line option | `--documentation={file pattern}` |
| Example             | `--documentation=Docs/*.md` |
| jazzy.yaml example  | `documentation: Docs/*.md` |

By default, jazzy looks for one of README.md, README.markdown, README.mdown or README (in that order) in the directory from where it runs to render the index page at the root of the docs output directory.
Using the `--documentation` option, extra markdown files can be integrated into the generated docs and sidebar navigation.

Any files found matching the file pattern will be parsed and included as a document with the type 'Guide' when generated. If the files are not included using the `custom_categories` config option, they will be grouped under 'Other Guides' in the sidebar navigation.

There are a few limitations:
- File names must be unique from source files.
- Readme should be specified separately using the `readme` option.

### Section description abstracts

| Description | Command |
| ---         | ---     |
| Command line option | `--abstract={file pattern}` |
| Example             | `--abstract=Docs/Sections/*.md` |
| jazzy.yaml example  | `abstract: Docs/Sections/*.md` |

Using the `--abstract` options, extra markdown can be included after the heading of section overview pages. Think of it as a template include.

The list of files matching the pattern is compared against the list of sections generated and if a match is found, it's contents will be included in that section before listing source output.

Unlike the `--documentation` option, these files are not included in navigation and if a file does not match a section title, it is not included at all.

This is very helpful when using `custom_categories` for grouping types and including relevant documentation in those sections.

For an example of a project using both `--documentation` and `--abstract` see: [https://reswift.github.io/ReSwift/](https://reswift.github.io/ReSwift/)

### Controlling what is documented

In Swift mode, Jazzy by default documents only `public` and `open` declarations. To
include declarations with a lower access level, set the `--min-acl` flag to `internal`,
`fileprivate`, or `private`.

By default, Jazzy does not document declarations marked `@_spi` when `--min-acl` is
set to `public` or `open`.  Set the `--include-spi-declarations` flag to include them.

In Objective-C mode, Jazzy documents all declarations found in the `--umbrella-header`
header file and any other header files included by it.

You can control exactly which declarations should be documented using `--exclude`,
`--include`, or `:nodoc:`.

The `--include` and `--exclude` flags list source files that should be included/excluded
respectively in the documentation. Entries in the list can be absolute pathnames beginning
with `/` or relative pathnames. Relative pathnames are interpreted relative to the
directory from where you run `jazzy` or, if the flags are set in the config file, relative
to the directory containing the config file. Entries in the list can match multiple files
using `*` to match any number of characters including `/`.  For example:
* `jazzy --include=/Users/fred/project/Sources/Secret.swift` -- include a specific file
* `jazzy --exclude=/*/Internal*` -- exclude all files with names that begin with *Internal*
  and any files under any directory with a name beginning *Internal*.
* `jazzy --exclude=Impl1/*,Impl2/*` -- exclude all files under the directories *Impl1* and
  *Impl2* found in the current directory.

Note that the `--include` option is applied before the `--exclude` option. For example:

* `jazzy --include=/*/Internal* --exclude=Impl1/*,Impl2/*` -- include all files with names
  that begin with *Internal* and any files under any directory with a name beginning
  *Internal*, **except** for those under the directories *Impl1* and *Impl2* found in the
  current directory

Declarations with a documentation comment containing `:nodoc:` are excluded from the
documentation.

Declarations with the `@_documentation(visibility:)` attribute are treated as though they
are written with the given visibility.  You can use this as a replacement for `:nodoc:` as
part of a transition to Apple's DocC but it is not compatible with Jazzy's symbolgraph mode.

### Documentation structure

Jazzy arranges documentation into categories.  The default categories are things
like _Classes_ and _Structures_ corresponding to programming-language concepts,
as well as _Guides_ if `--documentation` is set.

You can customize the categories and their contents using `custom_categories` in
the config file — see the ReSwift [docs](https://reswift.github.io/ReSwift/) and
[config file](https://github.com/ReSwift/ReSwift/blob/e94737282850fa038b625b4e351d1608a3d02cee/.jazzy.json)
for an example.

Within each category the items are ordered first alphabetically by source
filename, and then by declaration order within the file.  You can use
`// MARK:` comments within the file to create subheadings on the page, for
example to split up properties and methods.  There’s no way to customize this
order short of editing either the generated web page or the SourceKitten JSON.

Swift extensions and Objective-C categories allow type members to be declared
across multiple source files.  In general, extensions follow the main type
declaration: first extensions from the same source file, then extensions from
other files ordered alphabetically by filename.  Swift conditional extensions
(`extension A where …`) always appear beneath unconditional extensions.

Use this pattern to add or customize the subheading before extension members:
```swift
extension MyType {
  // MARK: Subheading for this group of methods
  …
}
```

When Jazzy is using `--swift-build-tool symgraph` the source file names and
line numbers may not be available. In this case the ordering is approximately
alphabetical by symbol name and USR; the order is stable for the same input.

Jazzy does not normally create separate web pages for declarations that do not
have any members -- instead they are entirely nested into their parent page.  Use
the `--separate-global-declarations` flag to change this and  create pages for
these empty types.

### Choosing the Swift language version

Jazzy normally uses the Swift compiler from the Xcode currently configured by
`xcode-select`.  Use the `--swift-version` flag or the `DEVELOPER_DIR` environment
variable to compile with a different Xcode.

The value you pass to `--swift-version` must be the Swift language version given
by `swift --version` in the Xcode you want to use. Jazzy uses
[xcinvoke](https://github.com/segiddins/xcinvoke) to find a suitable Xcode
installation on your system. This can be slow: if you know where Xcode is
installed then it's faster to set `DEVELOPER_DIR` directly.

For example to use Xcode 14:
```shell
jazzy --swift-version 5.7
```
...or:
```shell
DEVELOPER_DIR=/Applications/Xcode_14.app/Contents/Developer jazzy
```

## Linux

Jazzy uses [SourceKitten][sourcekitten] to communicate with the Swift build
environment and compiler.  The `sourcekitten` binary included in the Jazzy gem
is built for macOS and so does not run on other operating systems.

To use Jazzy on Linux you first need to install and build `sourcekitten`
following instructions from [SourceKitten's GitHub repository][sourcekitten].

Then to generate documentation for a SwiftPM project, instead of running just
`jazzy` do:
```shell
sourcekitten doc --spm > doc.json
jazzy --sourcekitten-sourcefile doc.json
```

We hope to improve this process in the future.

## Troubleshooting

### Swift

**Only extensions are listed in the documentation?**

Check the `--min-acl` setting -- see [above](#controlling-what-is-documented).

**Unable to find an Xcode with swift version X**

1. The value passed with `--swift-version` must exactly match the version
   number from `swiftc --version`.  For example Xcode 10.1 needs
   `--swift-version 4.2.1`.  See [the flag documentation](#choosing-the-swift-language-version).
2. The Xcode you want to use must be in the Spotlight index.  You can check
   this using `mdfind 'kMDItemCFBundleIdentifier == com.apple.dt.Xcode'`.
   Some users have reported this issue being fixed by a reboot; `mdutil -E`
   may also help.  If none of these work then you can set the `DEVELOPER_DIR`
   environment variable to point to the Xcode you want before running Jazzy
   without the `--swift-version` flag.

### Objective-C

See [this document](ObjectiveC.md).

### Miscellaneous

**Missing docset**

Jazzy only builds a docset when you set the `--module` flag.

**Unable to pass --build-tool-arguments containing commas**

If you want Jazzy to run something like `xcodebuild -scheme Scheme -destination 'a=x,b=y,c=z'`
then you must use the config file instead of the CLI flag because the CLI parser
that Jazzy uses cannot handle arguments that themselves contain commas.

The example config file here would be:
```yaml
build_tool_arguments:
  - "-scheme"
  - "Scheme"
  - "-destination"
  - "a=x,b=y,c=z"
```

**Errors running in an Xcode Run Script phase**

Running Jazzy from an Xcode build phase can go wrong in cryptic ways when Jazzy
has to run `xcodebuild`.

Users [have reported](https://github.com/realm/jazzy/issues/1012) that error
messages about symbols lacking USRs can be fixed by unsetting
`LLVM_TARGET_TRIPLE_SUFFIX` as part of the run script.

### Installation Problems

**Can't find header files / clang**

Some of the Ruby gems that Jazzy depends on have native C extensions.  This
means you need the Xcode command-line developer tools installed to build
them: run `xcode-select --install` to install the tools.

**/Applications/Xcode: No such file or directory**

The path of your active Xcode installation must not contain spaces.  So
`/Applications/Xcode.app/` is fine, `/Applications/Xcode-10.2.app/` is fine,
but `/Applications/Xcode 10.2.app/` is not.  This restriction applies only
when *installing* Jazzy, not running it.

### MacOS Before 10.14.4

Starting with Jazzy 0.10.0, if you see an error similar to `dyld: Symbol not found: _$s11SubSequenceSlTl` then you need to install the [Swift 5 Runtime Support for Command Line Tools](https://support.apple.com/kb/DL1998).

Alternatively, you can:
* Update to macOS 10.14.4 or later; or
* Install Xcode 10.2 or later at `/Applications/Xcode.app`.

## Development

Please review jazzy's [contributing guidelines](https://github.com/realm/jazzy/blob/master/CONTRIBUTING.md) when submitting pull requests.

jazzy is composed of two parts:

1. The parser, [SourceKitten][SourceKitten] (written in Swift)
2. The site generator (written in ruby)

To build and run jazzy from source:

1. Install [bundler][bundler].
2. Run `bundle install` from the root of this repo.
3. Run jazzy from source by running `bin/jazzy`.

Instructions to build SourceKitten from source can be found at
[SourceKitten's GitHub repository][SourceKitten].

## Design Goals

- Generate source code docs matching Apple's official reference documentation
- Support for standard Objective-C and Swift documentation comment syntax
- Leverage modern HTML templating ([Mustache][mustache])
- Leverage the power and accuracy of the [Clang AST][ast] and [SourceKit][sourcekit]
- Support for Dash docsets
- Support Swift and Objective-C

## License

This project is released under the [MIT license](https://github.com/realm/jazzy/blob/master/LICENSE).

## About

<img src="images/realm.png" width="184" />

Jazzy is maintained and funded by Realm Inc. The names and logos for
Realm are trademarks of Realm Inc.

We :heart: open source software!
See [our other open source projects](https://github.com/realm),
read [our blog](https://realm.io/news) or say hi on twitter
([@realm](https://twitter.com/realm)).

[clang]: https://clang.llvm.org "Clang"
[sourcekit]: https://www.jpsim.com/uncovering-sourcekit "Uncovering SourceKit"
[ast]: https://clang.llvm.org/docs/IntroductionToTheClangAST.html "Introduction To The Clang AST"
[xcode]: https://developer.apple.com/xcode "Xcode"
[SourceKitten]: https://github.com/jpsim/SourceKitten "SourceKitten"
[bundler]: https://rubygems.org/gems/bundler
[mustache]: https://mustache.github.io "Mustache"
[spm]: https://swift.org/package-manager/ "Swift Package Manager"
