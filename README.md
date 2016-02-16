# BetterRegex

[![CI Status](http://img.shields.io/travis/mobilarts/BetterRegex.svg?style=flat)](https://travis-ci.org/Mobilarts/BetterRegex)
[![Version](https://img.shields.io/cocoapods/v/BetterRegex.svg?style=flat)](http://cocoapods.org/pods/BetterRegex)
[![License](https://img.shields.io/cocoapods/l/BetterRegex.svg?style=flat)](http://cocoapods.org/pods/BetterRegex)
[![Platform](https://img.shields.io/cocoapods/p/BetterRegex.svg?style=flat)](http://cocoapods.org/pods/BetterRegex)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

The library is straightforward to use.

1. Define your regular expression matching pattern as you normally would, including named groups (which are not supported by the default NSRegularExpression). Named groups follow the same method used in PHP: (?<name_of_group>your match)

let pattern = "(?<test>w.+?)\\s(?<amatch>a.+?)$"


2. Instantiate the main class using your pattern: BetterRegex(pattern: pattern) (it is better for performance to reuse that class for the same pattern every time you need it rather than reinstantiate it every time)

let test = BetterRegex(pattern: pattern)

3. Obtain your matches back:

let regexOptions: NSMatchingOptions = NSMatchingOptions.WithTransparentBounds
let matches: RegexResults = test.extractMatches("welcome all", options: regexOptions)

4. Access your matches: the RegexResults structure that is returned with convenient accessor methods by name and index. Heye you can get your optional string for a key name using matches.getKey("test") or matches.getKey("amatch") or through numeric indexes for non-named groups and named groups alike via matches.getKey(0) for example.



## Requirements

A reasonably recent version of Xcode

## Installation

BetterRegex is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "BetterRegex"
```

## Author

Mobilarts / Louis-Eric Simard, louis-eric @ mobilarts -- dot-- com

## License

BetterRegex is available under the MIT license. See the LICENSE file for more info.
