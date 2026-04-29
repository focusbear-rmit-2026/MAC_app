//
//
//  Focus Bear
//
//  Created by Prashant Sawnani on 04/07/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//


// notes


// focus mode auto finish hota h to sirf finish ka log likhvate hai.   jabki agar focus mode abort hota h to abort ka log likhvate hai lekin ager focus abort mai reason( i achived what i want ) select kiya hai to 2 log likhavte hai abort ka or finish ka dono ka qki is case mai focus finished vali screen bhi aaaati h or vha se finish vala nag bhi likhvate hai


// 4 hour app deactivate k case mai evening habit or shutoff or focus summary aata h
//lekin agar kisi se focus summary ya evening habit ko 4 hour app deactivate kiyta h to sirf shutoff ayga, focus summary 4 hour deactivate se evening routine bhi skip hogi

// note break activity postpone krke sleep mac akrte h to mac jagne k baad break activity   normal timer lgega
//todo always check releas notes in updae build xml


//todo always add new search items in search
// always seet new height if new item added in preferences
//there will be no habit display on first day


//annnoying things
//showing pomodoro window again if user close pomodoro window 1fter 10 minutes


/*
blockpage params
 
 1. block page :-
 
 if isCurrentUrlAllowedInFocsMode{
     if isAnyAllowedFocusModeActivityRunning(habit focusmode) == true{
         block_type="morning-habit" / "evening-habit" / "special-activity"
         block_mode = "cuddly" / "grizzly"
     
         if currentFocusModeStrictness != ._SUPER_STRICT_{
            cuddly_bear_mode=true
            reason=The website URL is allowed in focus mode.
         }

      }else{
        let focusModeExpiryTimeString = "&focus_mode_end_time=\(stringTime)"
        focus_mode_end_time=Time
        focus_mode=focusMode
        focus_mode_intention=intention
         if currentFocusModeStrictness != ._SUPER_STRICT_{
            cuddly_bear_mode=true
            reason=The website URL is allowed in focus mode.
         }
      }
 
 }else{
     block_type=always-blocked
     block_mode = "cuddly" / "grizzly"
     if shouldShowTour{
        &show_tour=true
     }
}


 
 2. focus mode:-
 
 focus_mode_end_time=Time
 focus_mode=focusMode
 focus_mode_intention=intention
 if currentFocusModeStrictness != ._SUPER_STRICT_{
    cuddly_bear_mode=true
    reason=AIREASON
 }
 
  
 habit:-
     block_type=morning-habit/evening-habit/special-activity
 
 
 
 habit focusmode:-
 
    block_type="morning-habit" / "evening-habit" / "special-activity"
 if settings cuddly mode is enabled){
    cuddly_bear_mode=true
    reason=AIREASON
 }
  
 if isRunningAppFullScreen || isStageManagerEnabled{
     confirm_ai_distracting_url=true
 }
 version=1.20.351
 encouraging_info
 old_url
 
*/
//file:///Users/prashant/Library/Application%20Support/com.App.EarnYourScreentime/focus-block.html?old_url=https%3A%2F%2Fwww.facebook.com%2F&block_type=always-blocked&block_mode=cuddly&encouraging_info=%7B%0A%20%20%22long_term_goals%22%20%3A%20%5B%0A%20%20%20%20%22Meditate%20consistently%22%0A%20%20%5D,%0A%20%20%22focused_time%22%20%3A%201799.992%0A%7D&version=1.20.351


// old supublicedkey  tdVYiEz/MSjLl07DnhYNXOqHrNS7Tf/j5aCtwR/Tt6s=

//                Application is agent (UIElement)// added on info plist because without it launch agent making problems (not allowing to remove app icon by this:- NSApp.setActivationPolicy(NSApplication.ActivationPolicy.accessory) with launc agent so adding this info plist) 28/5/25


//https://focus-bear.sentry.io/issues/?project=4509122992275456&statsPeriod=1h // sentry 






//ISSUES//


// focus bear settings showing wrong information :- it shows activity is office friendly but in realty it was non office friendly activity
// wrong tab blocked not found
// edit routine alert not showing when user is doing edit routin from morning/ evening



// from v 2.28.450 app alwaus show cuddly mode popups during focus mode even afater focus mode is in super strit mode


//        if UserDefaults.standard.object(forKey: kUserdefaultsDontShowToolBoxAutomatically) as? Bool == false{removed on 1/9/25  on version 2.27.408
