## 0.9.4

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Fix crash with pre-existing `Docs` directory.  
  [John Fairhurst](https://github.com/johnfairh)
  [#965](https://github.com/realm/jazzy/issues/965)

* Fix crash with unicode scalars in string literals.  
  [John Fairhurst](https://github.com/johnfairh)
  [#972](https://github.com/realm/jazzy/issues/972)

* Fix error compiling a Swift podspec in Xcode 10.  
  [Minh Nguyễn](https://github.com/1ec5)
  [#970](https://github.com/realm/jazzy/issues/970)

## 0.9.3

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Fix crash when specifying empty Swift version. Now correctly uses the default
  Swift version.  
  [JP Simard](https://github.com/jpsim)

* Fix jony theme selection.  
  [John Fairhurst](https://github.com/johnfairh)
  [#962](https://github.com/realm/jazzy/issues/962)

## 0.9.2

##### Breaking

* None.

##### Enhancements

* Add a new 'jony' theme similar to the 2017 Apple documentation style.  
  [Harshil Shah](https://github.com/HarshilShah)

* Add the ability to limit documentation to certain files by passing in an
  `-i`/`--include` argument.  
  [Nick Fox](https://github.com/nicholasffox)
  [#949](https://github.com/realm/jazzy/issues/949)

* Improve Swift declarations to look more like the Xcode Quick Help version,
  for example including `{ get set }`, and include all attributes.  
  [John Fairhurst](https://github.com/johnfairh)
  [#768](https://github.com/realm/jazzy/issues/768)
  [#591](https://github.com/realm/jazzy/issues/591)

##### Bug Fixes

* Preserve `MARK` comment headings associated with extensions and enum cases.  
  [John Fairhurst](https://github.com/johnfairh)

* Fix issue where Overview items were invalidly being referenced with NULL
  types in the generated Dash docset index.  
  [Andrew De Ponte](https://github.com/cyphactor)

* Don't display FIXME or TODO comments as section markers.  
  [John Fairhurst](https://github.com/johnfairh)
  [#658](https://github.com/realm/jazzy/issues/658)

## 0.9.1

##### Breaking

* None.

##### Enhancements

* Added a config option (`--undocumented-text UNDOCUMENTED_TEXT`) to set the
  default text for undocumented symbols.  
  [Akhil Batra](https://github.com/akhillies)
  [#913](https://github.com/realm/jazzy/issues/913)

* Added a config option to hide Objective-C or Swift declarations:
  `--hide-declarations [objc|swift]`.  
  [Ibrahim Ulukaya](https://github.com/ulukaya)
  [#828](https://github.com/realm/jazzy/issues/828)

* Automatically use Swift or Objective-C syntax highlighting for code blocks
  in documentation comments.  Improve Swift highlighting with latest Rouge.  
  [John Fairhurst](https://github.com/johnfairh)
  [#218](https://github.com/realm/jazzy/issues/218)

##### Bug Fixes

* Fix Swift declarations when generating Objective-C docs for generic types.  
  [John Fairhurst](https://github.com/johnfairh)
  [#910](https://github.com/realm/jazzy/issues/910)

* Don't create documentation nodes for generic type parameters.  
  [John Fairhurst](https://github.com/johnfairh)
  [#878](https://github.com/realm/jazzy/issues/878)

## 0.9.0

##### Breaking

* Generate documentation coverage badge locally. Since this avoids the failable
  HTTP request to shields.io previously used to obtain the badge, we've removed
  the `--[no-]download-badge` flag and the corresponding `download_badge`
  YAML configuration key.  
  [Samuel Giddins](https://github.com/segiddins)

##### Enhancements

* None.

##### Bug Fixes

* Fixed issue that prevented Jazzy from running on case sensitive file systems.  
  [Jeremy David Giesbrecht](https://github.com/SDGGiesbrecht)
  [#891](https://github.com/realm/jazzy/issues/891)

* Fixed issue preventing `--podspec` from working with `test_spec`s.  
  [John Fairhurst](https://github.com/johnfairh)
  [#894](https://github.com/realm/jazzy/issues/894)

* Always display correct declaration for undocumented symbols.  
  [John Fairhurst](https://github.com/johnfairh)
  [#864](https://github.com/realm/jazzy/issues/864)

* Trim common indentation in multiline declarations.  
  [John Fairhurst](https://github.com/johnfairh)
  [#836](https://github.com/realm/jazzy/issues/836)

## 0.8.4

##### Breaking

* None.

##### Enhancements

* Align jazzy terminology with Apple usage.  
  [Xiaodi Wu](https://github.com/xwu)
  [John Fairhurst](https://github.com/johnfairh)

* Add `url` attribute that can be more accurate than `{{section}}.html` as a URL
  in custom templates.  
  [John Fairhurst](https://github.com/johnfairh)

##### Bug Fixes

* Fix crash when specifying `swift_version` as a floating point value in
  `.jazzy.yaml` rather than a string.  
  [JP Simard](https://github.com/jpsim)
  [#860](https://github.com/realm/jazzy/issues/860)

* Autolink from parameter documentation and from external markdown documents
  including README.  Autolink to symbols containing & < >.  
  [John Fairhurst](https://github.com/johnfairh)
  [#715](https://github.com/realm/jazzy/issues/715)
  [#789](https://github.com/realm/jazzy/issues/789)
  [#805](https://github.com/realm/jazzy/issues/805)

* Fix Swift 4 declarations containing ampersands (`&`) being truncated.  
  [JP Simard](https://github.com/jpsim)

## 0.8.3

##### Breaking

* None.

##### Enhancements

* Generate Swift declaration for more Objective-C declarations.  
  [Zheng Li](https://github.com/ainopara)

* Improve quality & accuracy of Swift interfaces for Objective-C declarations
  when generating Objective-C docs.  
  [Norio Nomura](https://github.com/norio-nomura)

* Process Swift 3.2/4 doc comments.  
  [John Fairhurst](https://github.com/johnfairh)

##### Bug Fixes

* Fix missing doc comments on some extensions.  
  [John Fairhurst](https://github.com/johnfairh)
  [#454](https://github.com/realm/jazzy/issues/454)

* Fix failure when attempting to download documentation coverage badge with
  jazzy using macOS system Ruby, or a Ruby built with outdated versions of
  OpenSSL.  
  [JP Simard](https://github.com/jpsim)
  [#824](https://github.com/realm/jazzy/issues/824)

* Stop `--skip-undocumented` from skipping documented items nested
  inside extensions of types from other modules.  
  [John Fairhurst](https://github.com/johnfairh)
  [#502](https://github.com/realm/jazzy/issues/502)

* Fix members added to extensions of a nested type showing up in the parent.  
  [John Fairhurst](https://github.com/johnfairh)
  [#333](https://github.com/realm/jazzy/issues/333)

## 0.8.2

##### Breaking

* None.

##### Enhancements

* Report number of included and skipped declarations in CLI output.  
  [John Fairhurst](https://github.com/johnfairh)
  [#238](https://github.com/realm/jazzy/issues/238)

* Build ObjC docs with clang modules enabled by default (`-fmodules` flag).  
  [Maksym Grebenets](https://github.com/mgrebenets)
  [#636](https://github.com/realm/jazzy/issues/636)

* Shave ~1MB from jazzy's gem distribution.  
  [JP Simard](https://github.com/jpsim)

##### Bug Fixes

* Fix support for Ruby 2.2.  
  [John Fairhurst](https://github.com/johnfairh)
  [#801](https://github.com/realm/jazzy/issues/801)

* Fix many cases of incorrect, missing or superfluous docs on Swift
  declarations.  
  [John Fairhurst](https://github.com/johnfairh)

## 0.8.1

##### Breaking

* None.

##### Enhancements

* Allow all markdown in returns and parameter description callouts.  
  [John Fairhurst](https://github.com/johnfairh)
  [#476](https://github.com/realm/jazzy/issues/476)

##### Bug Fixes

* Fix a crash that occurred when a documentation comment ended with an extended
  grapheme cluster.  
  [Lukas Stührk](https://github.com/Lukas-Stuehrk)
  [#794](https://github.com/realm/jazzy/issues/794)
  [SourceKitten#350](https://github.com/jpsim/SourceKitten/issues/350)

## 0.8.0

##### Breaking

* `undocumented.json` is now only in the output directory and is no longer
  copied into docsets.  
  [Jeremy David Giesbrecht](https://github.com/SDGGiesbrecht)
  [#754](https://github.com/realm/jazzy/issues/754)

##### Enhancements

* Add `--[no-]download-badge` flag to skip downloading the documentation
  coverage badge from shields.io. Useful if generating docs offline.  
  [JP Simard](https://github.com/jpsim)
  [#765](https://github.com/realm/jazzy/issues/765)

##### Bug Fixes

* Blank line no longer needed before lists or code blocks.  
  [John Fairhurst](https://github.com/johnfairh)
  [#546](https://github.com/realm/jazzy/issues/546)

* Linking to headers in apple theme gives correct vertical alignment.  
  [John Fairhurst](https://github.com/johnfairh)

* Headers in source code markdown no longer cause corruption.  
  [John Fairhurst](https://github.com/johnfairh)
  [#628](https://github.com/realm/jazzy/issues/628)

## 0.7.5

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Fix issue where using a custom theme would crash jazzy when using Ruby 2.4.  
  [Jason Wray](https://github.com/friedbunny)
  [#752](https://github.com/realm/jazzy/issues/752)

* Fix support for Ruby 2.0.0.  
  [Jason Wray](https://github.com/friedbunny)
  [#747](https://github.com/realm/jazzy/issues/747)

* Fix issue where header files are not found if inside subdirectories of the
  framework_root specified folder.  
  [Christopher Gretzki](https://github.com/gretzki)
  [#518](https://github.com/realm/jazzy/issues/518)

## 0.7.4

##### Breaking

* None.

##### Enhancements

* Generate shields.io badge for documentation coverage, unless
  `hide_documentation_coverage` is set.  
  [Harlan Haskins](https://github.com/harlanhaskins)
  [#723](https://github.com/realm/jazzy/issues/723)

* Add support for searching docs when using the `fullwidth` theme. A new option,
  `--disable-search`, lets you turn this off.  
  [Esad Hajdarevic](https://github.com/esad)
  [Tom MacWright](https://github.com/tmcw)
  [Nadia Barbosa](https://github.com/captainbarbosa)
  [#14](https://github.com/realm/jazzy/issues/14)

* New config option `use_safe_filenames` encodes unsafe characters when
  generating filenames. By default, documentation may receive filenames like
  `/(_:_:).html`. With `use_safe_filenames`, the same file will receive the name
  `_2F_28_5F_3A_5F_3A_29.html` instead.  
  [Jeremy David Giesbrecht](https://github.com/SDGGiesbrecht)
  [#699](https://github.com/realm/jazzy/issues/699)
  [#146](https://github.com/realm/jazzy/issues/146)
  [#361](https://github.com/realm/jazzy/issues/361)
  [#547](https://github.com/realm/jazzy/issues/547)

* References to Objective-C methods are now autolinked.  
  [Minh Nguyễn](https://github.com/1ec5)
  [#362](https://github.com/realm/jazzy/issues/362)

* Print documentation coverage percentage and the number of undocumented
  methods to the command line when running jazzy.  
  [Jason Wray](https://github.com/friedbunny)

##### Bug Fixes

* Fix issue where existing abstracts for non custom sections would be completely
  overwritten when using extra abstract injection with --abstract.  
  [Thibaud Robelain](https://github.com/thibaudrobelain)
  [#600](https://github.com/realm/jazzy/issues/600)

* Fix issue where generic type parameters registered as undocumented symbols.  
  [Jeremy David Giesbrecht](https://github.com/SDGGiesbrecht)
  [#429](https://github.com/realm/jazzy/issues/429)

* Fix issue where parameter and return callouts were duplicated in documentation.  
  [Jeremy David Giesbrecht](https://github.com/SDGGiesbrecht)
  [#673](https://github.com/realm/jazzy/issues/673)

* Fix issue where Objective-C superclass in declaration was unlinked.  
  [Minh Nguyễn](https://github.com/1ec5)
  [#706](https://github.com/realm/jazzy/issues/706)

* Fix issue where multiple Objective-C categories of the same external class
  in different files were merged into one and named after the first category
  found.  
  [Minh Nguyễn](https://github.com/1ec5)
  [#539](https://github.com/realm/jazzy/issues/539)

* String literals in code listings are no longer wrapped in `<q>` tags (`apple`
  and `fullwidth` themes only).  
  [Minh Nguyễn](https://github.com/1ec5)
  [#714](https://github.com/realm/jazzy/issues/714)

* Fix issue where passing a `--podspec` argument would use a malformed
  `SWIFT_VERSION` value, causing compilation to fail.  
  [JP Simard](https://github.com/jpsim)

## 0.7.3

##### Breaking

* None.

##### Enhancements

* Podspec-based documentation will take trunk's `pushed_with_swift_version`
  attribute into account when generating documentation by default.  
  [Orta Therox](https://github.com/orta)

* Podspec-based documentation respects the `swift-version` config option.  
  [Orta Therox](https://github.com/orta)

##### Enhancements

* Support Objective-C class properties.  
  [Jérémie Girault](https://github.com/jeremiegirault)
  [JP Simard](https://github.com/jpsim)

* Support documenting Swift 3 operator precedence groups.  
  [JP Simard](https://github.com/jpsim)

##### Bug Fixes

* Rename Dash typedef type from "Alias" to "Type".  
  [Bogdan Popescu](https://github.com/Kapeli)

* Fix crash when sorting multiple identically named declarations with no USR,
  which is very common when generating docs for podspecs supporting multiple
  platforms.  
  [JP Simard](https://github.com/jpsim)
  [#661](https://github.com/realm/jazzy/issues/661)

* Fix Xcode not being found when specifying a custom Swift version
  (`--swift-version`).  
  [Samuel Giddins](https://github.com/segiddins)
  [Paul Cantrell](https://github.com/pcantrell)
  [#656](https://github.com/realm/jazzy/issues/656)

* Fix crash when generating Objective-C docs for projects with "@" directives in
  documentation comments with Xcode 8.1 or later.  
  [Jérémie Girault](https://github.com/jeremiegirault)

## 0.7.2

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Declarations marked `@available(..., unavailable, ...)` are no longer
  documented.  
  [JP Simard](https://github.com/jpsim)
  [#654](https://github.com/realm/jazzy/issues/654)

* Treat the `open` ACL as more public than `public`.  
  [JP Simard](https://github.com/jpsim)

## 0.7.1

##### Breaking

* None.

##### Enhancements

* Added support for the new access control specifiers of fileprivate and open.  
  [Shmuel Kallner](https://github.com/shmuelk)
  [#645](https://github.com/realm/jazzy/issues/645)
  [#646](https://github.com/realm/jazzy/issues/646)

##### Bug Fixes

* Fix issue where jazzy could not be installed from Gemfile due to
  SourceKitten symlinks already being present.  
  [William Meleyal](https://github.com/meleyal)
  [#438](https://github.com/realm/jazzy/issues/438)

* The lint report in `undocumented.json` is more human-readable: includes fully
  qualified symbol names, pretty printed.  
  [Paul Cantrell](https://github.com/pcantrell)
  [#598](https://github.com/realm/jazzy/issues/598)

* The `exclude` option now properly supports wildcards.  
  [Paul Cantrell](https://github.com/pcantrell)
  [#640](https://github.com/realm/jazzy/issues/640)

## 0.7.0

##### Breaking

* The `docset_platform` option is no longer available. The module name will
  now be used instead of `jazzy`.  
  [JP Simard](https://github.com/jpsim)
  [#423](https://github.com/realm/jazzy/issues/423)

##### Enhancements

* Improved auto-linking behavior to link declarations within declarations and
  fix cases where declarations would link to themselves or their current page.  
  [Esad Hajdarevic](https://github.com/esad)
  [#483](https://github.com/realm/jazzy/issues/483)

##### Bug Fixes

* Fix issue where single-line declaration + bodies in Swift would include the
  body in the parsed declaration.  
  [JP Simard](https://github.com/jpsim)
  [#226](https://github.com/realm/jazzy/issues/226)

* Fix issue where some sections would become empty when using custom groups.  
  [JP Simard](https://github.com/jpsim)
  [#475](https://github.com/realm/jazzy/issues/475)

* Fix issue where directories ending with `.swift` would be considered Swift
  source files.  
  [JP Simard](https://github.com/jpsim)
  [#586](https://github.com/realm/jazzy/issues/586)

## 0.6.3

##### Breaking

* None.

##### Enhancements

* `--exclude` flag now supports excluding directories in addition to files.  
  [Gurrinder](https://github.com/gurrinder)
  [#503](https://github.com/realm/jazzy/issues/503)

* The `cocoapods` gem was updated to 1.0.1 and `rouge` to 1.11.0.  
  [Samuel Giddins](https://github.com/segiddins)
  [#568](https://github.com/realm/jazzy/issues/568)

* Extra markdown documentation can now be included as their own pages in the
  sidebar using the `--documentation` option and in the generated Dash docset
  as Guides.  
  [Karl Bowden](https://github.com/agentk)
  [#435](https://github.com/realm/jazzy/issues/435)

* Section headings can now include additional markdown content using the
  `--abstract` option.  
  [Karl Bowden](https://github.com/agentk)
  [#435](https://github.com/realm/jazzy/issues/435)

* If Swift version is not specified, look for Swift toolchain or clang location
  in the following order:

    * `$XCODE_DEFAULT_TOOLCHAIN_OVERRIDE`
    * `$TOOLCHAIN_DIR`
    * `xcrun -find swift`
    * `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`
    * `/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`
    * `~/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`
    * `~/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`

  This will be especially useful once jazzy supports generating docs for
  Swift Package Manager modules with a toolchain not tied to an Xcode release.  
  [JP Simard](https://github.com/jpsim)

##### Bug Fixes

* Don't document clang-unexposed Objective-C declarations.  
  [JP Simard](https://github.com/jpsim)
  [#573](https://github.com/realm/jazzy/issues/573)

## 0.6.2

##### Breaking

* None.

##### Enhancements

* Include one level of nested classes, structs, protocols and enums in the
  navigation bar.  
  [JP Simard](https://github.com/jpsim)
  [#64](https://github.com/realm/jazzy/issues/64)

##### Bug Fixes

* None.

## 0.6.1

##### Breaking

* None.

##### Enhancements

* Objective-C documentation now also includes Swift declarations.  
  [JP Simard](https://github.com/jpsim)
  [#136](https://github.com/realm/jazzy/issues/136)

* Default to the Xcode version selected in `xcode-select` if no Swift version is
  specified.  
  [Samuel Giddins](https://github.com/segiddins)
  [#427](https://github.com/realm/jazzy/issues/427)

##### Bug Fixes

* Uses GitHub-Flavored Markdown syntax for anchors when rendering README pages.  
  [Zachary Waldowski](https://github.com/zwaldowski)
  [#524](https://github.com/realm/jazzy/issues/524)

* Fix crash when using unexposed declarations in Objective-C.  
  [JP Simard](https://github.com/jpsim)
  [#543](https://github.com/realm/jazzy/issues/543)

* No longer document Swift extensions on types with an ACL lower than `min-acl`
  when they contain `MARK`s.  
  [JP Simard](https://github.com/jpsim)
  [#544](https://github.com/realm/jazzy/issues/544)

## 0.6.0

##### Breaking

* Config files now use the same option names as the command line. If you are
  using one of the keys that has changed in your `.jazzy.yaml`, you will receive
  a warning. See the [pull request](https://github.com/realm/jazzy/pull/456) for
  a complete list of changed options. As always, you can get a list of all
  options with `jazzy --help config`.  
  [Paul Cantrell](https://github.com/pcantrell)

* Jazzy's undocumented.txt has been replaced with undocumented.json. This new
  format includes contextual information that one might use to lint
  documentation in an automated fashion.  
  [Jeff Verkoeyen](https://github.com/jverkoey)

* `--swift-version` now defaults to 2.2 instead of 2.1.1.  
  [Tamar Nachmany](https://github.com/tamarnachmany)

##### Enhancements

* Add `--skip-documentation` flag. Skips site generation phase. `undocumented.json`
  is still generated.  
  [Jeff Verkoeyen](https://github.com/jverkoey)

* Merge Objective-C categories into their parent type documentation to match
  Swift behavior.  
  [Esad Hajdarevic](https://github.com/esad)
  [#457](https://github.com/realm/jazzy/issues/457)

* Add support for documenting Swift 2.2 `associatedtype`s and infix, postfix &
  prefix operators.  
  [JP Simard](https://github.com/jpsim)

##### Bug Fixes

* Add support for Objective-C module imports.  
  [JP Simard](https://github.com/jpsim)
  [#452](https://github.com/realm/jazzy/issues/452)

* Workaround for an apparent SourceKit bug which sometimes caused extensions
  to be merged into the wrong type.  
  [Paul Cantrell](https://github.com/pcantrell)
  [#459](https://github.com/realm/jazzy/issues/459)
  [#460](https://github.com/realm/jazzy/issues/460)

## 0.5.0

##### Breaking

* `--swift-version` now defaults to 2.1.1 instead of 2.1.  
  [Nikita Lutsenko](https://github.com/nlutsenko)
  [#416](https://github.com/realm/jazzy/pull/416)

* Swift 1.x is no longer supported.

* `--templates-directory` and `--assets-directory` have been deprecated in favor
  of `--theme`. Specify either 'apple' (default), 'fullwidth' or the path to
  your mustache templates and other assets for a custom theme.  
  [Karl Bowden](https://github.com/agentk)
  [JP Simard](https://github.com/jpsim)
  [#130](https://github.com/realm/jazzy/issues/130)

##### Enhancements

* Add `--sdk [iphone|watch|appletv][os|simulator]|macosx` option for Objective-C
  projects.  
  [Jeff Verkoeyen](https://github.com/jverkoey)

* Add `--head` option to inject custom HTML into `<head></head>`.  
  [JP Simard](https://github.com/jpsim)

##### Bug Fixes

* Fix an issue where extension documentation would use the original type
  documentation block rather than the comment immediately preceding the
  extension.  
  [JP Simard](https://github.com/jpsim)
  [#230](https://github.com/realm/jazzy/issues/230)
  [#313](https://github.com/realm/jazzy/issues/313)
  [#334](https://github.com/realm/jazzy/issues/334)

* Fix multi-byte documentation issues.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#403](https://github.com/realm/jazzy/issues/403)


## 0.4.1

*Note: this is the last official release of jazzy supporting Swift 1.x.*

##### Breaking

* None.

##### Enhancements

* Support "wall of asterisk" documentation comments.  
  [Jeff Verkoeyen](https://github.com/jverkoey)
  [#347](https://github.com/realm/jazzy/issues/347)

* Expanding a token no longer causes the document to 'jump' to the hash.  
  [Jeff Verkoeyen](https://github.com/jverkoey)
  [#352](https://github.com/realm/jazzy/issues/352)

* Autolinking improvements:
  - Autolinks only match `` `ThingsInBackticks` ``, and must match the entire
    string. This prevents spurious matching in prose and sample code.
  - Autolinks supports siblings, ancestors, top-level elements, and
    dot-separated chains starting with any of the above: `someProperty`,
    `SomeType.NestedType.someMethod(_:)`.
  - New `...` wildcard prevents you from having to list all method parameters:
    `someMethod(...)`

  [Paul Cantrell](https://github.com/pcantrell)
  [#327](https://github.com/realm/jazzy/issues/327)
  [#329](https://github.com/realm/jazzy/issues/329)
  [#359](https://github.com/realm/jazzy/issues/359)

* Miscellaneous minor font size, weight, and color adjustments.  
  [Jeff Verkoeyen](https://github.com/jverkoey)

* In-page anchors now appear below the header.  
  [Jeff Verkoeyen](https://github.com/jverkoey)

##### Bug Fixes

* Fix an out-of-bounds exception when generating pragma marks.  
  [JP Simard](https://github.com/jpsim)
  [#370](https://github.com/realm/jazzy/issues/370)

* Add support for C/C++ struct, field & ivar types.  
  [JP Simard](https://github.com/jpsim)
  [#374](https://github.com/realm/jazzy/issues/374)
  [#387](https://github.com/realm/jazzy/issues/387)

* Links to source files on GitHub are no longer broken when `source_directory`
  does not point to the current working directory.  
  [Paul Cantrell](https://github.com/pcantrell)

* When `excluded_files` is specified in a config file, it is now resolved
  relative to the file (like other options) instead of relative to the working
  directory.  
  [Paul Cantrell](https://github.com/pcantrell)


## 0.4.0

##### Breaking

* `--swift-version` now defaults to 2.1 instead of 2.0.  
  [JP Simard](https://github.com/jpsim)

##### Enhancements

* Support for documenting Objective-C projects! 🎉
  Pass `--objc`, `--umbrella-header ...` and `-framework-root ...`.  
  [JP Simard](https://github.com/jpsim)
  [#56](https://github.com/realm/jazzy/issues/56)

* Mentions of top-level declarations in documentation comments are now
  automatically hyperlinked to their reference.  
  [JP Simard](https://github.com/jpsim)

* Jazzy can now read options from a configuration file. The command line
  provides comprehensive help for available options via `jazzy -h config`.  
  [Paul Cantrell](https://github.com/pcantrell)
  [#310](https://github.com/realm/jazzy/pull/310)

* Render special list items (e.g. Throws, See, etc.). See
  https://ericasadun.com/2015/06/14/swift-header-documentation-in-xcode-7/ for
  a complete list.  
  [JP Simard](https://github.com/jpsim)
  [#317](https://github.com/realm/jazzy/issues/317)

* Support for Swift 2.1.  
  [JP Simard](https://github.com/jpsim)

* Swift extensions are now merged with their extended type, rendering a note
  to describe extension default implementations and extension methods.  
  [Paul Cantrell](https://github.com/pcantrell)

##### Bug Fixes

* None.


## 0.3.2

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Fixed an issue that prevented building projects with different schema & module
  names.  
  [JP Simard](https://github.com/jpsim)
  [#259](https://github.com/realm/jazzy/issues/259)

* Hide documentation coverage from header using `--hide-documentation-coverage`.  
  [mbogh](https://github.com/mbogh)
  [#129](https://github.com/realm/jazzy/issues/297)

* Print a more informative error when unable to find an Xcode that has the
  requested Swift version.  
  [Samuel Giddins](https://github.com/segiddins)


## 0.3.1

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Added missing Swift 2 declaration types.  
  [JP Simard](https://github.com/jpsim)


## 0.3.0

##### Breaking

* `--swift-version` now defaults to 2.0 instead of 1.2.  
  [JP Simard](https://github.com/jpsim)

##### Enhancements

* Now supports Swift 2.0 (previous Swift versions are still supported).  
  [JP Simard](https://github.com/jpsim)
  [Samuel Giddins](https://github.com/segiddins)

* Declarations can now be grouped by custom categories defined in a JSON or YAML
  file passed to `--categories`.  
  [Paul Cantrell](https://github.com/pcantrell)

##### Bug Fixes

* "View on GitHub" is now only generated if a GitHub URL is specified.  
  [mbogh](https://github.com/mbogh)
  [#244](https://github.com/realm/jazzy/issues/244)

* Empty extensions are no longer documented.  
  [Paul Cantrell](https://github.com/pcantrell)

* Undocumented enum cases are now supported.  
  [JP Simard](https://github.com/jpsim)
  [#74](https://github.com/realm/jazzy/issues/74)


## 0.2.4

##### Breaking

* None.

##### Enhancements

* Improved how SourceKitten is vendored.  
  [JP Simard](https://github.com/jpsim)

* Show type declaration under its title.  
  [Paul Cantrell](https://github.com/pcantrell)

* Added support for custom assets: pass `--assets-directory` to jazzy.  
  [gurkendoktor](https://github.com/gurkendoktor)

* Added support for custom copyright text: pass `--copyright` to jazzy.  
  [emaloney](https://github.com/emaloney)

##### Bug Fixes

* Fixed a crash when parsing an empty documentation comment.  
  [JP Simard](https://github.com/jpsim)
  [#236](https://github.com/realm/jazzy/issues/236)

* `--exclude` now works properly if its argument is a relative path.  
  [Paul Cantrell](https://github.com/pcantrell)


## 0.2.3

##### Breaking

* None.

##### Enhancements

* The `jazzy` CLI now accepts a `--swift-version` option (defaulting to 1.2),
  and will automatically find an appropriate Xcode installation.  
  [Samuel Giddins](https://github.com/segiddins)
  [#214](https://github.com/realm/jazzy/issues/214)

##### Bug Fixes

* Declarations with no USR will no longer be documented.  
  [JP Simard](https://github.com/jpsim)


## 0.2.2

##### Breaking

* None.

##### Enhancements

* Added support for custom templates: use the `-t`/`--template-directory`
  argument to jazzy.  
  [JP Simard](https://github.com/jpsim)
  [#20](https://github.com/realm/jazzy/issues/20)

##### Bug Fixes

* None.


## 0.2.1

##### Breaking

* None.

##### Enhancements

* Added the ability to ignore certain files by passing in an `-e`/`--exclude`
  argument to jazzy.  
  [JP Simard](https://github.com/jpsim)
  [#173](https://github.com/realm/jazzy/issues/173)

##### Bug Fixes

* None.


## 0.2.0

##### Breaking

* Jazzy now only supports projects using Swift 1.2.  
  [JP Simard](https://github.com/jpsim)
  [#170](https://github.com/realm/jazzy/issues/170)

* Increase default minimum ACL to public.  
  [JP Simard](https://github.com/jpsim)
  [#186](https://github.com/realm/jazzy/issues/186)

##### Enhancements

* Use `key.accessibility` to determine ACL (value coming from SourceKit, which
  is generally more accurate than parsing the declaration for an accessibility
  keyword).  
  [JP Simard](https://github.com/jpsim)
  [#185](https://github.com/realm/jazzy/issues/185)

##### Bug Fixes

* None.


## 0.1.6

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Make the gem installable.  
  [Samuel Giddins](https://github.com/segiddins)


## 0.1.5

##### Breaking

* None.

##### Enhancements

* Added `--readme` command line option.  
  [segiddins](https://github.com/segiddins)
  [#196](https://github.com/realm/jazzy/issues/196)

* Cleaned up front end HTML & CSS.  
  [JP Simard](https://github.com/jpsim)
  [#95](https://github.com/realm/jazzy/issues/95)

* "Show on GitHub" links now link to line-ranges for multi-line definitions.  
  [JP Simard](https://github.com/jpsim)
  [#198](https://github.com/realm/jazzy/issues/198)

##### Bug Fixes

* Fixed issue where docset would contain duplicate files.  
  [JP Simard](https://github.com/jpsim)
  [#204](https://github.com/realm/jazzy/issues/204)

* Fixed installation issues on case-sensitive file systems.  
  [kishikawakatsumi](https://github.com/kishikawakatsumi)

* Fixed out-of-bounds exception when parsing the declaration in files starting
  with a declaration.  
  [JP Simard](https://github.com/jpsim)
  [#30](https://github.com/jpsim/SourceKitten/issues/30)

* Fixed out-of-bounds exception and inaccurate parsed declarations when using
  multibyte characters.  
  [JP Simard](https://github.com/jpsim)
  [#35](https://github.com/jpsim/SourceKitten/issues/35)

* Fixed parsing issues with keyword functions such as `subscript`, `init` and
  `deinit`.  
  [JP Simard](https://github.com/jpsim)
  [#27](https://github.com/jpsim/SourceKitten/issues/27)

* Fixed issues where USR wasn't accurate because dependencies couldn't be
  resolved.  
  [JP Simard](https://github.com/jpsim)

* Allow using a version of Xcode that is symlinked to
  `/Applications/Xcode.app`.  
  [Samuel Giddins](https://github.com/segiddins)


## 0.1.4

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* No longer count undocumented externally declared tokens as undocumented.  
  [JP Simard](https://github.com/jpsim)
  [#188](https://github.com/realm/jazzy/issues/188)


## 0.1.3

##### Breaking

* None.

##### Enhancements

* Improve the styling of `dl` elements (parsed key-value pairs).  
  [segiddins](https://github.com/segiddins)

* Raise exceptions if Xcode requirements aren't met.  
  [JP Simard](https://github.com/jpsim)

##### Bug Fixes

* No longer count initializers with parameters as undocumented.  
  [JP Simard](https://github.com/jpsim)
  [#183](https://github.com/realm/jazzy/issues/183)

* No longer crash when a token is missing a USR.  
  [JP Simard](https://github.com/jpsim)
  [#171](https://github.com/realm/jazzy/issues/171)

* Fixed encoding issues in some environments.  
  [James Barrow](https://github.com/Baza207)
  [#152](https://github.com/realm/jazzy/issues/152)

* No longer count undocumented externally declared tokens as undocumented.  
  [JP Simard](https://github.com/jpsim)
  [#188](https://github.com/realm/jazzy/issues/188)

* Fixed `--source-directory` CLI option.  
  [JP Simard](https://github.com/jpsim)
  [#177](https://github.com/realm/jazzy/issues/177)


## 0.1.2

##### Breaking

* None.

##### Enhancements

* Use Menlo for code everywhere.  
  [beltex](https://github.com/beltex)
  [#137](https://github.com/realm/jazzy/issues/137)

##### Bug Fixes

* (Really) fixes installation as a RubyGem.  
  [beltex](https://github.com/beltex)
  [#159](https://github.com/realm/jazzy/issues/159)


## 0.1.1

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Fixes installation as a RubyGem.  
  [Samuel Giddins](https://github.com/segiddins)
  [#159](https://github.com/realm/jazzy/issues/159)


## 0.1.0

[sourcekitten](https://github.com/jpsim/sourcekitten/compare/0.2.7...0.3.1)

##### Breaking

* None.

##### Enhancements

* Add the ability to document a Pod from just a podspec, which allows jazzy to
  run on cocoadocs.org.  
  [Samuel Giddins](https://github.com/segiddins)
  [#58](https://github.com/realm/jazzy/issues/58)

##### Bug Fixes

* De-duplicate the sidebar list of extensions and show all children for an
  extension, regardless of how many extensions on a type there are.  
  [Samuel Giddins](https://github.com/segiddins)


## 0.0.20

[sourcekitten](https://github.com/jpsim/sourcekitten/compare/0.2.6...0.2.7)

##### Breaking

* Don't skip declarations with no documentation comments by default.
  Allow skipping using `--skip-undocumented`.  
  [JP Simard](https://github.com/jpsim)
  [#129](https://github.com/realm/jazzy/issues/129)

##### Enhancements

* Combine abstract and discussion in page overview.  
  [JP Simard](https://github.com/jpsim)
  [#115](https://github.com/realm/jazzy/issues/115)

##### Bug Fixes

* Don't show 'Show in Github' link for types declared in system frameworks.  
  [JP Simard](https://github.com/jpsim)
  [#110](https://github.com/realm/jazzy/issues/110)

## 0.0.19

[sourcekitten](https://github.com/jpsim/sourcekitten/compare/0.2.3...0.2.6)

##### Breaking

None.

##### Enhancements

* Added CHANGELOG.md.  
  [JP Simard](https://github.com/jpsim)
  [#125](https://github.com/realm/jazzy/issues/125)

* Include parse errors in the JSON output & print to STDERR.  
  [JP Simard](https://github.com/jpsim)
  [jpsim/sourcekitten#16](https://github.com/jpsim/sourcekitten/issues/16)

##### Bug Fixes

* Fixed crash when files contained a declaration on the first line.  
  [JP Simard](https://github.com/jpsim)
  [jpsim/sourcekitten#14](https://github.com/jpsim/sourcekitten/issues/14)

* Fixed invalid JSON issue when last file in an Xcode project failed to parse.  
  [JP Simard](https://github.com/jpsim)

* Fixed crash when attempting to parse the declaration of `extension Array`.  
  [JP Simard](https://github.com/jpsim)
  [#126](https://github.com/realm/jazzy/issues/126)
