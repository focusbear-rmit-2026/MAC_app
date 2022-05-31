//
//  globalFile.swift
//  EarnYourScreentime
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
var quitCountDownVcObj:quitCountDownVc?
func getQuittingCountDownVcObject()->quitCountDownVc{
    if quitCountDownVcObj == nil{
        quitCountDownVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("quitCountDownVc")) as? quitCountDownVc
    }
    return quitCountDownVcObj!
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

let appdelegate = NSApplication.shared.delegate as? AppDelegate


var kUserdefaultsPomodoroModeEnabled = "kUserdefaultsPomodoroModeEnabled"
var kUserdefaultsOfficeModeEnabled = "kUserdefaultsOfficeModeEnabled"
var isOfficeModeEnabled = false

var kUserdefaultsReducedMotion = "kUserdefaultsReducedMotion"
var kIsReducedMotion = false

var isPromptToRememberHabit = true
var kUserdefaultsPromptToRememberHabit = "kUserdefaultsPromptToRememberHabit"

var isPromptToRememberHabitShowedInLastHabit = false///   reason:-Make sure it doesn't happen twice in a row though. 

var configjson = NSDictionary()

let kUserdefaultsShowPomodoroView = "kUserdefaultsShowPomodoroView"

let kUserdefaultsSelectedJson = "kUserdefaultsSelectedJson"
let kUserdefaultsFirstRun = "kUserdefaultsFirstRun"
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

let kUserdefaultsAppPassword = "kUserdefaultsAppPassword"

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
    var name:String!
    var durationSeconds:Int!
    var urlsArray:[String]
    var logQuantity:Bool!
    var logQuantityQuestion:String?
    var openSpecificApps:Bool!
    var allowUrls:[String]!
    var allowApps:[String]!
    init(name:String, durationSeconds:Int, urlsArray:[String], logQuantity:Bool, logQuantityQuestion:String?, openSpecificApps:Bool,allowUrls:[String],allowApps:[String]) {
        self.name = name
        self.durationSeconds = durationSeconds
        self.urlsArray = urlsArray
        self.logQuantity = logQuantity
        self.logQuantityQuestion = logQuantityQuestion
        self.openSpecificApps = openSpecificApps
        self.allowUrls = allowUrls
        self.allowApps = allowApps
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
//var showEveryBreak = false
var isAnyMandatoryActivityIncluded = false
var isMandatoryActivityGoing = false
var breakAfterMinutes = 0
var arrAllbreakActivities = [breakActivity]()
var arrActivitiesIncludeInEveryBreak = [breakActivity]()
var arrActivitiesExcludeInEveryBreak = [breakActivity]()
struct breakActivity {
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
    init(name:String, durationSeconds:Int, IncludeInEveryBreak:Bool, urlsArray:[String], logQuantity:Bool,isRandomChoice:Bool,choices:[activityChoice],logQuantityQuestion:String?, openSpecificApps:Bool,allowUrls:[String],allowApps:[String],isOfficeFriendly:Bool) {
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
    }
}


struct activityChoice {
    var name:String!
    var urlsArray:[String]
    var logQuantityQuestion:String!
    var logQuantity:Bool!
    init(name:String, urlsArray:[String], logQuantityQuestion:String, logQuantity:Bool) {
        self.name = name
        self.urlsArray = urlsArray
        self.logQuantityQuestion = logQuantityQuestion
        self.logQuantity = logQuantity
    }
}

let avmonitor = AVMonitor()

//////////////////////////////////////////////////////////START AT LOGIN//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class LaunchOnStartup {
    static func itemReferencesInLoginItems() -> (existingReference: LSSharedFileListItem?, lastReference: LSSharedFileListItem?) {
        let appUrl = URL(fileURLWithPath: Bundle.main.bundlePath)
        let loginItemsRef = LSSharedFileListCreate(
            nil,
            kLSSharedFileListSessionLoginItems.takeRetainedValue(),
            nil
        ).takeRetainedValue() as LSSharedFileList?
        if loginItemsRef != nil {
            let loginItems = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as Array
            
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
        ).takeRetainedValue() as LSSharedFileList?
        
        if loginItemsRef != nil
        {
            if shouldLaunch
            {
                if !alreadyExists
                {
                    
                    let appUrl = URL(fileURLWithPath: Bundle.main.bundlePath) as CFURL
                    LSSharedFileListInsertItemURL(
                        loginItemsRef,
                        itemReferences.lastReference,
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
    case _START_ = 11, _INPROGRESS_, _END_
}



enum CURRENTSTATE:Int{
    case _NOTHING_ = 111, _MORNING_HABIT_, _EVENING_HABIT_, _ACTIVITY_, _SHUTOFFMAC_, _BREATHING_, _ABORT_, _FOCUS_SUMMARY_
}
var currentState:CURRENTSTATE = ._NOTHING_
var currentAction:ACTION = ACTION._START_

var lastCurrentState:CURRENTSTATE = ._NOTHING_//abort  cancel ho to to pta krne k liye 
var lastCurrentAction:ACTION = ACTION._START_



func playEveryActivitySound(){
    NSSound(named: "everyActivity")?.play()
}

func playAfterMorningRoutineSound(){
    NSSound(named: "afterMorningRoutine")?.play()
}

var startActivityButtonText = "Start <TIME> <NAME>"
var unlockMachineButtonText = "Unlock the machine"
var activityFinishedText = "<ACTIVITY> finished!✅"
var lastActivityFinishedText = "<ACTIVITY> finished!✅ You’ve earned your screen time. 💪"
var startBreakActivityTitleText = "It’s time for a break. Do <TIME> of <ACTIVITY> to earn more screentime."
var doSomeActivityText = "Do some <ACTIVITY>."
var startMorningHabitTitleText = "Good Morning! It’s time to earn your screentime. Here are the habits you need to accomplish before you can use your computer."
var startEveningHabitTitleText = "Good Evening! It’s time to earn your screentime. Here are the habits you need to accomplish before you can leave for the day."
var emailID = "team@earnyourscreentime.com"
var appName = "Earn Your Screen Time"
var buttonCancelText = "Cancel"
var buttonOkText = "OK"
var buttonStatusStateFocusText = "FOCUS"
var buttonStatusStateOffText = "OFF"
var buttonStatusStateCallText = "CALL"


var webhookUrl = "https://hooks.zapier.com/hooks/catch/326116/b98ovxc/"
func readConfigFile(){
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




//{ se phele space todod
func getConfigFile(completionHandler: @escaping(_ result: NSDictionary?) -> ()) {
    addLog(text: "downloading config file")
    if let myUrl = NSURL(string: "https://earnyourscreentime.com/config/config.json"){
    
        let request = NSMutableURLRequest(url:myUrl as URL);
    request.httpMethod = "GET";
    
    let task = URLSession.shared.dataTask(with: request as URLRequest) {
        data, response, error in

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200{
                
                if data != nil{
                    
//                    let responseStrInISOLatin = String(data: data!, encoding: String.Encoding.isoLatin1)
//                    guard let modifiedDataInUTF8Format = responseStrInISOLatin?.data(using: String.Encoding.utf8) else {
//                        print("could not convert data to UTF-8 format")
//                        addLog(text: "error config file: could not convert data to UTF-8 format")
//                        completionHandler(nil)
//                        return
//                    }
//
//
//                    do {
//                        let jsonResult = try JSONSerialization.jsonObject(with: modifiedDataInUTF8Format) as? NSDictionary
//                        print(jsonResult)
//                        completionHandler(jsonResult)
//                        return
//                    } catch {
//                        print(error)
//                        addLog(text: "error config file: \(error.localizedDescription)")
//                        completionHandler(nil)
//                        return
//                    }
                    
                    do {
                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{

                            print(jsonResult)
                            completionHandler(jsonResult)
                            return
                        }

                    }catch{
                        print(error)
                        addLog(text: "error reading config file: \(error.localizedDescription)")
                        completionHandler(nil)
                        return
                    }
                    
                }
                
                completionHandler(nil)
                return
            }else{
                completionHandler(nil)
                return
            }
        }
        if error != nil {
            addLog(text: "error config file: \(error!.localizedDescription)")
            completionHandler(nil)
            return
        }
        completionHandler(nil)
        return
    }
    task.resume()
    }else{
        completionHandler(nil)
    }
}
var isGettingSchema = false
func getSchemsFile(completionHandler: @escaping(_ result: NSDictionary?) -> ()) {
    if let myUrl = NSURL(string: "https://earnyourscreentime.com/config/settings-schema.json"){
        
        let request = NSMutableURLRequest(url:myUrl as URL);
        request.httpMethod = "GET";
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200{
                    
                    if data != nil{
                        
                        do {
                            if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                
                                print(jsonResult)
                                completionHandler(jsonResult)
                                return
                            }
                            
                        }catch{
                            print(error)
                        }
                        
                    }
                    completionHandler(nil)
                    return
                }else{
                    completionHandler(nil)
                    return
                }
            }
            if error != nil {
                completionHandler(nil)
                return
            }
            completionHandler(nil)
        }
        task.resume()
    }else{
        completionHandler(nil)
    }
}


func getAbortJsonToUpload(emailAddress:String?, feedback:String, abortReason:String,completionHandler: @escaping(_ result: NSDictionary) -> ()) {
    var settingsJson = NSDictionary()
    if let stringDic = UserDefaults.standard.object(forKey: kUserdefaultsSelectedJson) as? String {
        if let data = stringDic.data(using: String.Encoding.utf8) {
            do {
                settingsJson = try (JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? [:])
            } catch let error as NSError {
                print(error)
            }
        }
        
    }else {
        if let path = Bundle.main.path(forResource: "settings", ofType: "json") {
            let url = URL(fileURLWithPath: path)
            do {
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                do {
                    if let dicResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                        settingsJson = dicResult
                    }
                }catch {
                    print(error)
                }
            } catch {
                // handle error
            }
        }
    }
    
    let systemVersion = ProcessInfo().operatingSystemVersion
    let version = "\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)"
    
    let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let myDateString = formatter.string(from: firstRunDate)
    
    let jsonResult:NSMutableDictionary = ["abortReason":abortReason, "settingsJSON":settingsJson, "macOSVersion":version, "feedback":feedback, "usageStartDate":myDateString]
    
    if emailAddress != nil{
        jsonResult["emailAddress"] = emailAddress!
    }
    
    
    
    let responsePath = webhookUrl
    if let myUrl = NSURL(string: responsePath){
        
        let request = NSMutableURLRequest(url:myUrl as URL);
        request.httpMethod = "POST";
        
        var json = jsonResult//[[String: String]]()
        
        
        
        
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        //         let boundary = generateBoundaryString()
        //         let contentData = createBodyWithParameters(imageDataKey: folderData as? NSData ?? NSData(), boundary: boundary, jsonData: jsonData) as Data
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            // print(response)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200{
                    
                    
                    
                    if data != nil{
                        
                        let status = String(data: data!, encoding: .utf8)!
                        if status == "1"{
                            print("success")
                            
                        }else{
                            
                        }
                    }
                }else{
                    
                }

            }
            //            isUploadingPopupResponse = false
            if error != nil {
                completionHandler(jsonResult)
                return
            }
            completionHandler(jsonResult)
            return;
        }
        task.resume()
    }else{
        //        isUploadingPopupResponse = false
        completionHandler(jsonResult)
    }
    

}
func getQuitJsonToUpload(emailAddress:String?, feedback:String, quitReason:String,completionHandler: @escaping(_ result: NSDictionary) -> ()) {
    var settingsJson = NSDictionary()
    if let stringDic = UserDefaults.standard.object(forKey: kUserdefaultsSelectedJson) as? String {
        if let data = stringDic.data(using: String.Encoding.utf8) {
            do {
                settingsJson = try (JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? [:])
            } catch let error as NSError {
                print(error)
            }
        }
        
    }else {
        if let path = Bundle.main.path(forResource: "settings", ofType: "json") {
            let url = URL(fileURLWithPath: path)
            do {
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                do {
                    if let dicResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                        settingsJson = dicResult
                    }
                }catch {
                    print(error)
                }
            } catch {
                // handle error
            }
        }
    }
    
    let systemVersion = ProcessInfo().operatingSystemVersion
    let version = "\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)"
    
    let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let myDateString = formatter.string(from: firstRunDate)
    
    let jsonResult:NSMutableDictionary = ["quitReason":quitReason, "settingsJSON":settingsJson, "macOSVersion":version, "feedback":feedback, "usageStartDate":myDateString]
    
    if emailAddress != nil{
        jsonResult["emailAddress"] = emailAddress!
    }
    
    
    
    let responsePath = webhookUrl
    if let myUrl = NSURL(string: responsePath){
        
        let request = NSMutableURLRequest(url:myUrl as URL);
        request.httpMethod = "POST";
        
        var json = jsonResult//[[String: String]]()
        
        
        
        
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        //         let boundary = generateBoundaryString()
        //         let contentData = createBodyWithParameters(imageDataKey: folderData as? NSData ?? NSData(), boundary: boundary, jsonData: jsonData) as Data
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            // print(response)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200{
                    
                    
                    
                    if data != nil{
                        
                        let status = String(data: data!, encoding: .utf8)!
                        if status == "1"{
                            print("success")
                            
                        }else{
                            
                        }
                    }
                }else{
                    
                }

            }
            //            isUploadingPopupResponse = false
            if error != nil {
                completionHandler(jsonResult)
                return
            }
            completionHandler(jsonResult)
            return;
        }
        task.resume()
    }else{
        //        isUploadingPopupResponse = false
        completionHandler(jsonResult)
    }
    

}
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

func getDateFromString(date:String, dateFormat:String)->Date?{
    let string = date
    // Create Date Formatter
    let dateFormatter = DateFormatter()
    // Set Date Format
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
func activateKey(license_key:String,completionHandler: @escaping(_ result: NSDictionary?) -> ()){
//80F7CCF5-7FE54D41-B5A2DD9F-4A84B894
//    isUploadingPopupResponse = true
    let responsePath = "https://api.gumroad.com/v2/licenses/verify?product_permalink=xdkkds&license_key=\(license_key)"
    if let myUrl = NSURL(string: responsePath){
        
        let request = NSMutableURLRequest(url:myUrl as URL);
        request.httpMethod = "POST";

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpBody = jsonData
        
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200{

                    if data != nil{
                        do {
                            if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{

                                completionHandler(jsonResult)
                                return
                            }
                            
                        }catch{
                            print(error)
                        }
                    }
                }else{
                    completionHandler(nil)
                    return
                }
            }
//            isUploadingPopupResponse = false
            if error != nil {
                completionHandler(nil)
                return
            }
            completionHandler(nil)
            return
        }
        
        task.resume()
    }else{
        completionHandler(nil)
    }
}

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
    let buynow_path = "https://earnyourscreentime.com/buynow"
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


func getMorningRoutineDate()->Date?{
    if let path = UserDefaults.standard.object(forKey: kUserdefaultsSelectedFolder) as? String{
        if FileManager.default.fileExists(atPath: path){
            let url = URL(fileURLWithPath: path)
            let fileUrl = url.appendingPathComponent("timestamp.plist")
            if let dic = NSMutableDictionary(contentsOf: fileUrl){
                if let stringDate = dic["lastMorningRoutine"] as? String{
                    if let date = getDateFromString(date: stringDate, dateFormat: "yyyy-MM-dd HH:mm:ss"){
                        return date
                    }
                }
            }
        }
    }
    return nil
}
func writeMorningRoutineDate(){
    var plistContent = NSMutableDictionary()
    
    if let path = UserDefaults.standard.object(forKey: kUserdefaultsSelectedFolder) as? String{
        let url = URL(fileURLWithPath: path)
        let fileUrl = url.appendingPathComponent("timestamp.plist")
        if FileManager.default.fileExists(atPath: fileUrl.path){
            if let dic = NSMutableDictionary(contentsOf: fileUrl){
                plistContent = dic
            }
        }
        let dateObj = Date()
        let timestamp = getStringFromDate(date: dateObj, dateFormat: "yyyy-MM-dd HH:mm:ss")
        plistContent["lastMorningRoutine"] = timestamp
        let success:Bool = plistContent.write(toFile: fileUrl.path, atomically: true)
        if success {
            print("file has been created!")
        }else{
            print("unable to create the file")
        }
    }
    
}
func getEveningRoutineDate()->Date?{
    if let path = UserDefaults.standard.object(forKey: kUserdefaultsSelectedFolder) as? String{
        if FileManager.default.fileExists(atPath: path){
            let url = URL(fileURLWithPath: path)
            let fileUrl = url.appendingPathComponent("timestamp.plist")
            if let dic = NSMutableDictionary(contentsOf: fileUrl){
                if let stringDate = dic["lastEveningRoutine"] as? String{
                    if let date = getDateFromString(date: stringDate, dateFormat: "yyyy-MM-dd HH:mm:ss"){
                        return date
                    }
                }
            }
        }
    }
    return nil
}
func writeEveningRoutineDate(){
    var plistContent = NSMutableDictionary()
    
    if let path = UserDefaults.standard.object(forKey: kUserdefaultsSelectedFolder) as? String{
        let url = URL(fileURLWithPath: path)
        let fileUrl = url.appendingPathComponent("timestamp.plist")
        if FileManager.default.fileExists(atPath: fileUrl.path){
            if let dic = NSMutableDictionary(contentsOf: fileUrl){
                plistContent = dic
            }
        }
        let dateObj = Date()
        let timestamp = getStringFromDate(date: dateObj, dateFormat: "yyyy-MM-dd HH:mm:ss")
        plistContent["lastEveningRoutine"] = timestamp
        let success:Bool = plistContent.write(toFile: fileUrl.path, atomically: true)
        if success {
            print("file has been created!")
        }else{
            print("unable to create the file")
        }
    }
    
}



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
                showAbortingFocusModeVc()
            }else{
                for i in 0..<arrFocusType.count{
                    if arrFocusType[i]["isOn"] as? Bool == true{
                        let alert = NSAlert()
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

// **blocked urls**
var arrBlockedUrls = [String]()
let kUserdefaultsArrBlockedUrls = "kUserdefaultsArrBlockedUrls"
//

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
var focusModeActualDurationPerformed:Int = 0// ye kaam aaygi log vali file jo export hoti hai . usme likhvane k liye.. jese fi focus mode finish hoga duuration is var mai likhva lenge fir log mai add krenge (fir ussse focus summary dikhaynge )
var focusModeMinutesToPerform = 0
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









var assertionIDDisableSleep: IOPMAssertionID = 0
func disableSystemSleep(){
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
        lblTitle.stringValue = appName//"Earn Your Screentime"
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
    
    if  startDate.compare(shutOffdate) == .orderedDescending{//(start date jyada ho shut off date se ) exshut off 5 bje start date 8 bje
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





func showSmallTimerWindow(durationSeconds: Int, name: String, isFocusBreak:Bool){
    getSmallCountDownWindowObject().contentViewController = getsmallCountDownVcObject()
    smallCountDownVcObj?.isFocusBreak = isFocusBreak
    getSmallCountDownWindowObject().window?.styleMask = .borderless
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    
    getSmallCountDownWindowObject().window?.setFrameOrigin(NSPoint(x: screenFrame.width - (smallCountDownVcObj?.view.frame.width)!, y: screenFrame.height - (smallCountDownVcObj?.view.frame.height)! - 22)) //  22 status bar heigh
    getSmallCountDownWindowObject().window?.isMovableByWindowBackground = true
    
    getSmallCountDownWindowObject().showWindow(nil)
    
    smallCountDownVcObj?.startTimerHabit(durationSeconds: durationSeconds, name: name)
}
