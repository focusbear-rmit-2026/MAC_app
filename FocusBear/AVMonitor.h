//
//  AVMonitor.h
//  Application
//
//  
//  
//

@import Cocoa;
@import Foundation;



#import <CoreMediaIO/CMIOHardware.h>




@interface AVMonitor : NSObject

//microphone state
@property NSControlStateValue microphoneState;



/* METHODS */

-(BOOL)isMicOn;
-(NSDictionary *)microphoneStatus;
-(BOOL)isACameraOn;
-(NSDictionary*)getSystemAssertionDic;
//checkCameraState
//-(BOOL)preventWindowFromBeingCaptured:(NSWindow *)window;

@end


@interface NSNumberFormatter (Adding)


@end
