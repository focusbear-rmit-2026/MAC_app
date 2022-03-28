//
//  urlValidation.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 26/03/22.
//  Copyright © 2022 MugPhotography. All rights reserved.
//

import Foundation

struct urlValidation {
    func isUrlValid(urlToCheck:String, allowUrl:String, domain:String)->Bool{
        var bool = false
        if allowUrl.contains("://"){
            if urlToCheck.contains("://"){
                bool = wildcard(urlToCheck, pattern: allowUrl)
            }
        }else{
            if allowUrl.contains("*"){
                bool = wildcard(domain, pattern: allowUrl)
            }else{
                let starUrl = "*" + allowUrl + "*"
                bool = wildcard(domain, pattern: starUrl)
            }
        }
        return bool
    }
    
}
