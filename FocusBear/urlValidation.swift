//
//  urlValidation.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/03/22.


import Foundation

struct urlValidation {
    func isUrlValid(urlToCheck:String, allowUrl:String, domain:String)->Bool{
        var bool = false
        var newAllowUrl = allowUrl
        var newUrlToCheck = urlToCheck
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
            
            newAllowUrl = "*" + newAllowUrl + "*"
            bool = wildcard(newUrlToCheck, pattern: newAllowUrl)
            
//            if newAllowUrl.contains("*"){
//                newAllowUrl = newAllowUrl + "*"
//                bool = wildcard(newUrlToCheck, pattern: newAllowUrl)
//            }else{
//                var starUrl: String = ""
//                if newAllowUrl.contains("."){
//                    starUrl = newAllowUrl + "*"
//                }else{
//                    starUrl = "*" + newAllowUrl + "*"
//                }
//                bool = wildcard(newUrlToCheck, pattern: starUrl)
//            }
        }
        return bool
    }
    
}
