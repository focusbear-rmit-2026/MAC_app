
@import AVFoundation;
@import IOKit;

#import "AVMonitor.h"
#import "CoreFoundation/CFArray.h"
#import "IOKit/IOKitLib.h"
#import "IOKit/pwr_mgt/IOPMLibDefs.h"
#import "IOKit/pwr_mgt/IOPMKeys.h"
#import "Availability.h"

@implementation AVMonitor


//init
-(id)init
{

    
    //super
    self = [super init];
//    if(nil != self)
//    {
//        //init camera state
//        self.cameraState = -1;
//        self.cameraState = [self isACameraOn];
//    }
    
    return self;
}



-(NSDictionary*)getSystemAssertionDic
{
    @try {
        CFDictionaryRef assertionStates;
        IOReturn ret = IOPMCopyAssertionsByProcess(&assertionStates);
        if (kIOReturnSuccess != ret ) {
            return nil;
        }
        if (!assertionStates) {
            return nil;
        }
        NSDictionary *andBack = (__bridge NSDictionary*)assertionStates;
//        if (assertionStates)
//            CFRelease(assertionStates);
        
        return andBack;
    }
    @catch (NSException *exception) {
        return nil;
    }
    
}

//is (any) camera on?
-(BOOL)isACameraOn
{
//    CFDictionaryRef *AssertionsStatus;
//    IOPMCopyAssertionsStatus(AssertionsStatus);
    
    
    

//    CFDictionaryRef assertionStates;
//    IOReturn status = IOPMCopyAssertionsStatus(&assertionStates);
//    if (status == kIOReturnSuccess)
//    {
//        CFNumberRef count = CFDictionaryGetValue(assertionStates, kIOPMAssertionTypeNoDisplaySleep);
//        CFNumberRef count2 = CFDictionaryGetValue(assertionStates, kIOPMAssertionTypePreventUserIdleDisplaySleep);
//        long longCount = 0, longCount2 = 0;
//        if (count)
//            CFNumberGetValue(count, kCFNumberLongType, &longCount);
//        if (count2)
//            CFNumberGetValue(count2, kCFNumberLongType, &longCount2);
////        *(BOOL *)ptr_param = !longCount && !longCount2;
//        CFRelease(assertionStates);
//    }
//    else
//    {
////        WARN("Could not determine screen saver state, error code %d\n", status);
////        *(BOOL *)ptr_param = TRUE;
//    }
//
    
    //flag
    BOOL cameraOn = NO;
    
    //device's connection id
    unsigned int connectionID = 0;
    
    //dbg msg
    //os_log_debug(logHandle, "checking if any camera is active");
    
    //are any cameras currently on?
    NSArray<AVCaptureDevice *> *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for(AVCaptureDevice* currentCamera in devices)
    {
        //dbg msg
        //os_log_debug(logHandle, "device: %{public}@/%{public}@", currentCamera.manufacturer, currentCamera.localizedName);
        
        //get id
        connectionID = [self getAVObjectID:currentCamera];
        
        //get state
        // is (any) camera on?
        if(NSControlStateValueOn == [self getCameraStatus:connectionID])
        {
            //dbg msg
            //os_log_debug(logHandle, "device: %{public}@/%{public}@, is on!", currentCamera.manufacturer, currentCamera.localizedName);
            if([currentCamera.manufacturer  isEqual: @"Apple Inc."]){
                NSLog(@"%@", currentCamera.manufacturer);
                NSLog(@"%@", currentCamera.localizedName);
                
                //set
                cameraOn = YES;
                break;
            }

            
        }
    }
    
bail:
    
    return cameraOn;
}

//get built-in mic
-(AudioObjectID)findBuiltInMic
{
    //mic
    AudioObjectID builtInMic = 0;
    
    //look for mic that belongs to apple
    for(AVCaptureDevice* currentMic in [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio])
    {
        //dbg msg
        //os_log_debug(logHandle, "device: %{public}@/%{public}@", currentMic.manufacturer, currentMic.localizedName);
        
        //check if apple
        // also check input source
        if( (YES == [currentMic.manufacturer isEqualToString:@"Apple Inc."]) &&
            (YES == [[[currentMic activeInputSource] inputSourceID] isEqualToString:@"imic"]) )
        {
            //grab ID
            builtInMic = [self getAVObjectID:currentMic];
     
            //done
            break;
        }
    }
    
    //not found?
    // grab default
    if(0 == builtInMic)
    {
        //get mic / id
        builtInMic = [self getAVObjectID:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio]];
        
        //dbg msg
        //os_log_debug(logHandle, "Apple mic not found, defaulting to default (id: %d)", builtInMic);
    }
    
    return builtInMic;
}

//get av object's ID
-(UInt32)getAVObjectID:(AVCaptureDevice*)audioObject
{
    //object id
    AudioObjectID objectID = 0;
    
    //selector for getting device id
    SEL methodSelector = nil;

    //init selector
    methodSelector = NSSelectorFromString(@"connectionID");
    
    //sanity check
    if(YES != [audioObject respondsToSelector:methodSelector])
    {
        //bail
        goto bail;
    }
    
    //ignore leak warning
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    
    //grab connection ID
    objectID = (unsigned int)[audioObject performSelector:methodSelector withObject:nil];
    
    //restore
    #pragma clang diagnostic pop
    
bail:
    
    return objectID;
}

//is built-in mic on?
-(BOOL)isMicOn
{
    //flag
    BOOL isMicOn = NO;
    
    //mic's ID
    AudioObjectID builtInMic = 0;
    
    //dbg msg
    //os_log_debug(logHandle, "checking if built-in mic is active");
    
    //find mic
    builtInMic = [self findBuiltInMic];
    if( (0 != builtInMic) &&
        (NSControlStateValueOn == [self getMicState:builtInMic]) )
    {
        //dbg msg
        //os_log_debug(logHandle, "built-in mic is on");
        
        //set
        isMicOn = YES;
    }

    return isMicOn;
}
    

//determine if audio device is active
-(UInt32)getMicState:(AudioObjectID)deviceID
{
    //status var
    OSStatus status = -1;
    
    //running flag
    UInt32 isRunning = 0;
    
    //size of query flag
    UInt32 propertySize = 0;
    
    //init size
    propertySize = sizeof(isRunning);
    
    //query to get 'kAudioDevicePropertyDeviceIsRunningSomewhere' status
    status = AudioDeviceGetProperty(deviceID, 0, false, kAudioDevicePropertyDeviceIsRunningSomewhere, &propertySize, &isRunning);
    if(noErr != status)
    {
        //err msg
        //os_log_error(logHandle, "ERROR: getting status of audio device failed with %d", status);
        
        //set error
        isRunning = -1;
        
        //bail
        goto bail;
    }
    
bail:
    
    return isRunning;
}

//check if a specified video is active
// note: on M1 this always says 'on' (smh apple)
-(UInt32)getCameraStatus:(CMIODeviceID)deviceID
{
    //status var
    OSStatus status = -1;
    
    //running flag
    UInt32 isRunning = 0;
    
    //size of query flag
    UInt32 propertySize = 0;
    
    //property address struct
    CMIOObjectPropertyAddress propertyStruct = {0};
    
    //init size
    propertySize = sizeof(isRunning);
    
    //init property struct's selector
    propertyStruct.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere;
    
    //init property struct's scope
    propertyStruct.mScope = kCMIOObjectPropertyScopeGlobal;
    
    //init property struct's element
    propertyStruct.mElement = 0;
    
    //query to get 'kAudioDevicePropertyDeviceIsRunningSomewhere' status
    status = CMIOObjectGetPropertyData(deviceID, &propertyStruct, 0, NULL, sizeof(kAudioDevicePropertyDeviceIsRunningSomewhere), &propertySize, &isRunning);
    if(noErr != status)
    {
        //err msg
        //os_log_error(logHandle, "ERROR: failed to get camera status (error: %#x)", status);
        
        //set error
        isRunning = -1;
        
        //bail
        goto bail;
    }
    
    //dbg msg
    //os_log_debug(logHandle, "isRunning: %d", isRunning);

bail:
    
    return isRunning;
}

//-(BOOL)preventWindowFromBeingCaptured:(NSWindow *)window{
//    return RHPreventWindowCaptureForWindow(window);
//}
//
//
////define the private CGS methods we need to exclude a window from being captured.
//// ------ PRIVATE API ------
//typedef int CGSConnectionID;
//typedef int CGSWindowID;
//typedef CFTypeRef CGSRegionRef;
//
//CG_EXTERN CGSConnectionID CGSMainConnectionID(void);
//
//CG_EXTERN CGError CGSGetWindowBounds(CGSConnectionID cid, CGSWindowID wid, CGRect *rectOut);
//
//CG_EXTERN CGError CGSNewRegionWithRect(const CGRect *rect, CGSRegionRef *regionOut);
//CG_EXTERN bool CGSRegionIsEmpty(CGSRegionRef region);
//CG_EXTERN CGError CGSReleaseRegion(CGSRegionRef region);
//
//CG_EXTERN CGError CGSSetWindowCaptureExcludeShape(CGSConnectionID cid, CGSWindowID wid, CGSRegionRef region);
//// ------ END PRIVATE API ------
//
//
////implementation
//
//BOOL RHPreventWindowCaptureForWindow(NSWindow *window){
//    CGSConnectionID cid = CGSMainConnectionID();
//    CGSWindowID wid = (int)window.windowNumber;
//
//    CGRect windowRectOut;
//    CGError err = CGSGetWindowBounds(cid, wid, &windowRectOut);
//    if (err != kCGErrorSuccess){
//        NSLog(@"Error: failed to get windows bounds with error %i", err);
//        return NO;
//    }
//    windowRectOut.origin = CGPointZero;
//
//    CGSRegionRef regionOut;
//    err = CGSNewRegionWithRect(&windowRectOut, &regionOut);
//    if (err != kCGErrorSuccess){
//        NSLog(@"Error: failed to get create CGSRegion with error %i", err);
//        return NO;
//    }
//
//    //CFShow(regionOut);
//
//    err = CGSSetWindowCaptureExcludeShape(cid, wid, regionOut);
//    if (err != kCGErrorSuccess){
//        NSLog(@"Error: failed to set capture exclude shape for window with error %i", err);
//        CGSReleaseRegion(regionOut);
//        return NO;
//    }
//
//    CGSReleaseRegion(regionOut);
//
//    return YES;
//}
@end

@implementation NSNumberFormatter (Adding)








- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error



{



   NSCharacterSet *nonDigits = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789."] invertedSet];



   if ([partialString rangeOfCharacterFromSet:nonDigits].location != NSNotFound){



*error = @"Input is not an integer";



return (NO);



} else {



*error = nil;



return (YES);



   }


}
@end


