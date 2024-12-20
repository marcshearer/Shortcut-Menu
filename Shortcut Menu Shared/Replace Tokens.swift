//
//  Replace Tokens.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 17/12/2024.
//  Copyright © 2024 Marc Shearer. All rights reserved.
//

import Foundation

extension String {
    
    public func replacingTokens(tokenStart: Character = "{", tokenEnd: Character = "}") -> String {
        let (result, _) = self.processTokens(tokenStart: tokenStart, tokenEnd: tokenEnd)
        return result
    }
    
    public func referencedTokens(tokenStart: Character = "{", tokenEnd: Character = "}") -> Set<ReplacementViewModel> {
        let (_, references) = self.processTokens(tokenStart: tokenStart, tokenEnd: tokenEnd)
        return references
    }
    
    public func processTokens(tokenStart: Character = "{", tokenEnd: Character = "}") -> (String, Set<ReplacementViewModel>) {
        var references: Set<ReplacementViewModel> = []
        if let firstStart = self.firstIndex(where: {$0 == tokenStart}) {
            let left = self.subString(self.startIndex, self.indexBefore(firstStart))
            let right = self.subString(self.indexAfter(firstStart), self.indexBefore(self.endIndex))
            if let nextEnd = right.firstIndex(where: {$0 == tokenEnd}) {
                let nextStart = right.firstIndex(where: {$0 == tokenStart})
                if nextStart == nil || nextStart! > nextEnd {
                        // No open token before next close token - process the token
                    let firstToken = right.startIndex
                    let lastToken = right.index(before: nextEnd)
                    var replacementString = ""
                    if firstToken <= lastToken {
                        let token = right[firstToken...lastToken]
                        if let replacement = findReplacement(token: String(token)) {
                            references.formUnion(Set([replacement]))
                            var newReferences: Set<ReplacementViewModel> = []
                            (replacementString, newReferences) = replacement.replacement.processTokens(tokenStart: tokenStart, tokenEnd: tokenEnd)
                            references.formUnion(newReferences)
                        }
                    }
                    var fragment = ""
                    if let endIndex = right.indexBefore(right.endIndex) {
                        if nextEnd < endIndex {
                                // Token is not last part of string
                            var newReferences: Set<ReplacementViewModel> = []
                            (fragment, newReferences) = right.subString(indexAfter(nextEnd), endIndex).processTokens(tokenStart: tokenStart, tokenEnd: tokenEnd)
                            references.formUnion(newReferences)
                        }
                    }
                        // Return all the bits
                    return (left + replacementString + fragment, references)
                } else {
                        // Embedded token - process it first
                    let beforeFirstToken = left + String(tokenStart)
                    let startOfFirstToken = right.subString(right.startIndex, right.indexBefore(nextStart!))
                    let (remainder, remainderReferences) = right.subString(nextStart!, right.indexBefore(right.endIndex)).processTokens(tokenStart: tokenStart, tokenEnd: tokenEnd)
                    references.formUnion(remainderReferences)
                    let (result, resultReferences) = (beforeFirstToken + startOfFirstToken + remainder).processTokens(tokenStart: tokenStart, tokenEnd: tokenEnd)
                    references.formUnion(resultReferences)
                    return (result, references)
                }
            } else {
                    // No remaining token ends - just return string
                return (self, [])
            }
        } else {
                // No remaining token starts - just return string
            return (self, [])
        }
    }
    
    private func findReplacement(token: String) -> ReplacementViewModel? {
        return MasterData.shared.replacements.first(where: {$0.token == token})
    }
    
    public func indexBefore(_ index: Self.Index) -> Self.Index? {
        if index <= self.startIndex {
            return nil
        } else {
            return self.index(before: index)
        }
    }
    
    public func indexAfter(_ index: Self.Index) -> Self.Index? {
        if index >= self.endIndex {
            return nil
        } else {
            return self.index(after: index)
        }
    }
    
    public func subString(_ from: Self.Index?, _ to: Self.Index?) -> String {
        if let from = from, let to = to {
            if from <= to {
                return String(self[from...to])
            }
        }
        return ""
    }
}
