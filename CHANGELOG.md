## Master

##### Breaking

* None.

##### Enhancements

* Added `--readme` command line option.  
  [segiddins](https://github.com/segiddins)
  [#196](https://github.com/realm/jazzy/issues/196)

##### Bug Fixes

* Fixed issue where docset would contain duplicate files.  
  [JP Simard](https://github.com/jpsim)
  [#204](https://github.com/realm/jazzy/issues/204)

* Fixed installation issues on case-sensitive file systems.  
  [kishikawakatsumi](https://github.com/kishikawakatsumi)


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
