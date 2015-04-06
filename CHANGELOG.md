## Master

##### Breaking

None.

##### Enhancements

* Added definition line ranges to declarations.  
  [JP Simard](https://github.com/jpsim)
  [#198](https://github.com/realm/jazzy/issues/198)

##### Bug Fixes

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


## 0.3.0

##### Breaking

* Everything. No, seriously lots has changed in this release and you should
  consider SourceKitten entirely rewritten. SourceKitten now uses dynamic
  frameworks for the bulk of its functionality, which means that everything is
  now much more modular and testable.  
  [JP Simard](https://github.com/jpsim)
  [#17](https://github.com/jpsim/SourceKitten/issues/17)

##### Enhancements

* Consolidated error generation.  
  [JP Simard](https://github.com/jpsim)
  [#24](https://github.com/jpsim/SourceKitten/issues/24)

##### Bug Fixes

None.

## 0.2.8

##### Breaking

None.

##### Enhancements

None.

##### Bug Fixes

* Fixed issue where certain Swift files wouldn't be parsed.  
  [JP Simard](https://github.com/jpsim)
  [#18](https://github.com/jpsim/sourcekitten/issues/18)

## 0.2.7

##### Breaking

None.

##### Enhancements

None.

##### Bug Fixes

* Fixed improper UTF8 parsing of MARK comments.  
  [JP Simard](https://github.com/jpsim)
  [realm/jazzy#131](https://github.com/realm/jazzy/issues/131)

## 0.2.6

##### Breaking

None.

##### Enhancements

* Added CHANGELOG.md.  
  [JP Simard](https://github.com/jpsim)
  [realm/jazzy#125](https://github.com/realm/jazzy/issues/125)

* Include parse errors in the JSON output.  
  [JP Simard](https://github.com/jpsim)
  [#16](https://github.com/jpsim/sourcekitten/issues/16)

##### Bug Fixes

* Fixed crash when files contained a declaration on the first line.  
  [JP Simard](https://github.com/jpsim)
  [#14](https://github.com/jpsim/sourcekitten/issues/14)

* Fixed invalid JSON issue when last file in an Xcode project failed to parse.  
  [JP Simard](https://github.com/jpsim)

* Fixed crash when attempting to parse the declaration of `extension Array`.  
  [JP Simard](https://github.com/jpsim)
  [realm/jazzy#126](https://github.com/realm/jazzy/issues/126)
