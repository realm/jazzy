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
  [pcantrell](https://github.com/pcantrell)

##### Bug Fixes

* "View on GitHub" is now only generated if a GitHub URL is specified.  
  [mbogh](https://github.com/mbogh)
  [#244](https://github.com/realm/jazzy/issues/244)

* Empty extensions are no longer documented.  
  [pcantrell](https://github.com/pcantrell)

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
  [pcantrell](https://github.com/pcantrell)

* Added support for custom assets: pass `--assets-directory` to jazzy.  
  [gurkendoktor](https://github.com/gurkendoktor)

* Added support for custom copyright text: pass `--copyright` to jazzy.  
  [emaloney](https://github.com/emaloney)

##### Bug Fixes

* Fixed a crash when parsing an empty documentation comment.  
  [JP Simard](https://github.com/jpsim)
  [#236](https://github.com/realm/jazzy/issues/236)

* `--exclude` now works properly if its argument is a relative path.  
  [pcantrell](https://github.com/pcantrell)


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
