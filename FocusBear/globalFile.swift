//
//  globalFile.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa
//import IOKit
import IOKit.pwr_mgt
import SystemConfiguration// for check internet availibility code

let mainStoryboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
let mainWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("mainWindowController")) as? mainWindowController
let mainViewControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("ViewController")) as? ViewController
let firstViewControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("firstViewController")) as? firstViewController

let timerViewcontrollerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("timerViewcontroller")) as? timerViewcontroller

var discourageDefaultFocusVcObj:discourageDefaultFocusVc?
func getDiscourageDefaultFocusVcObject()->discourageDefaultFocusVc{
    if discourageDefaultFocusVcObj == nil{
        discourageDefaultFocusVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("discourageDefaultFocusVc")) as? discourageDefaultFocusVc
    }
    return discourageDefaultFocusVcObj!
}
var quittingWcObj:commonWindowController?
func getQuittingWindowObject()->commonWindowController{
    if quittingWcObj == nil{
        quittingWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
    }
    return quittingWcObj!
}

var visualizeInstructionsVcObj:visualizeInstructionsVc?
func getvisualizeInstructionsObject()->visualizeInstructionsVc{
    if visualizeInstructionsVcObj == nil{
        visualizeInstructionsVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("visualizeInstructionsVc")) as? visualizeInstructionsVc
    }
    return visualizeInstructionsVcObj!
}

var quitCountDownVcObj:quitCountDownVc?
func getQuittingCountDownVcObject()->quitCountDownVc{
    if quitCountDownVcObj == nil{
        quitCountDownVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("quitCountDownVc")) as? quitCountDownVc
    }
    return quitCountDownVcObj!
}



var askPostponeVcObj:askPostponeVc?
func getAskPostponeVcObject()->askPostponeVc{
    if askPostponeVcObj == nil{
        askPostponeVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askPostponeVc")) as? askPostponeVc
    }
    return askPostponeVcObj!
}

var smallCountDownVcObj:smallCountDownVc?
func getsmallCountDownVcObject()->smallCountDownVc{
    if smallCountDownVcObj == nil{
        smallCountDownVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("smallCountDownVc")) as? smallCountDownVc
    }
    return smallCountDownVcObj!
}

var smallCountDownWcObj:commonWindowController?
func getSmallCountDownWindowObject()->commonWindowController{
    if smallCountDownWcObj == nil{
        smallCountDownWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        smallCountDownWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.popUpMenuWindow)))
    }
    return smallCountDownWcObj!
}

var quittingConfirmVcObj:quittingConfirmVc?

func getQuittingConfirmVcObject()->quittingConfirmVc{
    if quittingConfirmVcObj == nil{
        quittingConfirmVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("quittingConfirmVc")) as? quittingConfirmVc
    }
    return quittingConfirmVcObj!
}


let thirdVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("thirdVc")) as? thirdVc

//let selectJsonWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("selectJsonWindowController")) as? selectJsonWindowController
var selectJsonVcObj:selectJsonVc?// = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("selectJsonVc")) as? selectJsonVc
let shutOffTimeVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("shutOffTimeVc")) as? shutOffTimeVc

let abortingCountDownVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortingCountDownVc")) as? abortingCountDownVc
let abortingConfirmVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortingConfirmVc")) as? abortingConfirmVc
let abortDoneVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortDoneVc")) as? abortDoneVc

let activationWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("activationWindowController")) as? activationWindowController

let sevenDaysTrialvcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("sevenDaysTrialvc")) as? sevenDaysTrialvc
let activateNowvcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("activateNowvc")) as? activateNowvc

let abortingCantHandleVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortingCantHandleVc")) as? abortingCantHandleVc
let logQuantityVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("logQuantityVc")) as? logQuantityVc

let preferencesWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("preferencesWindowController")) as? preferencesWindowController

let menuViewControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("menuViewController")) as? menuViewController

//let focusPreferencesWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusPreferencesWc")) as? focusPreferencesWc
var focusPreferencesVcObj:focusPreferencesVc?// = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusPreferencesVc")) as? focusPreferencesVc
var blockedUrlsVcObj:blockedUrlsVc?

let addWebUrlVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("addWebUrlVc")) as? addWebUrlVc
let addFocusTypeVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("addFocusTypeVc")) as? addFocusTypeVc

let pomodoroWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("pomodoroWindowController")) as? pomodoroWindowController
let pomodoroVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("pomodoroVc")) as? pomodoroVc
let focusCompletedVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusCompletedVc")) as? focusCompletedVc


let startingFocusWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController


var endingFocusWindowControllerObj: commonWindowController?

func getEndFocusModeWindowControllerObj()->commonWindowController{
    if endingFocusWindowControllerObj == nil{
        endingFocusWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        endingFocusWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.popUpMenuWindow)))
    }
    return endingFocusWindowControllerObj!
}
var rememberNextHabitVcObj:rememberNextHabitVc?

func getRememberNextHabitVcObj()->rememberNextHabitVc{
    if rememberNextHabitVcObj == nil{
        rememberNextHabitVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("rememberNextHabitVc")) as? rememberNextHabitVc
    }
    return rememberNextHabitVcObj!
}


let startingFocusModeVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("startingFocusModeVc")) as? startingFocusModeVc
let abortingFocusModeVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortingFocusModeVc")) as? abortingFocusModeVc

let focusSummaryVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusSummaryVc")) as? focusSummaryVc


let enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as?enterPasswordVc

var focusPreferencesAdvancedVcObj:focusPreferencesAdvancedVc?

let appdelegate = NSApplication.shared.delegate as? AppDelegate

var SettingsManagerObject = SettingsManager()

var isHardCorePomodoroModeOn = false
var hardcodePmodoroFocusModeIndex = 0
var totalMinutesRemainingForHardcodePomodoro = 0
var currentPomodoroWorkDuration = 25
var currentPomodoroBreakDuration = 5
var totalPomodoroCountInHardCorePomodoro = 0
var completedPomodoroCountInHardcorePomodoro = 0

var activityPostponeCount = 0
//var isMorningRoutinePostpone = false


var isPromptToRememberHabitShowedInLastHabit = false///   reason:-Make sure it doesn't happen twice in a row though. 

var configjson = NSDictionary()


var currentDeviceId = ""
let kUserdefaultsDeviceId = "kUserdefaultsDeviceId"

let kUserdefaultsSelectedJson = "kUserdefaultsSelectedJson"

let kUserdefaultsFirstRunDate = "kUserdefaultsFirstRunDate"
let kUserdefaultsLastHabitShowDate = "UserdefaultsLastHabitShowDate"
var kUserdefaultsIsAppEnabled = "kUserdefaultsIsAppEnabled"
var kUserdefaults4HourReActivateTime = "kUserdefaults4HourReActivateTime"
var kUserdefaultsShutdownAborted = "kUserdefaultsShutdownAborted"
var kUserdefaultsEveningHabitsShowedTillDate = "kUserdefaultsEveningHabitsShowedTillDate"//agar evening habit ak bar show ho gai h to agle din start habit tk ki date save kr lenge taki jab bhi vps shut off ho same day hi to evening habit vapas na aay
var kUserdefaultsFocusSummaryShowedTillDate = "kUserdefaultsFocusSummaryShowedTillDate"//agar Focus Summary ak bar show ho gai h to agle din start habit tk ki date save kr lenge taki jab bhi vps shut off ho same day hi to Focus Summary vapas na aay

let kUserdefaultsFirstHabitDay = "kUserdefaultsFirstHabitDay"
var isAppInitialLodded = false// activation kha se show hua h menu se ya startup per iske liye iska use krenge 

let kIsPurchased = "kIsPurchased"
let kRegisteredLicenseKey = "kRegisteredLicenseKey"

var kUserdefaultsSelectedFolder = "kUserdefaultsSelectedFolder"

let kUserdefaultsArrFocusTypes = "kUserdefaultsArrFocusTypes"


var kUserdefaults24HoursClearPasswordTime = "kUserdefaults24HoursClearPasswordTime"

var isAppEnable = true
var startTime:Time?
var shutOffTime:Time?


var isMainWindowLodded = false
var isPomodoroWindowLodded = false
var isHabitAlreadyShowed = true
var isFirstRun = false

var lastActivityPerformedTime:Date?
struct Time{
    var hour = 0
    var minute = 0
    var second = 0
}

extension NSView{
    func addConstraints(subView:NSView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        //Trailing
        let trailing = NSLayoutConstraint(item: subView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        //Leading
        let leading = NSLayoutConstraint(item: subView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0)
        //Bottom
        let bottom = NSLayoutConstraint(item: subView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        //Height to be fixed for SubView same as AdHeight
        let height = NSLayoutConstraint(item: subView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0)
        self.addConstraint(trailing)
        self.addConstraint(bottom)
        self.addConstraint(leading)
        //Add height constraint to the subview, as subview owns it.
        self.addConstraint(height)
    }
}
//var isBreathingGoing = false
//var isHabitGoing = false
//var isBreakActivitiesGoing = false


var currentHabitIndex = -1
var currentActivityIndex = -1
var currentActivityPlaying:breakActivity?
var currentHabitPlaying:habit?


var arrAllMorningHabits = [habit]()
var arrAllEveningHabits = [habit]()
struct habit {
    var id:String!
    var name:String!
    var durationSeconds:Int!
    var urlsArray:[String]
    var logQuantity:Bool!
    var logQuantityQuestion:String?
    var openSpecificApps:Bool!
    var allowUrls:[String]!
    var allowApps:[String]!
    var allowedFocusMode:String!
    var activity_sequence_id:String!
    init(id:String, name:String, durationSeconds:Int, urlsArray:[String], logQuantity:Bool, logQuantityQuestion:String?, openSpecificApps:Bool,allowUrls:[String],allowApps:[String],allowedFocusMode:String, activity_sequence_id:String) {
        self.id = id
        self.name = name
        self.durationSeconds = durationSeconds
        self.urlsArray = urlsArray
        self.logQuantity = logQuantity
        self.logQuantityQuestion = logQuantityQuestion
        self.openSpecificApps = openSpecificApps
        self.allowUrls = allowUrls
        self.allowApps = allowApps
        self.allowedFocusMode = allowedFocusMode
        self.activity_sequence_id = activity_sequence_id
    }
}




var introActivity:habit?

func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
    return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
}
func getStringTimeFromSeconds(seconds : Int)->String{
    let (h,m,s) = secondsToHoursMinutesSeconds(seconds: seconds)
    var stringTime: String = ""
    if h != 0{
        stringTime = "\(h)h"
    }
    if m != 0{
        if stringTime.isEmpty{
            stringTime = "\(m)m"
        }else{
            stringTime += " \(m)m"
        }
    }
    if s != 0{
        if stringTime.isEmpty{
            stringTime = "\(s)s"
        }else{
            stringTime += " \(s)s"
        }
    }
    return stringTime
}
var activityAllowedFocusApps = [String]()
var activityAllowedFocusUrls = [String]()
//var showEveryBreak = false
var isAnyMandatoryActivityIncluded = false
var isMandatoryActivityGoing = false
var breakAfterMinutes = 0
var arrAllbreakActivities = [breakActivity]()
var arrActivitiesIncludeInEveryBreak = [breakActivity]()
var arrActivitiesExcludeInEveryBreak = [breakActivity]()
struct breakActivity {
    var id:String!
    var name:String!
    var durationSeconds:Int!
    var IncludeInEveryBreak:Bool!
    var urlsArray:[String]
    var logQuantity:Bool!
    var isRandomChoice:Bool!
    var choices:[activityChoice]
    var logQuantityQuestion:String?
    var openSpecificApps:Bool!
    var allowUrls:[String]!
    var allowApps:[String]!
    var isOfficeFriendly:Bool!
    var allowedFocusMode:String!
    var logQuantityType:String!
    var activity_sequence_id:String!
    init(id:String, name:String, durationSeconds:Int, IncludeInEveryBreak:Bool, urlsArray:[String], logQuantity:Bool,isRandomChoice:Bool,choices:[activityChoice],logQuantityQuestion:String?, openSpecificApps:Bool,allowUrls:[String],allowApps:[String],isOfficeFriendly:Bool,allowedFocusMode:String,logQuantityType:String,activity_sequence_id:String) {
        self.id = id
        self.name = name
        self.durationSeconds = durationSeconds
        self.IncludeInEveryBreak = IncludeInEveryBreak
        self.urlsArray = urlsArray
        self.logQuantity = logQuantity
        self.isRandomChoice = isRandomChoice
        self.choices = choices
        self.logQuantityQuestion = logQuantityQuestion
        self.openSpecificApps = openSpecificApps
        self.allowUrls = allowUrls
        self.allowApps = allowApps
        self.isOfficeFriendly = isOfficeFriendly
        self.allowedFocusMode = allowedFocusMode
        self.logQuantityType = logQuantityType
        self.activity_sequence_id = activity_sequence_id
    }
}


struct activityChoice {
    var id:String!
    var name:String!
    var urlsArray:[String]
    var logQuantityQuestion:String!
    var logQuantity:Bool!
    var logQuantityType:String!
    init(name:String, urlsArray:[String], logQuantityQuestion:String, logQuantity:Bool, logQuantityType:String, id:String) {
        self.id = id
        self.name = name
        self.urlsArray = urlsArray
        self.logQuantityQuestion = logQuantityQuestion
        self.logQuantity = logQuantity
        self.logQuantityType = logQuantityType
    }
}

let avmonitor = AVMonitor()

//////////////////////////////////////////////////////////START AT LOGIN//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class LaunchOnStartup {//todo
    static func itemReferencesInLoginItems() -> (existingReference: LSSharedFileListItem?, lastReference: LSSharedFileListItem?) {
        let appUrl = URL(fileURLWithPath: Bundle.main.bundlePath)
        let loginItemsRef = LSSharedFileListCreate(
            nil,
            kLSSharedFileListSessionLoginItems.takeRetainedValue(),
            nil
        )!.takeRetainedValue() as LSSharedFileList?
        if loginItemsRef != nil {
            let loginItems = LSSharedFileListCopySnapshot(loginItemsRef!, nil)!.takeRetainedValue() as Array
            
            if loginItems.count == 0 {
                return (nil, kLSSharedFileListItemBeforeFirst.takeRetainedValue())
            }
            
            let lastItemRef: LSSharedFileListItem = loginItems.last as! LSSharedFileListItem
            
            for currentItemRef in loginItems as! [LSSharedFileListItem] {
                if let itemUrl = LSSharedFileListItemCopyResolvedURL(currentItemRef, 0, nil) {
                    if (itemUrl.takeRetainedValue() as URL) == appUrl {
                        return (currentItemRef, lastItemRef)
                    }
                }
            }
            
            return (nil, lastItemRef)
        }
        return (nil, nil)
    }
    
    static func setLaunchAtStartup(_ shouldLaunch: Bool) {
        
        let itemReferences = itemReferencesInLoginItems()
        let alreadyExists = (itemReferences.existingReference != nil)
        let loginItemsRef = LSSharedFileListCreate(
            nil,
            kLSSharedFileListSessionLoginItems.takeRetainedValue(),
            nil
        )!.takeRetainedValue() as LSSharedFileList?
        
        if loginItemsRef != nil
        {
            if shouldLaunch
            {
                if !alreadyExists
                {
                    
                    let appUrl = URL(fileURLWithPath: Bundle.main.bundlePath) as CFURL
                    LSSharedFileListInsertItemURL(
                        loginItemsRef!,
                        itemReferences.lastReference!,
                        nil,
                        nil,
                        appUrl,
                        nil,
                        nil
                    )
                }
            }
            else
            {
                if alreadyExists
                {
                    let WTLObject: addLoginitem = addLoginitem()
                    //                    let WTLMemoryObject: WTLMemory = WTLMemory()
                    let deletitem=WTLObject.itemRefInLoginItems()
                    print(deletitem)
                    
                    
                }
            }
            
        }
    }
}


class cursorButton: NSButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
    }
    
    override func mouseEntered(with event: NSEvent) {
        NSCursor.pointingHand.set()
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
    }
}

class underLineButton: cursorButton {
    
    
    func setDisable(title:String){
        isEnabled = false
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs = [NSAttributedString.Key.foregroundColor: NSColor.secondaryLabelColor, NSAttributedString.Key.paragraphStyle: paragraph, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue] as [NSAttributedString.Key : Any]
        let attrString: NSAttributedString = NSAttributedString(string: title, attributes: attrs)
        self.attributedTitle = attrString
    }
    
    func setEnable(title:String){
        isEnabled = true
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs = [NSAttributedString.Key.foregroundColor: NSColor.labelColor, NSAttributedString.Key.paragraphStyle: paragraph, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue] as [NSAttributedString.Key : Any]
        let attrString: NSAttributedString = NSAttributedString(string: title, attributes: attrs)
        self.attributedTitle = attrString
    }
    
    override var title: String {
        didSet {
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let attrs = [NSAttributedString.Key.foregroundColor: NSColor.labelColor, NSAttributedString.Key.paragraphStyle: paragraph, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue] as [NSAttributedString.Key : Any]
            let attrString: NSAttributedString = NSAttributedString(string: title, attributes: attrs)
            self.attributedTitle = attrString
        }
    }
}





extension Date {
    
    /// Create a date from specified parameters
    ///
    /// - Parameters:
    ///   - year: The desired year
    ///   - month: The desired month
    ///   - day: The desired day
    /// - Returns: A `Date` object
    static func from(year: Int, month: Int, day: Int, hour:Int, minute:Int, second:Int) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = year
        dateComponents.minute = month
        dateComponents.second = day
        return calendar.date(from: dateComponents) ?? nil
    }
}
func getTimeFromString(val:String)->Time{
    let timearr = val.components(separatedBy: ":")
    var hour = 0
    var minute = 0
    var second = 0
    if timearr.count == 3{
        hour = Int(timearr[0]) ?? 0
        minute = Int(timearr[1]) ?? 0
        second = Int(timearr[2]) ?? 0
    }else if timearr.count == 2{
        hour = Int(timearr[0]) ?? 0
        minute = Int(timearr[1]) ?? 0
    }else if timearr.count == 1{
        hour = Int(timearr[0]) ?? 0
    }
    return Time(hour: hour, minute: minute, second: second)
}
extension Date {
    
    func fullDistance(from date: Date, resultIn component: Calendar.Component, calendar: Calendar = .current) -> Int? {
        calendar.dateComponents([component], from: self, to: date).value(for: component)
    }
    
    func distance(from date: Date, only component: Calendar.Component, calendar: Calendar = .current) -> Int {
        let days1 = calendar.component(component, from: self)
        let days2 = calendar.component(component, from: date)
        return days1 - days2
    }
    
    func hasSame(_ component: Calendar.Component, as date: Date) -> Bool {
        distance(from: date, only: component) == 0
    }
}

class CustomTextField: NSTextField, NSTextViewDelegate {
    override func rightMouseDown(with event: NSEvent) {
        
    }
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        return nil
    }
    private let commandKey = NSEvent.ModifierFlags.command.rawValue
    private let commandShiftKey = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        //        if event.type == NSEvent.EventType.keyDown {
        //            if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
        //                switch event.charactersIgnoringModifiers! {
        //                case "x":
        //                    if NSApp.sendAction(#selector(NSText.cut(_:)), to:nil, from:self) { return true }
        //                case "c":
        //                    if NSApp.sendAction(#selector(NSText.copy(_:)), to:nil, from:self) { return true }
        //                case "v":
        //                    if NSApp.sendAction(#selector(NSText.paste(_:)), to:nil, from:self) { return true }
        //                case "z":
        //                    if NSApp.sendAction(Selector(("undo:")), to:nil, from:self) { return true }
        //                case "a":
        //                    if NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to:nil, from:self) { return true }
        //                default:
        //                    break
        //                }
        //            }
        //            else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandShiftKey {
        //                if event.charactersIgnoringModifiers == "Z" {
        //                    if NSApp.sendAction(Selector(("redo:")), to:nil, from:self) { return true }
        //                }
        //            }
        //        }
        NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
        return false
    }
}
class ignoreMouseTextField: NSTextField, NSTextViewDelegate {
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
}

class PasteView: NSTextView, NSTextViewDelegate {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func paste(_ sender: Any?) {
        Swift.print("user tries to paste")
        // super.pasteAsPlainText(nil)
    }
}
class CustomWindow: NSWindow {//bacause titleless window per textfield kaam ni kar rhi
    override var canBecomeKey: Bool{
        return true
    }
}

func attechIconWithString(text:String)->NSMutableAttributedString{
    if text.localizedCaseInsensitiveContains("<icon>"){
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs = [NSAttributedString.Key.foregroundColor: NSColor.labelColor, NSAttributedString.Key.paragraphStyle: paragraph]
        let arr = text.components(separatedBy: "<icon>")
        let mainstr =  NSMutableAttributedString()
        for i in 0..<arr.count{
            let string = arr[i]
            if !string.isEmpty{
                let str = NSMutableAttributedString(string: string, attributes: attrs)
                if i != arr.count - 1{
                    let attachmentCell: NSTextAttachmentCell = NSTextAttachmentCell.init(imageCell: NSImage(named: NSImage.Name("clock22")))
                    let attachment: NSTextAttachment = NSTextAttachment()
                    attachment.attachmentCell = attachmentCell
                    let attrString: NSAttributedString = NSAttributedString(attachment: attachment)
                    str.append(attrString)
                }
                mainstr.append(str)
            }
        }
        return mainstr
    }else{
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs = [NSAttributedString.Key.foregroundColor: NSColor.labelColor, NSAttributedString.Key.paragraphStyle: paragraph]
        let str = NSMutableAttributedString(string: text, attributes: attrs)
        //        let attachmentCell: NSTextAttachmentCell = NSTextAttachmentCell.init(imageCell: NSImage(named: NSImage.Name("clock22")))
        //        let attachment: NSTextAttachment = NSTextAttachment()
        //        attachment.attachmentCell = attachmentCell
        //        let attrString: NSAttributedString = NSAttributedString(attachment: attachment)
        //        str.append(attrString)
        return str
    }
    
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attrs = [NSAttributedString.Key.foregroundColor: NSColor.labelColor, NSAttributedString.Key.paragraphStyle: paragraph]
    let str = NSMutableAttributedString(string: text, attributes: attrs)
    let attachmentCell: NSTextAttachmentCell = NSTextAttachmentCell.init(imageCell: NSImage(named: NSImage.Name("clock22")))
    let attachment: NSTextAttachment = NSTextAttachment()
    attachment.attachmentCell = attachmentCell
    let attrString: NSAttributedString = NSAttributedString(attachment: attachment)
    str.append(attrString)
    return str
}


enum ACTION:Int{
    case _START_ = 11, _INPROGRESS_, _END_, _VISUALIZE_
}



enum CURRENTSTATE:Int{
    case _NOTHING_ = 111, _MORNING_HABIT_, _EVENING_HABIT_, _ACTIVITY_, _SHUTOFFMAC_, _BREATHING_, _ABORT_, _FOCUS_SUMMARY_, _POSTPON_MORNING_HABIT_, _POSTPON_EVENING_HABIT_, _POSTPON_FOCUS_SUMMARY_, _POSTPON_BREAK_ACTIVITY_
}
var currentState:CURRENTSTATE = ._NOTHING_
var currentAction:ACTION = ACTION._START_

var lastCurrentState:CURRENTSTATE = ._NOTHING_//abort  cancel ho to to pta krne k liye 
var lastCurrentAction:ACTION = ACTION._START_



func playEveryActivitySound(){
    if SettingsManagerObject.isSoundEnabled{
        if let sound = arrCompletingHabitSound.randomElement(){
            NSSound(named: sound)?.play()
        }
    }
    //    NSSound(named: "everyActivity")?.play()
}

func playAfterMorningEveningRoutineSound(isMorning:Bool){
    if SettingsManagerObject.isSoundEnabled{
        if isMorning{
            if let sound = arrCompletingWholeMorningRoutineSound.randomElement(){
                NSSound(named: sound)?.play()
            }
        }else{
            if let sound = arrCompletingWholeEveningRoutineSound.randomElement(){
                NSSound(named: sound)?.play()
            }
        }
    }
    //    NSSound(named: "afterMorningRoutine")?.play()
}

func playFocusModeStartedSound(){
    if SettingsManagerObject.isSoundEnabled{
        if let sound = arrStartFocusSound.randomElement(){
            NSSound(named: sound)?.play()
        }
    }
}
func playStartMorningEveningRoutineSound(){
    if SettingsManagerObject.isSoundEnabled{
        if let sound = arrStartingMorningEveningRoutineSound.randomElement(){
            NSSound(named: sound)?.play()
        }
    }
}
func playFocusPomodorBreakEndsSound(){
    if SettingsManagerObject.isSoundEnabled{
        if let sound = arrCompletingHabitSound.randomElement(){
            NSSound(named: sound)?.play()
        }
    }
}


var arrStartingMorningEveningRoutineSound = ["Starting the Morning:Evening Routine_1",
                                             "Starting the Morning:Evening Routine_2",
                                             "Starting the Morning:Evening Routine_3.1",
                                             "Starting the Morning:Evening Routine_3.2",
                                             "Starting the Morning:Evening Routine_4",
                                             "Starting the Morning:Evening Routine_5"]

var arrStartFocusSound = ["Start Focus Button_1",
                          "Start Focus Button_2",
                          "Start Focus Button_3"]


var arrCompletingWholeMorningRoutineSound = ["Completing the Whole Morning Routine_1",
                                             "Completing the Whole Morning Routine_2.1",
                                             "Completing the Whole Morning Routine_2.2",
                                             "Completing the Whole Morning Routine_3.1",
                                             "Completing the Whole Morning Routine_3.2",
                                             "Completing the Whole Morning Routine_4"]


var arrCompletingWholeEveningRoutineSound = ["Completing the Whole Evening Routine_1",
                                             "Completing the Whole Evening Routine_2",
                                             "Completing the Whole Evening Routine_3",
                                             "Completing the Whole Evening Routine_4",
                                             "Completing the Whole Evening Routine_5",
                                             "Completing the Whole Evening Routine_6",
                                             "Completing the Whole Evening Routine_7"]

var arrCompletingHabitSound = ["Completing a Habit_1",
                               "Completing a Habit_2.1",
                               "Completing a Habit_2.2",
                               "Completing a Habit_3",
                               "Completing a Habit_4"]


//var arrAllSounds = arrCompletingHabitSound + arrCompletingWholeEveningRoutineSound + arrCompletingWholeMorningRoutineSound + arrStartFocusSound + arrStartingMorningEveningRoutineSound





var startActivityButtonText = "Start <TIME> <NAME>"
var unlockMachineButtonText = "Unlock the machine"
var activityFinishedText = "<ACTIVITY> finished!✅"
var lastActivityFinishedText = "<ACTIVITY> finished!✅ You’ve earned your screen time. 💪"
var startBreakActivityTitleText = "It’s time for a break. Do <TIME> of <ACTIVITY> to earn more screentime."
var doSomeActivityText = "Do some <ACTIVITY>."
var startMorningHabitTitleText = "Good Morning! It’s time to Focus Bear. Here are the habits you need to accomplish before you can use your computer."
var startEveningHabitTitleText = "Good Evening! It’s time to Focus Bear. Here are the habits you need to accomplish before you can leave for the day."
var emailID = "team@focusbear.io"
var appName = "Focus Bear"
var buttonCancelText = "Cancel"
var buttonOkText = "OK"
var buttonStatusStateFocusText = "FOCUS"
var buttonStatusStateOffText = "OFF"
var buttonStatusStateCallText = "CALL"
var buttonYesText = "Yes"
var buttonNoText = "No"

var webhookUrl = "https://hooks.zapier.com/hooks/catch/326116/b98ovxc/"
func readConfigFile(){
    addLog(text: "read Config File")
    if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
        startActivityButtonText = activityInfo.value(forKey: "startActivityButtonText") as? String ?? startActivityButtonText
        activityFinishedText = activityInfo.value(forKey: "activityFinishedText") as? String ?? activityFinishedText
        lastActivityFinishedText = activityInfo.value(forKey: "lastActivityFinishedText") as? String ?? lastActivityFinishedText
        startBreakActivityTitleText = activityInfo.value(forKey: "startBreakActivityTitleText") as? String ?? startBreakActivityTitleText
        doSomeActivityText = activityInfo.value(forKey: "doSomeActivityText") as? String ?? doSomeActivityText
        startMorningHabitTitleText = activityInfo.value(forKey: "startMorningHabitTitleText") as? String ?? startMorningHabitTitleText
        startEveningHabitTitleText = activityInfo.value(forKey: "startEveningHabitTitleText") as? String ?? startEveningHabitTitleText
    }
    
    if let common = configjson.value(forKey: "common") as? NSDictionary{
        emailID = common.value(forKey: "emailId") as? String ?? emailID
        appName = common.value(forKey: "appName") as? String ?? appName
        buttonCancelText = common.value(forKey: "buttonCancelText") as? String ?? buttonCancelText
        buttonOkText = common.value(forKey: "buttonOkText") as? String ?? buttonOkText
        buttonYesText = common.value(forKey: "yesText") as? String ?? buttonYesText
        buttonNoText = common.value(forKey: "noText") as? String ?? buttonNoText
        unlockMachineButtonText = common.value(forKey: "unlockMachineButtonText") as? String ?? unlockMachineButtonText
        webhookUrl = common.value(forKey: "webhookUrl") as? String ?? webhookUrl
        buttonStatusStateFocusText = common.value(forKey: "buttonStatusStateFocusText") as? String ?? buttonStatusStateFocusText
        buttonStatusStateOffText = common.value(forKey: "buttonStatusStateOffText") as? String ?? buttonStatusStateOffText
        buttonStatusStateCallText = common.value(forKey: "buttonStatusStateCallText") as? String ?? buttonStatusStateCallText
    }
}
func getDoSomeActivityText(activityName:String)->String{
    return doSomeActivityText.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
}

func getStartBreakActivityTitleText(seconds:Int, activityName:String)->String{
    let stringTime = getStringTime(seconds: seconds)
    var title = startBreakActivityTitleText.replacingOccurrences(of: "<TIME>", with: stringTime)
    title = title.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
    return title
}
func getActivityFinishedText(isLast:Bool, activityName:String)->String{
    if isLast{
        return lastActivityFinishedText.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
    }else{
        return activityFinishedText.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
    }
}
func getStringTime(seconds:Int)->String{
    var stringTime = ""
    if seconds < 60{
        stringTime = "\(seconds) seconds"
    }else{
        let minutes = seconds/60
        if minutes == 1 {
            stringTime = "\(minutes) minute"
        }else {
            stringTime = "\(minutes) minutes"
        }
    }
    return stringTime
}
func getstartActivityButtonText(seconds:Int, name:String)->String{
    var title = startActivityButtonText
    let stringTime = getStringTime(seconds: seconds)
    
    if title.localizedCaseInsensitiveContains("<TIME>"){
        title = title.replacingOccurrences(of: "<TIME>", with: stringTime)
    }
    if title.localizedCaseInsensitiveContains("<NAME>"){
        title = title.replacingOccurrences(of: "<NAME>", with: name)
    }
    return title
}


class Button: cursorButton {
    
    @IBInspectable var horizontalPadding   : CGFloat = 30
    @IBInspectable var verticalPadding    : CGFloat = 30
    
    override var intrinsicContentSize: NSSize {
        var size = super.intrinsicContentSize
        size.width += self.horizontalPadding
        size.height += self.verticalPadding
        return size;
    }
}


class mouseDownEffectButton: NSButton {
    var mouseDown = false

    override func awakeFromNib() {
        super.awakeFromNib()
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
        self.wantsLayer = true
    }
    override func mouseDown(with event: NSEvent) {
        //        super.mouseDown(with: event)
        if self.isEnabled{
            print("mouseDown")
            mouseDown = true
            self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.2).cgColor
            NSCursor.pointingHand.set()
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        // super.mouseUp(with: event)
        if self.isEnabled{
            print("mouseUP")
            if mouseDown {
                mouseDown = false
                if self.action != nil{
                    NSApp.sendAction(self.action!, to: self.target, from: self)
                }
                
                NSCursor.pointingHand.set()
            }
            self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0).cgColor
        }
    }
    override func mouseEntered(with event: NSEvent) {
        if self.isEnabled{
            NSCursor.pointingHand.set()
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        mouseDown = false
        NSCursor.arrow.set()
        self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0).cgColor
    }
}



var isGettingSchema = false
//func getSchemsFile(completionHandler: @escaping(_ result: NSDictionary?) -> ()) {
//    if let myUrl = NSURL(string: "https://focus-bear.github.io/assets/config/settings-schema.json"){
//
//        let request = NSMutableURLRequest(url:myUrl as URL);
//        request.httpMethod = "GET";
//
//        let task = URLSession.shared.dataTask(with: request as URLRequest) {
//            data, response, error in
//
//            if let httpResponse = response as? HTTPURLResponse {
//                if httpResponse.statusCode == 200{
//
//                    if data != nil{
//
//                        do {
//                            if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
//
//                                print(jsonResult)
//                                completionHandler(jsonResult)
//                                return
//                            }
//
//                        }catch{
//                            print(error)
//                        }
//
//                    }
//                    completionHandler(nil)
//                    return
//                }else{
//                    completionHandler(nil)
//                    return
//                }
//            }
//            if error != nil {
//                completionHandler(nil)
//                return
//            }
//            completionHandler(nil)
//        }
//        task.resume()
//    }else{
//        completionHandler(nil)
//    }
//}


let allApiObject = AllApi()



var DebugLogsURL:URL!
var quantityCsvURL:URL!
var blockURL:URL!
var blockWebUrlString = ""
class Log: TextOutputStream {
    
    func write(_ string: String) {
        //        let fm = FileManager.default
        let log = DebugLogsURL!//fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Debug_Logs.txt")
        if let handle = try? FileHandle(forWritingTo: log) {
            handle.seekToEndOfFile()
            handle.write(string.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? string.data(using: .utf8)?.write(to: log)
        }
    }
    static var log: Log = Log()
    private init() {} // we are sure, nobody else could create it
}


func addLog(text:String){
    // if isDebugModeEnabled{
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let now = df.string(from: Date())
    
    print(now , " - ", text, to: &Log.log)
    //}
}

func getStringFromDate(date:Date, dateFormat:String)->String{
    let df = DateFormatter()
    df.dateFormat = dateFormat
    let now = df.string(from: date)
    return now
}
func getStringFromDateInUtc(date:Date, dateFormat:String)->String{
    let df = DateFormatter()
    df.dateFormat = dateFormat
    df.timeZone = TimeZone(abbreviation: "UTC")
    let now = df.string(from: date)
    return now
}
func getDateFromString(date:String, dateFormat:String)->Date?{
    let string = date
    // Create Date Formatter
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = dateFormat

    return dateFormatter.date(from: string)
}

func getDateFromStringInUtc(date:String, dateFormat:String)->Date?{
    let string = date
    // Create Date Formatter
    let dateFormatter = DateFormatter()
    // Set Date Format
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    dateFormatter.dateFormat = dateFormat
    // Convert String to Date
    return dateFormatter.date(from: string)
}
//******************************************CreateDirectoryIfNotExist*******************************************************//
func CreateDirectoryIfNotExist(path:String){
    if !FileManager.default.fileExists(atPath: path){
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }catch{
            
        }
    }
}



////////////////////////////////activation text field ///////////////////////////////////
class CustomTextFieldCell: NSTextFieldCell {
    
    func adjustedFrame(toVerticallyCenterText rect: NSRect) -> NSRect {
        // super would normally draw text at the top of the cell
        var titleRect = super.titleRect(forBounds: rect)
        
        let minimumHeight = self.cellSize(forBounds: rect).height
        titleRect.origin.y += (titleRect.height - minimumHeight) / 2
        titleRect.size.height = minimumHeight
        
        return titleRect
    }
    
    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        super.edit(withFrame: adjustedFrame(toVerticallyCenterText: rect), in: controlView, editor: textObj, delegate: delegate, event: event)
    }
    
    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        super.select(withFrame: adjustedFrame(toVerticallyCenterText: rect), in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: adjustedFrame(toVerticallyCenterText: cellFrame), in: controlView)
    }
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.draw(withFrame: cellFrame, in: controlView)
    }
}
class Editing: NSTextField {
    
    private let commandKey = NSEvent.ModifierFlags.command.rawValue
    private let commandShiftKey = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == NSEvent.EventType.keyDown {
            if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
                switch event.charactersIgnoringModifiers! {
                case "x":
                    if NSApp.sendAction(#selector(NSText.cut(_:)), to:nil, from:self) { return true }
                case "c":
                    if NSApp.sendAction(#selector(NSText.copy(_:)), to:nil, from:self) { return true }
                case "v":
                    if NSApp.sendAction(#selector(NSText.paste(_:)), to:nil, from:self) { return true }
                case "z":
                    if NSApp.sendAction(Selector(("undo:")), to:nil, from:self) { return true }
                case "a":
                    if NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to:nil, from:self) { return true }
                default:
                    break
                }
            }
            else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandShiftKey {
                if event.charactersIgnoringModifiers == "Z" {
                    if NSApp.sendAction(Selector(("redo:")), to:nil, from:self) { return true }
                }
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}




//


// #MARK:- Check Internet connectivity
public class Reachability {
    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        let isReachable = flags == .reachable
        let needsConnection = flags == .connectionRequired
        
        return isReachable && !needsConnection
        
    }
}
var isPurchased = false


func  purchaseNow_clicked(){
    let buynow_path = "https://focusbear.io/buynow"
    NSWorkspace.shared.open(URL(string: buynow_path)!)
}



//    @objc func uploadText(){
//        document.getElementById('id_name').getElementsByTagName('textarea')[0].value = "hello world";
//        var dd = "shutOffTime: 20:30"
//        if let path = Bundle.main.path(forResource: "settings", ofType: "json") {
//            let url = URL(fileURLWithPath: path)
//            do {
//
//                let text2 = try String(contentsOf: url, encoding: .utf8)
//                print(text2)
//                let json = "document.getElementsByTagName('textarea')[0].value=\(text2)"
//
//                webView!.evaluateJavaScript(json,completionHandler: { (html: Any?, error: Error?) in
//                    print(html)
//                })
//
//            } catch {
//                // handle error
//            }
//
//        }

//read json from webview
//        webView!.evaluateJavaScript("document.getElementsByTagName('textarea')[0].value.toString()",
//                                   completionHandler: { (html: Any?, error: Error?) in
//                                    print(html!)
//                                    if let stringDic = html as? String{
//                                        if let data = stringDic.data(using: String.Encoding.utf8) {
//
//                                            do {
//                                                let jsonResult = try (JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? [:])
//                                                print(jsonResult)
//                                                print(jsonResult)
//
//                                            } catch let error as NSError {
//                                                print(error)
//                                            }
//                                        }
//                                    }
//        })
//    }


//  print("didFinish navigation: WKNavigation")
//
//webView.evaluateJavaScript("document.documentElement.outerHTML.toString()",
//                           completionHandler: { (html: Any?, error: Error?) in
//    print(html)
//})
//self.perform(#selector(uploadText), with: nil, afterDelay: 10)


//func getMorningRoutineDate()->Date?{
//    if let path = UserDefaults.standard.object(forKey: kUserdefaultsSelectedFolder) as? String{
//        if FileManager.default.fileExists(atPath: path){
//            let url = URL(fileURLWithPath: path)
//            let fileUrl = url.appendingPathComponent("timestamp.plist")
//            if let dic = NSMutableDictionary(contentsOf: fileUrl){
//                if let stringDate = dic["lastMorningRoutine"] as? String{
//                    if let date = getDateFromString(date: stringDate, dateFormat: "yyyy-MM-dd HH:mm:ss"){
//                        return date
//                    }
//                }
//            }
//        }
//    }
//    return nil
//}
//func writeMorningRoutineDate(){
//    var plistContent = NSMutableDictionary()
//
//    if let path = UserDefaults.standard.object(forKey: kUserdefaultsSelectedFolder) as? String{
//        let url = URL(fileURLWithPath: path)
//        let fileUrl = url.appendingPathComponent("timestamp.plist")
//        if FileManager.default.fileExists(atPath: fileUrl.path){
//            if let dic = NSMutableDictionary(contentsOf: fileUrl){
//                plistContent = dic
//            }
//        }
//        let dateObj = Date()
//        let timestamp = getStringFromDate(date: dateObj, dateFormat: "yyyy-MM-dd HH:mm:ss")
//        plistContent["lastMorningRoutine"] = timestamp
//        let success:Bool = plistContent.write(toFile: fileUrl.path, atomically: true)
//        if success {
//            print("file has been created!")
//        }else{
//            print("unable to create the file")
//        }
//    }
//
//}
//func getEveningRoutineDate()->Date?{
//    if let path = UserDefaults.standard.object(forKey: kUserdefaultsSelectedFolder) as? String{
//        if FileManager.default.fileExists(atPath: path){
//            let url = URL(fileURLWithPath: path)
//            let fileUrl = url.appendingPathComponent("timestamp.plist")
//            if let dic = NSMutableDictionary(contentsOf: fileUrl){
//                if let stringDate = dic["lastEveningRoutine"] as? String{
//                    if let date = getDateFromString(date: stringDate, dateFormat: "yyyy-MM-dd HH:mm:ss"){
//                        return date
//                    }
//                }
//            }
//        }
//    }
//    return nil
//}
//func writeEveningRoutineDate(){
//    var plistContent = NSMutableDictionary()
//
//    if let path = UserDefaults.standard.object(forKey: kUserdefaultsSelectedFolder) as? String{
//        let url = URL(fileURLWithPath: path)
//        let fileUrl = url.appendingPathComponent("timestamp.plist")
//        if FileManager.default.fileExists(atPath: fileUrl.path){
//            if let dic = NSMutableDictionary(contentsOf: fileUrl){
//                plistContent = dic
//            }
//        }
//        let dateObj = Date()
//        let timestamp = getStringFromDate(date: dateObj, dateFormat: "yyyy-MM-dd HH:mm:ss")
//        plistContent["lastEveningRoutine"] = timestamp
//        let success:Bool = plistContent.write(toFile: fileUrl.path, atomically: true)
//        if success {
//            print("file has been created!")
//        }else{
//            print("unable to create the file")
//        }
//    }
//
//}



var currentHoverBox:customBox?
class customBox: NSBox {
    
    var tagValue = 0
    var isTableView = false
    override func awakeFromNib() {
        super.awakeFromNib()
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        if currentHoverBox != nil{
            if currentHoverBox! != self{
                currentHoverBox!.fillColor = .clear
            }
        }
        self.fillColor = NSColor.quaternaryLabelColor
        currentHoverBox = self
    }
    
    override func mouseDown(with event: NSEvent) {
        // super.mouseDown(with: event)
        print("mouse down")
        if isTableView{
            
        }else{
            super.mouseDown(with: event)
        }
        
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        print("mouse up")
        if isTableView{
            if UserDefaults.standard.object(forKey: "trialExpired") != nil{
                activationWindowControllerObj?.showSevenDayTrialVc()
                return;
            }
            
            if arrFocusType[tagValue]["isOn"] as? Bool == true{
                //abort focus mode
                if isHardCorePomodoroModeOn{
                    if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                        //                        if pomodoroVcObj!.enterPasswordVcObj == nil{
                        //                            pomodoroVcObj!.enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as?enterPasswordVc
                        //                        }
                        //                        pomodoroVcObj!.presentAsModalWindow(enterPasswordVcObj!)
                        //                        enterPasswordVcObj?.parentVc = menuViewControllerObj
                        //                        DispatchQueue.global().async {
                        //                            DispatchQueue.main.async {
                        //                                pomodoroVcObj!.enterPasswordVcObj?.view.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
                        //                                pomodoroVcObj!.enterPasswordVcObj?.view.window?.title = ""
                        //                                pomodoroVcObj!.enterPasswordVcObj?.view.window?.styleMask.remove(.closable)
                        //                                pomodoroVcObj!.enterPasswordVcObj?.view.window?.styleMask.remove(.resizable)
                        //                            }
                        //                        }
                        menuViewControllerObj?.showPasswordWindow()
                        addLog(text: "Showing enter password view from hardcodre pomodoro stop from focus stop menu")
                    }else{
                        showAbortingFocusModeVc()
                    }
                }else{
                    showAbortingFocusModeVc()
                }
            }else{
                if isHardCorePomodoroModeOn{
                    
                    return;
                }
                for i in 0..<arrFocusType.count{
                    if arrFocusType[i]["isOn"] as? Bool == true{
                        let alert = NSAlert()
                        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
                            if state{
                                alert.window.sharingType = .none
                            }
                        }
                        alert.messageText = "A focus mode is already running. Please abort the running focus mode to start a new one."
                        
                        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                            if let focusAlreadyRunningText = focusInfo.value(forKey: "focusAlreadyRunningText") as? String{
                                alert.messageText = focusAlreadyRunningText
                            }
                        }
                        alert.runModal()
                        return;
                    }
                }
                
                
                
                
                // new work starting foces mode
                
                //                if arrFocusType[tagValue]["isDefault"] as? Bool == true{
                //                    if focusPreferencesVcObj != nil{// Discourage Default Focus Vc se pahle preferences band kr denege taki vha se koi focus mode chalu na kar pay
                //
                //                        if preferencesWindowControllerObj?.window?.isVisible ?? false{
                //                            preferencesWindowControllerObj?.window?.close()
                //                        }
                //                    }
                //                    if focusModeStartWindowLodded{
                //                        if startingFocusWindowControllerObj?.window?.isVisible ?? false{
                //                            startingFocusWindowControllerObj!.window?.close()
                //                        }
                //                    }
                //                    menuViewControllerObj!.presentAsSheet(getDiscourageDefaultFocusVcObject())
                //                    getDiscourageDefaultFocusVcObject().resetData()
                //                }else{
                
                showStartingFocusMode(focusModeIndex: tagValue, focusType: arrFocusType[tagValue]["name"] as? String ?? "")
                //                startingFocusWindowControllerObj?.window.
                
                //                }
                
                
                
                return;
                
            }
            
            
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        self.fillColor = NSColor.clear
    }
}
var isDiscourageDefaultFocusVcVisible = false
var focusModeStartWindowLodded = false
var isFocusModeStartedFromPomodoroMode = false
func showStartingFocusMode(focusModeIndex: Int, focusType: String){
    addLog(text: "Showing Starting Focus Mode view")
    startingFocusWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.popUpMenuWindow)))
    startingFocusWindowControllerObj?.contentViewController = startingFocusModeVcObj
    startingFocusWindowControllerObj?.showWindow(nil)
    startingFocusModeVcObj?.ResetData(focusModeIndex: focusModeIndex, focusType: focusType)
    NSApplication.shared.activate(ignoringOtherApps: true)
}
func showAbortingFocusModeVc(){
    addLog(text: "Showing Abort focus mode view")
    startingFocusWindowControllerObj?.contentViewController = abortingFocusModeVcObj
    startingFocusWindowControllerObj?.showWindow(nil)
    abortingFocusModeVcObj?.ResetData()
    NSApplication.shared.activate(ignoringOtherApps: true)
}
var arrFocusType = [[String:Any]]()
var isAllowedAllAppsInFocus = false
var isAllowedAllUrlsInFocus = false
var selfAppName = Bundle.main.infoDictionary!["CFBundleName"] as! String


var whatToAchieveInFocusBlock = ""

//// **blocked urls**
//var arrBlockedUrls = [String]()
//let kUserdefaultsArrBlockedUrls = "kUserdefaultsArrBlockedUrls"
////

func getColorString(color:NSColor)->String{
    let ciColor:CIColor = CIColor(color: color)!
    let hexString = String(format: "%02X%02X%02X", Int(ciColor.red * 0xff), Int(ciColor.green * 0xff), Int(ciColor.blue * 0xff))
    return hexString
}
func HexToColor(hexString: String, alpha:CGFloat? = 1.0) -> NSColor {
    // Convert hex string to an integer
    let hexint = Int(intFromHexString(hexStr: hexString))
    let red = CGFloat((hexint & 0xff0000) >> 16) / 255.0
    let green = CGFloat((hexint & 0xff00) >> 8) / 255.0
    let blue = CGFloat((hexint & 0xff) >> 0) / 255.0
    let alpha = alpha!
    // Create color object, specifying alpha as well
    let color = NSColor(red: red, green: green, blue: blue, alpha: alpha)
    return color
}
func intFromHexString(hexStr: String) -> UInt32 {
    var hexInt: UInt32 = 0
    // Create scanner
    let scanner: Scanner = Scanner(string: hexStr)
    // Tell scanner to skip the # character
    scanner.charactersToBeSkipped = NSCharacterSet(charactersIn: "#") as CharacterSet
    // Scan hex value
    scanner.scanHexInt32(&hexInt)
    return hexInt
}

var timerForFocusMode:Timer?//jab bhi focus mode disable krenge timer bhi check krenge valid ua to invalidate krenge
var isFocusTimeType:FocusModeTimeType = ._NONE_
var endFocusModeTime:Date?// ye to vo h jo start foccus k time per hisab lgaya ki end focus ka time kya hoga
var startFocusModeTime:Date?
var startFocusModeTimeForPauseAndResume:Date?
var focusModeActualDurationPerformed:Int = 0// ye kaam aaygi log vali file jo export hoti hai . usme likhvane k liye.. jese fi focus mode finish hoga duuration is var mai likhva lenge fir log mai add krenge (fir ussse focus summary dikhaynge )
var focusModeMinutesToPerform = 0
var focusModeSecondsToPerform = 0 //pause// resume k liye 
enum FocusModeTimeType:Int{
    case _HOUR_ = 11, _TILL_SHUTOFF_, _NONE_
}

func isFocusModeOn()->Bool{
    for dic in arrFocusType{
        if dic["isOn"] as? Bool == true{
            return true
        }
    }
    return false
}

func getRunningFocusModeId()->String{
    for dic in arrFocusType{
        if dic["isOn"] as? Bool == true{
            return dic["id"] as? String ?? ""
        }
    }
    return ""
}

//pomodoro
func resetPomodoroVcFocusListIfNeeded(){
    if isPomodoroWindowLodded{
        if pomodoroWindowControllerObj != nil{
            if (pomodoroWindowControllerObj?.window!.isVisible)!{
                if pomodoroWindowControllerObj?.contentViewController == pomodoroVcObj{
                    pomodoroVcObj?.reFillFocusTypeList()
                }
            }
        }
    }
}


//CSV new entry
func addEntryInCsv(logType:String, activity:String, durationInSeconds:String, quantityQuestion:String, quantityLogged:String, startTime:String, workAchieved:String, distractionsEncountered:String, abortReason:String, feedback:String ){
    do {
        var csv = try String(contentsOf: quantityCsvURL, encoding: .utf8)
        
        let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let csvString = "\(logType),\(timestamp),\(activity),\(durationInSeconds),\(quantityQuestion),\(quantityLogged),\(startTime),\(workAchieved),\(distractionsEncountered),\(abortReason),\(feedback)\n"
        csv = csv.appending(csvString)
        do {
            try csv.write(to: quantityCsvURL, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
    }catch{
        print(error)
    }
}



func replaceLastEntryInCsv(logType:String, activity:String, durationInSeconds:String, quantityQuestion:String, quantityLogged:String, startTime:String, workAchieved:String, distractionsEncountered:String, abortReason:String, feedback:String ){
    do {
        var csv = try String(contentsOf: quantityCsvURL, encoding: .utf8)
        let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let csvString = "\(logType),\(timestamp),\(activity),\(durationInSeconds),\(quantityQuestion),\(quantityLogged),\(startTime),\(workAchieved),\(distractionsEncountered),\(abortReason),\(feedback)\n"
        
        csv = csv.replaceLastLineWith(newLine: csvString)
        
        do {
            try csv.write(to: quantityCsvURL, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
    }catch{
        print(error)
    }
}


extension String {
    func replaceLastLineWith(newLine:String)->String {
        var comps = self.split(separator: "\n")
        comps.removeLast()
        var outputString = ""
//        var br = "\n"
        for sub in comps {
            outputString.append(String(sub)+"\n")
        }
        outputString = outputString.appending(newLine)
        return outputString
    }
}



var assertionIDDisableSleep: IOPMAssertionID = 0
func disableSystemSleep(){
    addLog(text:"disableSystemSleep")
    let reasonForActivity = "Reason for activity" as CFString
    //    var assertionID: IOPMAssertionID = 0
    var success = IOPMAssertionCreateWithName( kIOPMAssertionTypeNoDisplaySleep as CFString,
                                               IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                               reasonForActivity,
                                               &assertionIDDisableSleep )
    //    if success == kIOReturnSuccess {
    //        // Add the work you need to do without the system sleeping here.
    //
    //        success = IOPMAssertionRelease(assertionIDDisableSleep);
    //        // The system will be able to sleep again.
    //    }
}
func enableSystemSleep(){
    IOPMAssertionRelease(assertionIDDisableSleep);
}
func showBlankWindowInSecondaryMonitor(){
//    if appdelegate!.alertSuggestFocusMode != nil{
//        if appdelegate!.alertSuggestFocusMode!.window.isVisible{
////            appdelegate!.alertSuggestFocusMode!.window.close()
//            NSApp.stopModal()
//        }
//    }
    
    // Luisa App broken bug fix 28/6/22
    let windows = NSApp.windows
    for win in windows{
        print(win)
        if win.isModalPanel{
            NSApp.stopModal()
            break;
        }
    }
    //  /////////////////////////////////
    
    appdelegate?.showExtraWindows()
}


func hideBlankWindowInSecondaryMonitor(){
    for i in 0..<arrWindows.count{
        let window = arrWindows[i]
        //        if let vc = window.contentViewController as? ViewController{
        //            vc.customView.cbox?.isHidden = true
        //            vc.customView.setNeedsDisplay(vc.customView.frame)
        //            vc.customView.cRect = NSRect(x: 0, y: 0, width: 0, height: 0)
        //            vc.customView.mouseDownPoint = NSPoint.zero
        //        }
        window.orderOut(nil)
        arrWindows[i].windowController?.window=nil
    }
    arrWindows.removeAll()
}
var arrWindows = [NSWindow]()


func resetWin(_ win: NSWindow) -> NSWindow {
    win.collectionBehavior = NSWindow.CollectionBehavior.canJoinAllSpaces          // we want these windows to follow Spaces around
    //use .desktopWindow for window below icons   //hack? this makes mission control and expose ignore these windows
    //        if toggleButtonHideDesktopIcons.isOn{
    //            win.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.backstopMenu)))
    //        }else{
    win.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
    //        }
    // rest is to make the windows dumb
    win.canHide = false
    win.isExcludedFromWindowsMenu = true
    win.hidesOnDeactivate = false
    win.discardCursorRects()
    win.discardEvents(matching: NSEvent.EventTypeMask.any, before: nil)
    //win.ignoresMouseEvents = true
    win.orderBack(nil)
    win.isRestorable = false
    win.animationBehavior = .none
    win.backgroundColor = NSColor.clear
    return win
}

class blankController: NSViewController {
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        lblTitle.stringValue = appName//"Focus Bear"
    }
}
//4b3eb33632184640b82aa3e3f50fe11b2cdd8b0e82ce48a8bfd1cbe26edc32f5

var newGifsNamesArray = ["Glasses-Bear-250-px_V3", "cheer_250px_trans_centered", "Finger-and-Sign-Bear-250px", "Weight-bear-250-px_V2", "Whistle-bear-250-px"]


extension String {
    
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
    
}

//

func wildcard(_ string: String, pattern: String) -> Bool {
    let pred = NSPredicate(format: "self LIKE %@", pattern)
    return !NSArray(object: string).filtered(using: pred).isEmpty
}

func getDomainFromUrl(url:String) -> String{
    let mainurl = NSURL(string: url)
    var domain = mainurl?.host ?? ""
    print(domain)
    
    if domain.contains("www."){
        domain = domain.replacingOccurrences(of: "www.", with: "")
    }
    print("****")
    return domain
}

func isPreventUserIdleDisplaySleepOn()-> Bool{
    addLog(text: "is Prevent UserIdle Display SleepOn Called")
    let processArray = ["zoom.us", "teams"]// lowercased names aynge sirf
    let dic = avmonitor.getSystemAssertionDic()
    addLog(text: "is Prevent UserIdle Display SleepOn return \(dic)")
    print(dic)
    if dic == nil{
        addLog(text: "is Prevent UserIdle Display SleepOn return false because dic is nil")
        return false
    }
    if let keys  = dic?.keys{
        for key in keys{
            if let arr = dic?[key] as? NSArray{
                addLog(text: "is Prevent UserIdle Display SleepOn success :- arr = dic?[key] as? NSArray")
                for item in arr{
                    //                        print(item as? NSDictionary)
                    if let itemDic = item as? NSDictionary{
                        print(itemDic)
                        print(itemDic.value(forKey: "AssertionTrueType") as?  String ?? "")
                        if itemDic.value(forKey: "AssertionTrueType") as?  String ?? ""  == "PreventUserIdleDisplaySleep"{
                            print(itemDic.value(forKey: "Process Name") as?  String ?? "")
                            if let name = itemDic.value(forKey: "Process Name") as?  String{
                                let processName = name.lowercased()
                                if processName != selfAppName.lowercased(){
                                    if processArray.contains(processName){
                                        addLog(text: "is Prevent UserIdle Display SleepOn return true")
                                        return true
                                    }
                                }
                                
                            }
                            //                                zoom.us, teams
                        }
                        
                    }
                }
            }
        }
    }
    addLog(text: "is Prevent UserIdle Display SleepOn return false")
    return false
}



var lastShownRandomChoiceDic = [String:activityChoice]()



let mainAppBundelId = Bundle.main.bundleIdentifier ?? ""
func createLaunchAgent(){
    
    let path = Bundle.main.bundlePath
    
    let destination = "/Users/\(NSUserName())/Library/LaunchAgents/"
    if !FileManager.default.fileExists(atPath: destination) {
        
        do {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: destination), withIntermediateDirectories: true, attributes: nil)
        } catch {}
        
    }
    
    // saves the agent plist file
    let userLaunchAgentsPath = "\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"
    
    let dicContent = ["Label": "\(mainAppBundelId).plist", "ProgramArguments":["/usr/bin/open","-F","-g",path,"--args"],"KeepAlive":true] as [String : Any]
    
    let plistContent = NSDictionary(dictionary: dicContent)
    let success:Bool = plistContent.write(toFile: userLaunchAgentsPath, atomically: true)
    if success {
        print("file has been created!")
    }else{
        print("unable to create the file")
    }
    shell(launchPath: "/bin/launchctl", arguments: ["load","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
}
func shell(launchPath: String, arguments: [String] = [])  {
    
    let task = Process()
    task.launchPath = launchPath
    task.arguments = arguments
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
    
    
}


func isShutOffTimeGoing()->Bool{
    let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
    let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
    let currentDate = Date()
    
    var isShutOffTime = false
    
    if  startDate.compare(shutOffdate) == .orderedDescending{//(start date jyada ho shut off date se ) ex shut off 5 bje start date 8 bje
        if currentDate.compare(startDate) == .orderedAscending  && currentDate.compare(shutOffdate) == .orderedDescending{
            isShutOffTime = true
        }
        
    }else if currentDate.compare(startDate) == .orderedAscending  || currentDate.compare(shutOffdate) == .orderedDescending{
        isShutOffTime = true
    }
    return isShutOffTime
}


func showNotificationWithMessage(msg:String){
    let notification = NSUserNotification()
    //notification.informativeText = ""
    notification.title = msg
    notification.soundName = NSUserNotificationDefaultSoundName
    NSUserNotificationCenter.default.deliver(notification)
}





func showSmallTimerWindow(durationSeconds: Int, msg: String, isFocusBreak:Bool){
    addLog(text:"show Top Small Timer Window")
    getSmallCountDownWindowObject().contentViewController = getsmallCountDownVcObject()
    smallCountDownVcObj?.isFocusBreak = isFocusBreak
    getSmallCountDownWindowObject().window?.styleMask = .borderless
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    
    getSmallCountDownWindowObject().window?.setFrameOrigin(NSPoint(x: screenFrame.width - (smallCountDownVcObj?.view.frame.width)!, y: screenFrame.height - (smallCountDownVcObj?.view.frame.height)! - 22)) //  22 status bar heigh
    getSmallCountDownWindowObject().window?.isMovableByWindowBackground = true
    
    getSmallCountDownWindowObject().showWindow(nil)
    
    smallCountDownVcObj?.startTimerHabit(durationSeconds: durationSeconds, msg: msg)
}



func runAppleScriptFile(path:String){
    let task = Process()
    task.launchPath = "/usr/bin/osascript"
    task.arguments = [path]
    
    task.launch()
}

func runAppleScriptBeforeFocusBeginIfAvailable(index:Int){
    if let val = arrFocusType[index]["isScriptBeforeFocusEnabled"] as? Bool{
        if val{
            if let path = arrFocusType[index]["scriptPathBeforeFocus"] as? String{
                runAppleScriptFile(path: path)
            }
        }
    }
}
func runAppleScriptAfterFocusEndIfAvailable(index:Int){
    if let val = arrFocusType[index]["isScriptAfterFocusEnabled"] as? Bool{
        if val{
            if let path = arrFocusType[index]["scriptPathAfterFocus"] as? String{
                runAppleScriptFile(path: path)
            }
        }
    }
}

//*****************************Read data from csv******************************//
func readDataFromCSV(url:URL)-> [[String]]{
    var arrItems = [[String]]()
    if let string = try? String(contentsOf: url){
        print(string)
        let arrCsv = csv(data: string)
        print(arrCsv)
        for item in arrCsv{
            if let row = item.first{
                print(row)
                var arrHeaders = [String]()
                let arrString = getArrItem(data: row)
                //                    if arrHeaders.count == 0{
                for header in arrString{
                    if header != "\r"{
                        arrHeaders.append(header)
                    }
                }
                arrItems.append(arrHeaders)
            }
        }
    }
    return arrItems
}
func csv(data: String) -> [[String]] {
    var result: [[String]] = []
    let rows = data.components(separatedBy: "\n")
    for row in rows {
        let columns = row.components(separatedBy: ";")
        result.append(columns)
    }
    return result
}
func getArrItem(data: String) -> [String] {
    var result: [String] = []
    result = data.components(separatedBy: ",")
    return result
}



extension Date {
    
    func interval(ofComponent comp: Calendar.Component, fromDate date: Date) -> Int {
        
        let currentCalendar = Calendar.current
        
        guard let start = currentCalendar.ordinality(of: comp, in: .era, for: date) else { return 0 }
        guard let end = currentCalendar.ordinality(of: comp, in: .era, for: self) else { return 0 }
        
        return end - start
    }
}



var arrLanguageDic = [["name":"English", "id":"en"], ["name":"Spanish", "id":"es"]]



class PopoverAwareTextField: NSTextField, NSPopoverDelegate {

    var parentVcObj:rememberNextHabitVc?
    var itemsArr = [String]()
    var popoverViewControllerObj:PopoverViewController?// = PopoverViewController()
    var selectedItemId = -1
//    lazy var popover: NSPopover = {
//        let popover = NSPopover()
//        popover.behavior = .semitransient
//        popover.contentViewController = popoverViewControllerObj
//        popover.delegate = self
//        return popover
//    }()
    
    override func becomeFirstResponder() -> Bool {
        
        print("becomeFirstResponder")
        if popoverViewControllerObj!.view.isHidden == false{
            return super.becomeFirstResponder()
        }
        
        if itemsArr.count != 0{
            selectedItemId = -1


//            self.superview?.addSubview(popoverViewControllerObj.view)
//            addConstraints()
//            popover.show(relativeTo: self.frame, of: NSApp.keyWindow?.contentView ?? self, preferredEdge: .minY)
            popoverViewControllerObj!.view.isHidden = false
            popoverViewControllerObj!.textFieldObj = self
            popoverViewControllerObj!.ReloadData(arr: itemsArr)
            popoverViewControllerObj!.tblView.reloadData()
            let range = self.currentEditor()?.selectedRange
            self.selectText(self)
            self.currentEditor()?.selectedRange = range ?? NSMakeRange(0, 0)
        }
        
        return super.becomeFirstResponder()
    }
    
//    func addConstraints() {
////        popoverViewControllerObj.view.translatesAutoresizingMaskIntoConstraints = false
//        //Trailing
//        let width = NSLayoutConstraint(item: popoverViewControllerObj.view, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1.0, constant: 0.0)
//        //Leading
//        let leading = NSLayoutConstraint(item: popoverViewControllerObj.view, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0)
//        //Bottom
////        let bottom = NSLayoutConstraint(item: popoverViewControllerObj.view, attribute: .bottom, relatedBy: .equal, toItem: self.superview, attribute: .bottom, multiplier: 1.0, constant: 0.0)
//        //Height to be fixed for SubView same as AdHeight
//        let height = NSLayoutConstraint(item: popoverViewControllerObj.view, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0)
//        self.addConstraint(width)
////        self.superview?.addConstraint(bottom)
//        self.superview?.addConstraint(leading)
//        //Add height constraint to the subview, as subview owns it.
//        self.addConstraint(height)
//    }
    
    @objc func Close(){
//        popover.close()/////
        popoverViewControllerObj!.view.isHidden = true
    }
//    @objc func ChangeState(){
//        isShown = false
//    }
    
//    func popoverDidClose(_ notification: Notification) {
//        self.perform(#selector(ChangeState), with: nil, afterDelay: 1)
//    }
    
//    override func keyDown(with event: NSEvent) {
//        if event.keyCode == 126{
//            return
//        }
//        if event.keyCode == 125{
//            return
//        }
//        super.keyDown(with: event)
//    }
    override func keyUp(with theEvent: NSEvent) {
        
        if theEvent.keyCode == 53 || theEvent.keyCode == 48{//esc,tab
            super.keyUp(with: theEvent)
            popoverViewControllerObj?.view.isHidden = true
            return
        }
        if theEvent.keyCode == 36 || theEvent.keyCode == 76{//enter
            if popoverViewControllerObj!.view.isHidden == false{
                popoverViewControllerObj!.doubleClicked()
            }else{
                
            }
            super.keyUp(with: theEvent)
            return
        }
        if theEvent.keyCode == 126{//// up key
            popoverViewControllerObj!.selectPrevious()
            return
        }
        if theEvent.keyCode == 125{//down key (go next)
            if popoverViewControllerObj!.view.isHidden == true{
                popoverViewControllerObj!.view.isHidden = false
            }else{
                popoverViewControllerObj!.selectNext()
            }
            return
        }
        self.complete(self)
        super.keyUp(with: theEvent)
    }
    
    override func complete(_ sender: Any?) {
        let lengthOfWord = self.stringValue.count
        var matches = [String]()
        selectedItemId = -1
        if self.itemsArr.count != 0 {
            matches.removeAll()
            for result in self.itemsArr {
//                if let _ = result.range(of: self.stringValue, options: [String.CompareOptions.anchored, .caseInsensitive]) {
//                    matches.append(result)
//                }
                if result.localizedStandardContains(self.stringValue){
                    matches.append(result)
                }
            }
            
        }
        
        if lengthOfWord == 0{
            matches = self.itemsArr
        }
        if matches.count > 0 {
            let range = self.currentEditor()?.selectedRange
//            popover.show(relativeTo: self.frame, of: self, preferredEdge: .maxY)
//            popover.show(relativeTo: self.frame, of: NSApp.keyWindow?.contentView ?? self, preferredEdge: .minY)//////
            popoverViewControllerObj!.view.isHidden = false
            popoverViewControllerObj!.textFieldObj = self
            popoverViewControllerObj!.ReloadData(arr: matches)
            popoverViewControllerObj!.tblView.reloadData()
            
            self.selectText(self)
            self.currentEditor()?.selectedRange = range ?? NSMakeRange(0, 0)
        } else{
//            popover.close()/////
            popoverViewControllerObj!.view.isHidden = true
        }
    }
    
}
func roundToHundred(number : Int) -> Int {
    let rounded = Int(number + 50)/100 * 100
    print(rounded) // 1398000
    return rounded
}
func roundToTen(number : Int) -> Int {
    let rounded = (number + 5)/10 * 10
    print(rounded) // 1398000
    return rounded
}
func roundOffValue(number : Int) -> Int {
    if number < 99{
        return roundToTen(number: number)
    }else{
        return roundToHundred(number: number)
    }
}

func roundToHundred(number : Double) -> Double {
    let rounded:Double = Double(Int(number + 5)/100 * 100)
    print(rounded) // 1398000
    return rounded
}
func roundToTen(number : Double) -> Double {
    let rounded:Double = Double(Int(number + 5)/10 * 10)
    print(rounded) // 1398000
    return rounded
}
func roundOffValue(number : Double) -> Double {
    if number < 99{
        return roundToTen(number: number)
    }else{
        return roundToHundred(number: number)
    }
}


//func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
//    var error = error
//
//
//
//    let nonDigits = CharacterSet(charactersIn: "0123456789.").inverted
//
//    if (partialString as NSString).rangeOfCharacter(from: nonDigits).location != NSNotFound {
//
//        error = AutoreleasingUnsafeMutablePointer<NSString?>(mutating: "Input is not an integer")
//
//        return false
//    } else {
//
//        error = nil
//
//        return true
//    }
//}







let daysFreeTrial  = 21


extension NSTextField{
    func setFocus(){
        self.selectText(self)
        self.currentEditor()?.selectedRange = NSRange(location: 0, length: self.stringValue.count)
    }
}







//public extension NSTextField
//{
//    var isFocused:Bool {
//        if
//            window?.firstResponder is NSTextView,
//            let fieldEditor = window?.fieldEditor(false, for: nil),
//            let delegate = fieldEditor.delegate as? NSTextField,
//            self == delegate
//        {
//            return true
//        }
//        return false
//    }
//}


func getUuid()->String{
    return UUID().uuidString.lowercased()
}


func showAlertNoInternet(window:NSWindow){
//        if self.view.window == nil{// doing this beacuse when window is opening for the first time and if window is not completely loddded than it should wait for window (verna crash ho rha tha)
//            self.perform(#selector(showAlertNoInternet), with: nil, afterDelay: 1)
//            return;
//        }
    var noInternetTitle = "No Internet Connection"
    var noInternetSubTitle = "Make sure your device is connected to the internet."
    addLog(text: "settings clicked:- No Internet Connection")
    if let activationNagInfo = configjson.value(forKey: "activationNagInfo") as? NSDictionary{
        if let text = activationNagInfo.value(forKey: "noInternetTitle") as? String{
            noInternetTitle = text
        }
        if let text = activationNagInfo.value(forKey: "noInternetSubTitle") as? String{
            noInternetSubTitle = text
        }
    }
    let alert = NSAlert()
    if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
        if state{
            alert.window.sharingType = .none
        }
    }
    alert.messageText = noInternetTitle
    alert.informativeText = noInternetSubTitle
    alert.alertStyle = .warning
    alert.addButton(withTitle:  buttonOkText)
    alert.beginSheetModal(for: window, completionHandler: {_ in
        window.close()
    })
    
    
}


extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}


var graphOneMonthData:NSDictionary?
var graphOneDayData:[NSDictionary]?


//*****************Safari Chrome Active Tab Url and Titlle*********************//

func getSafariActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Safari"
    set the_wnd to front window
    set active_tab to current tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    if let appleScript = NSAppleScript(source: script) {
        
        var errors : NSDictionary? = nil
        let desc = appleScript.executeAndReturnError(&errors)
        if errors != nil {
            print(errors)
        }
        return desc.stringValue
    }
    return nil
}
func getSafariActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Safari"
    set the_wnd to front window
    set active_tab to current tab in the_wnd
    set tabtitle to name of active_tab
    end tell
    """
    
    if let appleScript = NSAppleScript(source: script) {
        
        var errors : NSDictionary? = nil
        let desc = appleScript.executeAndReturnError(&errors)
        if errors != nil {
            print(errors)
        }
        return desc.stringValue
    }
    return nil
}
func getGoogleChromeActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Google Chrome"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    if let appleScript = NSAppleScript(source: script) {
        
        var errors : NSDictionary? = nil
        let desc = appleScript.executeAndReturnError(&errors)
        if errors != nil {
            print(errors)
        }
        return desc.stringValue
    }
    return nil
}

func getGoogleChromeActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Google Chrome"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set tabtitle to title of active_tab
    end tell
    """
    
    if let appleScript = NSAppleScript(source: script) {
        
        var errors : NSDictionary? = nil
        let desc = appleScript.executeAndReturnError(&errors)
        if errors != nil {
            print(errors)
        }
        return desc.stringValue
    }
    return nil
}
//*******************************************************//



extension NSLayoutConstraint {
    /**
     Change multiplier constraint

     - parameter multiplier: CGFloat
     - returns: NSLayoutConstraint
    */
    func setMultiplier(multiplier:CGFloat) -> NSLayoutConstraint {

        NSLayoutConstraint.deactivate([self])

        let newConstraint = NSLayoutConstraint(
            item: firstItem,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)

        newConstraint.priority = priority
        newConstraint.shouldBeArchived = self.shouldBeArchived
        newConstraint.identifier = self.identifier

        NSLayoutConstraint.activate([newConstraint])
        return newConstraint
    }
}
