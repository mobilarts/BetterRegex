
//  BetterRegex.swift
//
//  Created by Louis-Eric Simard on 2015-06-24.
//  Copyright (c) 2015 Mobilarts. All rights reserved.
//


import Foundation

/*

Generic helper class that knows nothing about named capturing groups

*/

class BaseRegex {
    
    var expression: NSRegularExpression?
    var options: NSRegularExpressionOptions?
    var pattern: String?
    var results: [NSTextCheckingResult]?
    
    init (pattern: String, options: NSRegularExpressionOptions = nil)
    {
        //TODO: detect PHP preg-match options
        self.pattern = pattern
        self.options = options
    }
    
    func getExpression() -> NSRegularExpression
    {
        if expression == nil {
            expression = NSRegularExpression(pattern: pattern!, options: options ?? nil, error: nil)
        }
        return expression!
    }
    
    func internalProcess(pattern: NSRegularExpression, against: String, options: NSMatchingOptions = nil)  -> (NSString, [NSTextCheckingResult]?)
    {
        let nsString = against as NSString // Swift as of version 1.3 is schizo about String definitions in the context of NSRegularExpression; pls file Radar requests to support mine
        let results = pattern.matchesInString(against, options: options, range: NSMakeRange(0, count(against))) as? [NSTextCheckingResult]
        
        return (nsString, results)
    }
    
    func processExpression(against: String, options: NSMatchingOptions = nil) -> (NSString, [NSTextCheckingResult]?)
    {
        return internalProcess(getExpression(), against: against, options: options)
    }
    
    func matches(against: String, options: NSMatchingOptions = nil) -> Bool
    {
        let (target, matches) = processExpression(against, options: options)
        return matches != nil
    }
    
    func extractMatchesAsRanges(against: String, options: NSMatchingOptions = nil) -> (NSString, [NSRange])
    {
        let (target, matches) = processExpression(against, options: options)
        if (matches != nil)
        {
            let ranges = map(matches!) { $0.range}
            return (target, ranges)
        }
        else
        {
            return (target, [])
        }
    }
    
    func extractMatches(against: String, options: NSMatchingOptions = nil) -> [String]
    {
        let (target, ranges) = extractMatchesAsRanges(against, options: options)
        if (ranges.count > 0)
        {
            return map(ranges) { target.substringWithRange($0)}
        }
        else
        {
            return []
        }
    }
    
    func extractNumberedGroups(against: String, options: NSMatchingOptions = nil) -> [String]?
    {
        let (target, matches) = processExpression(against, options: options)
        if (matches != nil)
        {
            return map(matches!) { target.substringWithRange($0.rangeAtIndex(1))}
        }
        else
        {
            return []
        }
    }
    
}

// Standard results for Regex.extractMatches

struct RegexResult {
    
    var matchingText: String?
    var groupIndex: Int = 0
    var groupName: String? = ""
    var named: Bool {
        get {
            return (groupName == nil) ? false : !groupName!.isEmpty as Bool
        }
    }
}

// Helper class with accessors

struct RegexResults {
    
    var results: [RegexResult]
    
    init(fromResults: [RegexResult]) {
        self.results = fromResults
    }
    
    func getKey(key: String) -> String?
    {
        for result in self.results {
            if result.groupName == key {
                return result.matchingText
            }
        }
        return nil
    }
    
    func getKey(key: Int) -> String?
    {
        if key < self.results.count {
            return self.results[key].matchingText
        }
        return nil
    }
    
    func debug()
    {
        for result in self.results {
            let name = result.named ? " aka \"\(result.groupName!)\"" : ""
            let match = result.matchingText != nil ? result.matchingText! : ""
            println("Group \(result.groupIndex)\(name): \(match)")
        }
    }
    
}

class BetterRegex: BaseRegex {
    
    struct groupDefinition {
        let index: Int
        let contents: String
        let isNamed: Bool
        let name: String
    }
    
    var groups: [groupDefinition] = []
    
    func document() -> String
    {
        var results = ""
        var index = 0;
        for group in self.groups {
            ++index;
            results += "Group \(index): Index \(group.index) Contains \"\(group.contents)\" isNamed: \(group.isNamed) Name: '\(group.name)'\n"
        }
        results += "Simplified to \(self.pattern!)"
        return results
    }
    
    
    class func analyzeGroups(pattern: String) -> (String, [groupDefinition])
    {
        var results: [groupDefinition] = []
        var newPattern = pattern
        
        // Very naive pattern to extract capturing groups, I hope someone will develop something better
        let groupPattern = "\\((?!\\?:).+?\\)" // Unescaped pattern: \((?!\?:).+?\)
        let genericGroupAnalyzer = BaseRegex(pattern: groupPattern, options: nil) // Extract all groups, named or not
        
        let namedGroupNamePattern = "\\?<([A-Za-z]*?)>"
        let namedGroupPattern = "^\\(\(namedGroupNamePattern).+?\\)$" // Unescaped pattern: ^\(\?<([A-Za-z]*?)>.+?\)$
        let namedGroupAnalyser = BaseRegex(pattern: namedGroupPattern, options: nil)
        let namedGroupNameExtractor = BaseRegex(pattern: namedGroupNamePattern, options: nil)
        
        let rawGroups = genericGroupAnalyzer.extractMatches(pattern, options: nil)
        for (index, group) in enumerate(rawGroups) {
            
            var groupName = ""
            
            let groupCapture = namedGroupAnalyser.extractNumberedGroups(group, options: nil)
            if groupCapture?.count > 0
            {
                let candidateGroupName = groupCapture?.first! ?? ""
                if (!candidateGroupName.isEmpty) {
                    groupName = candidateGroupName
                    // We have the indexes, remove the capture group names from the pattern
                    let extractedName = namedGroupNameExtractor.extractMatches(group, options: nil).first
                    newPattern = newPattern.stringByReplacingOccurrencesOfString(extractedName!, withString: "")
                }
            }
            
            // FIXME: eventually deprecate groupIndex
            
            let definition = groupDefinition(index: index, contents: group, isNamed: !groupName.isEmpty, name: groupName)
            
            results.append(definition)
            
        }
        return (newPattern, results)
    }
    
    
    override init (pattern: String, options: NSRegularExpressionOptions = nil)
    {
        let (newPattern, groups) = BetterRegex.analyzeGroups(pattern)
        super.init(pattern: newPattern, options: options)
        self.groups = groups
    }
    
    func getGroupAtIndex(index: Int) -> groupDefinition
    {
        return self.groups[index]
    }
    
    func extractMatches(against: String, options: NSMatchingOptions) -> RegexResults {
        
        var results: [RegexResult] = []
        
        let (target, matches) = processExpression(against, options: options)
        
        if (matches != nil)
        {
            
            if (matches?.count > 0)
            {
                let match = matches?.first
                
                for index in 1 ... match!.numberOfRanges - 1  {
                    var newResult = RegexResult()
                    newResult.groupIndex = index
                    newResult.matchingText = target.substringWithRange(match!.rangeAtIndex(index))
                    let group = self.getGroupAtIndex(index - 1)
                    if (group.isNamed) { newResult.groupName = group.name }
                    results.append(newResult)
                }
                
            }
            
        }
        return RegexResults(fromResults: results)
    }
    
}
