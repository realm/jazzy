## Master

[sourcekitten](https://github.com/jpsim/sourcekitten/compare/0.2.6...master)

##### Breaking

None.

##### Enhancements

None.

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
