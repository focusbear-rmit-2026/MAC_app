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
-(BOOL)isACameraOn;

//checkCameraState


@end

