//
//  globalFile.swift
//  EarnYourScreentime
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa

let mainStoryboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
let mainWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("mainWindowController")) as? mainWindowController
let mainViewControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("ViewController")) as? ViewController
let firstViewControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("firstViewController")) as? firstViewController

let timerViewcontrollerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("timerViewcontroller")) as? timerViewcontroller

let thirdVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("thirdVc")) as? thirdVc

let selectJsonWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("selectJsonWindowController")) as? selectJsonWindowController
let selectJsonVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("selectJsonVc")) as? selectJsonVc
let shutOffTimeVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("shutOffTimeVc")) as? shutOffTimeVc

let abortingCountDownVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortingCountDownVc")) as? abortingCountDownVc
let abortingConfirmVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortingConfirmVc")) as? abortingConfirmVc
let abortDoneVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortDoneVc")) as? abortDoneVc


let abortingCantHandleVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortingCantHandleVc")) as? abortingCantHandleVc

let appdelegate = NSApplication.shared.delegate as? AppDelegate

var configjson = NSDictionary()

let kUserdefaultsSelectedJson = "kUserdefaultsSelectedJson"
let kUserdefaultsFirstRun = "kUserdefaultsFirstRun"
let kUserdefaultsFirstRunDate = "kUserdefaultsFirstRunDate"
let kUserdefaultsLastHabitShowDate = "UserdefaultsLastHabitShowDate"
var kUserdefaultsIsAppEnabled = "kUserdefaultsIsAppEnabled"
var kUserdefaults4HourReActivateTime = "kUserdefaults4HourReActivateTime"
var kUserdefaultsShutdownAborted = "kUserdefaultsShutdownAborted"

var isAppEnable = true
var startTime:Time?
var shutOffTime:Time?

var isHabitAlreadyShowed = true
var isFirstRun = false

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
var isBreathingGoing = false
var isHabitGoing = false
var isBreakActivitiesGoing = false
var currentHabitIndex = -1
var currentActivityIndex = -1

var arrAllHabits = [morningHabit]()
struct morningHabit {
    var name:String!
    var durationSeconds:Int!
    var url:String?
    init(name:String, durationSeconds:Int, url:String?) {
        self.name = name
        self.durationSeconds = durationSeconds
        self.url = url
    }
}
var introActivity:morningHabit?

func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
    return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
}

var showEveryBreak = false
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
    var url:String?
    init(name:String, durationSeconds:Int, IncludeInEveryBreak:Bool, url:String?) {
        self.name = name
        self.durationSeconds = durationSeconds
        self.IncludeInEveryBreak = IncludeInEveryBreak
        self.url = url
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

//class CustomTextFieldcell: NSTextFieldCell {
//
//    override func fieldEditor(for aControlView: NSView) -> NSTextView? {
//        return PasteView()
//    }
//}
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
    case _NOTHING_ = 111, _HABIT_, _ACTIVITY_, _SHUTOFFMAC_, _BREATHING_, _ABORT_, _FIRST_TIME_
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
var emailID = "team@earnyourscreentime.com"
var buttonCancelText = "Cancel"
var webhookUrl = "https://hooks.zapier.com/hooks/catch/326116/b98ovxc/"
func readConfigFile(){
    if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
        startActivityButtonText = activityInfo.value(forKey: "startActivityButtonText") as? String ?? startActivityButtonText
        activityFinishedText = activityInfo.value(forKey: "activityFinishedText") as? String ?? activityFinishedText
        lastActivityFinishedText = activityInfo.value(forKey: "lastActivityFinishedText") as? String ?? lastActivityFinishedText
        startBreakActivityTitleText = activityInfo.value(forKey: "startBreakActivityTitleText") as? String ?? startBreakActivityTitleText
        doSomeActivityText = activityInfo.value(forKey: "doSomeActivityText") as? String ?? doSomeActivityText
        startMorningHabitTitleText = activityInfo.value(forKey: "startMorningHabitTitleText") as? String ?? startMorningHabitTitleText
    }
    
    if let common = configjson.value(forKey: "common") as? NSDictionary{
        emailID = common.value(forKey: "emailId") as? String ?? emailID
        buttonCancelText = common.value(forKey: "buttonCancelText") as? String ?? buttonCancelText
        unlockMachineButtonText = common.value(forKey: "unlockMachineButtonText") as? String ?? unlockMachineButtonText
        webhookUrl = common.value(forKey: "webhookUrl") as? String ?? webhookUrl
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
    var stringTime = getStringTime(seconds: seconds)
    
    if title.localizedCaseInsensitiveContains("<TIME>"){
        title = title.replacingOccurrences(of: "<TIME>", with: stringTime)
    }
    if title.localizedCaseInsensitiveContains("<NAME>"){
        title = title.replacingOccurrences(of: "<NAME>", with: name)
    }
    return title
}


class Button: NSButton {

    @IBInspectable var horizontalPadding   : CGFloat = 30
    @IBInspectable var verticalPadding    : CGFloat = 30

    override var intrinsicContentSize: NSSize {
        var size = super.intrinsicContentSize
        size.width += self.horizontalPadding
        size.height += self.verticalPadding
        return size;
    }
}
class CustomNSButtonCell: NSButtonCell {

@IBInspectable var imagePaddingLeft   : CGFloat = 30
@IBInspectable var imagePaddingTop    : CGFloat = 0
@IBInspectable var textPaddingLeft   : CGFloat = 30
@IBInspectable var textPaddingTop    : CGFloat = 0

override func drawImage(_ image: NSImage, withFrame frame: NSRect, in controlView: NSView) {

    let newFrame = NSRect.init(
        origin: .init(x: frame.minX + imagePaddingLeft, y: frame.minY + imagePaddingTop),
        size: frame.size)

    super.drawImage(image, withFrame: newFrame, in: controlView)
}

override func drawTitle(_ title: NSAttributedString, withFrame frame: NSRect, in controlView: NSView) -> NSRect {
     let newFrame = NSRect.init(
               origin: .init(x: frame.minX + textPaddingLeft, y: frame.minY + textPaddingTop),
               size: frame.size)
    super.drawTitle(title, withFrame: newFrame, in: controlView)
    return newFrame
}
}
