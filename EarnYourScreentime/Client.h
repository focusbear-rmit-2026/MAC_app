//
//  Client.h
//  Application
//
//  
//  
//

@import Foundation;

@interface Client : NSObject

/* PROPERTIES */

//pid
@property(nonatomic, retain)NSNumber* pid;

//message count
@property unsigned long long msgCount;

//client id
@property(nonatomic, retain)NSNumber* clientID;

//path
@property(nonatomic, retain)NSString* path;

//name
@property(nonatomic, retain)NSString* name;

@end

