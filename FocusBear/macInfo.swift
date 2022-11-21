//
//  macInfo.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 03/10/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Foundation


var macAddress = GetMACAddressString()
func GetMACAddressString() -> String {
   if let intfIterator = FindEthernetInterfaces() {
       if let macAddress = GetMACAddress(intfIterator) {
           let macAddressAsString = macAddress.map( { String(format:"%02x", $0) } )
               .joined(separator: ":")
           return macAddressAsString
       }
       IOObjectRelease(intfIterator)
   }
   return ""
}
func FindEthernetInterfaces() -> io_iterator_t? {
   
   let matchingDict = IOServiceMatching("IOEthernetInterface") as NSMutableDictionary
   matchingDict["IOPropertyMatch"] = [ "IOPrimaryInterface" : true]
   
   var matchingServices : io_iterator_t = 0
   if IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &matchingServices) != KERN_SUCCESS {
       return nil
   }
   
   return matchingServices
}
func GetMACAddress(_ intfIterator : io_iterator_t) -> [UInt8]? {
   
   var macAddress : [UInt8]?
   
   var intfService = IOIteratorNext(intfIterator)
   while intfService != 0 {
       
       var controllerService : io_object_t = 0
       if IORegistryEntryGetParentEntry(intfService, "IOService", &controllerService) == KERN_SUCCESS {
           
           let dataUM = IORegistryEntryCreateCFProperty(controllerService, "IOMACAddress" as CFString, kCFAllocatorDefault, 0)
           if let data = dataUM?.takeRetainedValue() as? NSData {
               macAddress = [0, 0, 0, 0, 0, 0]
               data.getBytes(&macAddress!, length: macAddress!.count)
           }
           IOObjectRelease(controllerService)
       }
       
       IOObjectRelease(intfService)
       intfService = IOIteratorNext(intfIterator)
   }
   
   return macAddress
}
