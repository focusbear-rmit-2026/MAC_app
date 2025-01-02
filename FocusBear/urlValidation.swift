//
//  urlValidation.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/03/22.


import Foundation

struct urlValidation {
    func isUrlValid(urlToCheck:String, allowUrl:String)->Bool{
        var bool = false
        var newAllowUrl = allowUrl.lowercased()
        var newUrlToCheck = urlToCheck.lowercased()
        newAllowUrl = newAllowUrl.replacingOccurrences(of: "http://", with: "")
        newAllowUrl = newAllowUrl.replacingOccurrences(of: "https://", with: "")
        
        newUrlToCheck = newUrlToCheck.replacingOccurrences(of: "http://", with: "")
        newUrlToCheck = newUrlToCheck.replacingOccurrences(of: "https://", with: "")
        
        
        if newAllowUrl.contains("www."){
            newAllowUrl = newAllowUrl.replacingOccurrences(of: "www.", with: "")
        }
        
        if newUrlToCheck.contains("www."){
            newUrlToCheck = newUrlToCheck.replacingOccurrences(of: "www.", with: "")
        }

        if newAllowUrl.contains("file://"){
            if urlToCheck.contains("://"){
                bool = wildcard(urlToCheck, pattern: newAllowUrl)
            }
        }else{
            let urlFromList = newAllowUrl
            newAllowUrl = "*" + newAllowUrl + "*"
            bool = wildcard(newUrlToCheck, pattern: newAllowUrl)
            
//            Improve x.com in blocked list #1209
            if bool{
                if urlFromList == "x.com"{
                    if newUrlToCheck.contains(s: urlFromList){
                        let result = hasLetterBefore(substring: urlFromList, in: newUrlToCheck)
                        if result {
                            bool = false
                        }
                    }
                }
            }
        }
        return bool
    }
    
    //Change all suggested blocked apps in onboarding to start with https:// #1233
    func isUrlAlwaysBlocked(urlToCheck:String, blockedUrl:String)->Bool{
        var bool = false
        var newBlockedUrl = blockedUrl.lowercased()
        var newUrlToCheck = urlToCheck.lowercased()
        newBlockedUrl = newBlockedUrl.replacingOccurrences(of: "http://", with: "")
        newBlockedUrl = newBlockedUrl.replacingOccurrences(of: "https://", with: "")
        
        newUrlToCheck = newUrlToCheck.replacingOccurrences(of: "http://", with: "")
        newUrlToCheck = newUrlToCheck.replacingOccurrences(of: "https://", with: "")
        
        
        if newBlockedUrl.contains("www."){
            newBlockedUrl = newBlockedUrl.replacingOccurrences(of: "www.", with: "")
        }
        
        if newUrlToCheck.contains("www."){
            newUrlToCheck = newUrlToCheck.replacingOccurrences(of: "www.", with: "")
        }

        if newBlockedUrl.contains("file://"){
            if urlToCheck.contains("://"){
                bool = wildcard(urlToCheck, pattern: newBlockedUrl)
            }
        }else{
            if newBlockedUrl.contains("."){
                newBlockedUrl = newBlockedUrl + "*"
                bool = wildcard(newUrlToCheck, pattern: newBlockedUrl)
            }else{// keyword
                newBlockedUrl = "*" + newBlockedUrl + "*"
                bool = wildcard(newUrlToCheck, pattern: newBlockedUrl)
            }
        }
        return bool
    }
    
    
}


func hasLetterBefore(substring: String, in mainString: String) -> Bool {
    // Check if the substring exists in the main string
    guard let range = mainString.range(of: substring) else {
        return false
    }
    
    // Find the index of the character just before the substring
    let beforeSubstringIndex = range.lowerBound
    if beforeSubstringIndex > mainString.startIndex {
        let precedingCharacterIndex = mainString.index(before: beforeSubstringIndex)
        // Check if the character before the substring is a letter
        return mainString[precedingCharacterIndex].isLetter
    }
    
    return false
}
