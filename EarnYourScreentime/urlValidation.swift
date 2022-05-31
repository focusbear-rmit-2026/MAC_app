//
//  urlValidation.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 26/03/22.


import Foundation

struct urlValidation {
    func isUrlValid(urlToCheck:String, allowUrl:String, domain:String)->Bool{
        var bool = false
        var newAllowUrl = allowUrl
        if newAllowUrl.contains("http"){
            newAllowUrl = getDomainFromUrl(url: newAllowUrl)
        }
        if newAllowUrl.contains("file://"){
            if urlToCheck.contains("://"){
                bool = wildcard(urlToCheck, pattern: newAllowUrl)
            }
        }else{
            if newAllowUrl.contains("*"){
                bool = wildcard(domain, pattern: newAllowUrl)
            }else{
                let starUrl = "*" + newAllowUrl + "*"
                bool = wildcard(domain, pattern: starUrl)
            }
        }
        return bool
    }
    
}
