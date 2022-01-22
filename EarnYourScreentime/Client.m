//
//  Client.m
//  Application
//
//  
//  
//

#import "Client.h"

@implementation Client

//override description method
-(NSString*)description
{
    //description
    return [NSString stringWithFormat:@"CLIENT: pid: %@, path: %@, clientID: %@", self.pid, self.path, self.clientID];
}

@end
