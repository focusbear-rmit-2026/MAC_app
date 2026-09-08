//
//  allExtension.swift
//  FocusBear
//
//  Created by Manish Jain on 23/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import WebKit

extension WKWebView {
    func stringByEvaluatingJavaScript(from script: String?) -> String? {
        var resultString: String? = nil
        var finished = false
        
        evaluateJavaScript(script ?? "", completionHandler: { result, error in
            if error == nil {
                if result != nil {
                    if let result = result {
                        resultString = "\(result)"
                    }
                }
            } else {
                print("evaluateJavaScript error : \(error?.localizedDescription ?? "")")
            }
            finished = true
        })
        
        while !finished {
            RunLoop.current.run(mode: .default, before: Date.distantFuture)
        }
        
        return resultString
    }
    
    class func clean() {
        //guard #available(iOS 9.0, *) else {return}
        
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                #if DEBUG
                print("WKWebsiteDataStore record deleted:", record)
                #endif
            }
        }
    }
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
    
    func dayOfWeek() -> String{
        let dateFormatter = DateFormatter()
        // Fixed locale: the result is matched against English server values ("MON"…"SUN",
        // "weekdays", "weekend") — a localized day name (e.g. Spanish "SÁB") never matches.
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEE"
        return dateFormatter.string(from: self).uppercased()
    }
    
    func interval(ofComponent comp: Calendar.Component, fromDate date: Date) -> Int {
        
        let currentCalendar = Calendar.current
        
        guard let start = currentCalendar.ordinality(of: comp, in: .era, for: date) else { return 0 }
        guard let end = currentCalendar.ordinality(of: comp, in: .era, for: self) else { return 0 }
        
        return end - start
    }
}


extension NSScrollView{
    func scrollToLast(){
        if let documentView = documentView {
            let newOrigin = NSPoint(x: 0, y: 0)
            documentView.scroll(newOrigin)
        }
    }
    
    func scrollToTop(){
        if let documentView = documentView {
            documentView.scroll(NSPoint(x: 0, y: documentView.bounds.height))
        }
    }
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
    
    func addTopRightConstraints(subView:NSView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        //Trailing
        let trailing = NSLayoutConstraint(item: subView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        
        let top = NSLayoutConstraint(item: subView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0)
        self.addConstraint(trailing)
        self.addConstraint(top)
    }
    
    func addVerticalCenterConstraints(subView:NSView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        //Trailing
        let trailing = NSLayoutConstraint(item: subView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        //Leading
        let leading = NSLayoutConstraint(item: subView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0)
        //Bottom
      //  let bottom = NSLayoutConstraint(item: subView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        //Height to be fixed for SubView same as AdHeight
        let center = NSLayoutConstraint(item: subView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0)
        self.addConstraint(trailing)
        self.addConstraint(center)
        self.addConstraint(leading)
        //Add height constraint to the subview, as subview owns it.
     //   self.addConstraint(height)
    }
    
    func addBottomRightConstraints(subView:NSView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        //Trailing
        let trailing = NSLayoutConstraint(item: subView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        let bottom = NSLayoutConstraint(item: subView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        self.addConstraint(trailing)
        self.addConstraint(bottom)
    }
    
    func addBottomLeftConstraints(subView:NSView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        //Trailing
        let leading = NSLayoutConstraint(item: subView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0)
        let bottom = NSLayoutConstraint(item: subView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        self.addConstraint(leading)
        self.addConstraint(bottom)
    }
    
    func addConstraints(subView:NSView, leading:CGFloat, trailing:CGFloat, bottom:CGFloat, top:CGFloat) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        let trailing = NSLayoutConstraint(item: subView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: trailing)
        let leading = NSLayoutConstraint(item: subView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: leading)
        let bottom = NSLayoutConstraint(item: subView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: bottom)
        let top = NSLayoutConstraint(item: subView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: top)
        self.addConstraint(trailing)
        self.addConstraint(bottom)
        self.addConstraint(leading)
        self.addConstraint(top)
    }
    
}

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

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}

extension NSAppleEventDescriptor {
    
    func toStringArray() -> [String] {
        guard let listDescriptor = self.coerce(toDescriptorType: typeAEList) else {
            return []
        }
        
        return (0..<listDescriptor.numberOfItems)
            .compactMap { listDescriptor.atIndex($0 + 1)?.stringValue }
    }
    
    func toTwoColumnStringArray() -> [(title: String, url: String)] {
        guard let listDescriptor = self.coerce(toDescriptorType: typeAEList) else {
            return []
        }
        guard listDescriptor.numberOfItems > 0 else { return [] }
        var result: [(String, String)] = []

        for i in 0..<listDescriptor.numberOfItems {
            if let sublist = listDescriptor.atIndex(i + 1)?.coerce(toDescriptorType: typeAEList) {
                let title = sublist.atIndex(1)?.stringValue ?? ""
                let url = sublist.atIndex(2)?.stringValue ?? ""
                result.append((title: title, url: url))
            }
        }

        return result
    }
    
    func toAnyArray() -> [String:[String]] {
        guard let listDescriptor = self.coerce(toDescriptorType: typeAEList) else {
            return [:]
        }
        var tabStruct = [String:[String]]()
        
        for i in 0..<listDescriptor.numberOfItems{
            guard let listWindDescriptor = listDescriptor.atIndex(i + 1)?.coerce(toDescriptorType: typeAEList) else {
                return [:]
            }
            var currentKey = ""
            for j in 0..<listWindDescriptor.numberOfItems{
                
                if  let listTabDescriptor = listWindDescriptor.atIndex(j + 1)?.coerce(toDescriptorType: typeAEList){
                    
                    for k in 0..<listTabDescriptor.numberOfItems{
                        if let stringValue = listTabDescriptor.atIndex(k + 1)?.stringValue{
                            
                            if let id  = Int(stringValue){
                                currentKey = stringValue
                                var arrTabs = [String]()
                                tabStruct[currentKey] = arrTabs
                            }else{
                                if !currentKey.isEmpty{
                                    var tabArr = tabStruct[currentKey] ?? []
                                    tabArr.append(stringValue)
                                    tabStruct[currentKey] = tabArr
                                }
                            }
                            
                        }
                        
                    }
                    
                }
            }
        }
        
        return tabStruct;
    }
}


// This font is from storybord change this according to user settings
extension NSTextField {//CourierNewPSMT // CourierNewPS-BoldMT
    open override func awakeFromNib() {
        super.awakeFromNib()

        if self.font?.fontName == "CourierNewPS-BoldMT"{
            font = getBoldFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == "CourierNewPSMT"{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".AppleSystemUIFontBold"{
            font = getBoldFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".AppleSystemUIFont"{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".SF NS Regular"{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".SFNS-Bold"{
            font = getBoldFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".AppleSystemUIFontMedium"{
            font = getMediumFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".AppleSystemUIFontDemi"{
            font = getSemiBoldFont(size: self.font?.pointSize ?? 24)
        }else{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }
    }//.AppleSystemUIFontMedium
}//.AppleSystemUIFontDemi semi bold

extension NSButton {
    open override func awakeFromNib() {
        super.awakeFromNib()
        if self.font?.fontName == "CourierNewPS-BoldMT"{
            font = getBoldFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == "CourierNewPSMT"{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".AppleSystemUIFontBold"{
            font = getBoldFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".AppleSystemUIFont"{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".SF NS Regular"{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".SFNS-Bold"{
            font = getBoldFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".AppleSystemUIFontMedium"{
            font = getMediumFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".AppleSystemUIFontDemi"{
            font = getSemiBoldFont(size: self.font?.pointSize ?? 24)
        }else{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }
    }
}
extension NSSegmentedControl {
    open override func awakeFromNib() {
        super.awakeFromNib()
        if self.font?.fontName == "CourierNewPS-BoldMT"{
            font = getBoldFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == "CourierNewPSMT"{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".AppleSystemUIFontBold"{
            font = getBoldFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".AppleSystemUIFont"{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".SF NS Regular"{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".SFNS-Bold"{
            font = getBoldFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".AppleSystemUIFontMedium"{
            font = getMediumFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".AppleSystemUIFontDemi"{
            font = getSemiBoldFont(size: self.font?.pointSize ?? 24)
        }else{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }
    }
}

extension NSTabView {
    open override func awakeFromNib() {
        super.awakeFromNib()
        if self.font.fontName == "CourierNewPS-BoldMT"{
            font = getBoldFont(size: self.font.pointSize)
        }else if self.font.fontName == "CourierNewPSMT"{
            font = getRegularFont(size: self.font.pointSize)
        }else if self.font.fontName == ".AppleSystemUIFontBold"{
            font = getBoldFont(size: self.font.pointSize)
        }else if self.font.fontName == ".AppleSystemUIFont"{
            font = getRegularFont(size: self.font.pointSize)
        }else if self.font.fontName == ".SF NS Regular"{
            font = getRegularFont(size: self.font.pointSize)
        }else if self.font.fontName == ".SFNS-Bold"{
            font = getBoldFont(size: self.font.pointSize)
        }else if self.font.fontName == ".AppleSystemUIFontMedium"{
            font = getMediumFont(size: self.font.pointSize)
        }else if self.font.fontName == ".AppleSystemUIFontDemi"{
            font = getSemiBoldFont(size: self.font.pointSize)
        }else{
            font = getRegularFont(size: self.font.pointSize)
        }
    }
}

extension NSTextView {
    open override func awakeFromNib() {
        super.awakeFromNib()
        if self.font != nil{
            if self.font!.fontName == "CourierNewPS-BoldMT"{
                font = getBoldFont(size: self.font!.pointSize)
            }else if self.font!.fontName == "CourierNewPSMT"{
                font = getRegularFont(size: self.font!.pointSize)
            }else if self.font!.fontName == ".AppleSystemUIFontBold"{
                font = getBoldFont(size: self.font!.pointSize)
            }else if self.font!.fontName == ".AppleSystemUIFont"{
                font = getRegularFont(size: self.font!.pointSize)
            }else if self.font!.fontName == ".SF NS Regular"{
                font = getRegularFont(size: self.font!.pointSize)
            }else if self.font?.fontName == ".SFNS-Bold"{
                font = getBoldFont(size: self.font?.pointSize ?? 24)
            }else if self.font?.fontName == ".AppleSystemUIFontMedium"{
                font = getMediumFont(size: self.font?.pointSize ?? 24)
            }else if self.font?.fontName == ".AppleSystemUIFontDemi"{
                font = getSemiBoldFont(size: self.font?.pointSize ?? 24)
            }else{
                font = getRegularFont(size: self.font?.pointSize ?? 24)
            }
        }else{
            font = getRegularFont(size: 13)
        }
    }
}


extension NSFont {
    
    func getFontWeight() -> NSFont.Weight {
        
        let fontAttributeKey = NSFontDescriptor.AttributeName.init(rawValue: "NSCTFontUIUsageAttribute")
        if let fontWeight = self.fontDescriptor.fontAttributes[fontAttributeKey] as? String {
            switch fontWeight {
                
            case "CTFontBoldUsage":
                return NSFont.Weight.bold
                
            case "CTFontBlackUsage":
                return NSFont.Weight.black
                
            case "CTFontHeavyUsage":
                return NSFont.Weight.heavy
                
            case "CTFontUltraLightUsage":
                return NSFont.Weight.ultraLight
                
            case "CTFontThinUsage":
                return NSFont.Weight.thin
                
            case "CTFontLightUsage":
                return NSFont.Weight.light
                
            case "CTFontMediumUsage":
                return NSFont.Weight.medium
                
            case "CTFontDemiUsage":
                return NSFont.Weight.semibold
                
            case "CTFontRegularUsage":
                return NSFont.Weight.regular
                
            default:
                return NSFont.Weight.regular
            }
        }
        
        return NSFont.Weight.regular
    }
}



//************* andom color**************//
extension NSColor {
    static var random: NSColor {
        let r:CGFloat  = .random(in: 0...1)
        let g:CGFloat  = .random(in: 0...1)
        let b:CGFloat  = .random(in: 0...1)
        return NSColor(red: r, green: g, blue: b, alpha: 1)
    }

    /// "#RRGGBB" → colour. Returns nil for malformed input.
    convenience init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(srgbRed: CGFloat((v >> 16) & 0xFF) / 255.0,
                  green: CGFloat((v >> 8) & 0xFF) / 255.0,
                  blue: CGFloat(v & 0xFF) / 255.0, alpha: 1)
    }

    /// Colour → "#RRGGBB".
    var hexString: String {
        guard let c = usingColorSpace(.sRGB) else { return "#000000" }
        return String(format: "#%02X%02X%02X",
                      Int(round(c.redComponent * 255)),
                      Int(round(c.greenComponent * 255)),
                      Int(round(c.blueComponent * 255)))
    }
}




extension NSAlert{
    func setSharingType() {
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.window.sharingType = .none
            }
        }
    }
}


// zip a folder
public extension URL {
    
    /// Creates a zip archive of the file/folder represented by this URL and returns a references to the zipped file
    ///
    /// - parameter dest: the destination URL; if nil, the destination will be this URL with ".zip" appended
    func zip(dest: URL) throws -> URL {
        let destURL = dest// ?? self.URLByAppendingPathExtension("zip")
        
        let fm = FileManager.default
        if fm.fileExists(atPath: destURL.path){
            do{
                try fm.removeItem(at: destURL)
            }catch{
                print(error.localizedDescription)
            }
        }
        var isDir: ObjCBool = false
        
        let srcDir: URL
        let srcDirIsTemporary: Bool
        let path = self.path //{
        
        srcDir = self
        srcDirIsTemporary = false
        
        let coord = NSFileCoordinator()
        var error: NSError?
        
        // coordinateReadingItemAtURL is invoked synchronously, but the passed in zippedURL is only valid
        // for the duration of the block, so it needs to be copied out
        coord.coordinate(readingItemAt: srcDir as URL, options: NSFileCoordinator.ReadingOptions.forUploading, error: nil) { (zippedURL: URL) -> Void in
            do {
                try fm.copyItem(at: zippedURL, to: destURL as URL)
            } catch let err {
                error = err as NSError
            }
        }
        
        if srcDirIsTemporary { try fm.removeItem(at: srcDir as URL) }
        if let error = error { throw error }
        return destURL
    }
    
    
}


extension NSWindow {
    var hasDarkAppearance: Bool {
        if #available(OSX 10.14, *) {
            switch effectiveAppearance.name {
            case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
                return true
            default:
                return false
            }
        } else {
            switch effectiveAppearance.name {
            case .vibrantDark:
                return true
            default:
                return false
            }
        }
    }
}

extension NSView {

    var backgroundcolor: NSColor? {
        get {
            guard let layer = layer, let backgroundColor = layer.backgroundColor else { return nil }
            return NSColor(cgColor: backgroundColor)
        }
        set {
            wantsLayer = true
            layer?.backgroundColor = newValue?.cgColor
        }
    }

}

//-----------------------------------------------//

extension String {
    var length:Int {
        return self.count
    }
    func indexOf(target: String) -> Int? {
        let range = (self as NSString).range(of: target)
        guard range.toRange() != nil else {
            return nil
        }
        return range.location
    }
    func lastIndexOf(target: String) -> Int? {
        let range = (self as NSString).range(of: target, options: NSString.CompareOptions.backwards)
        
        guard range.toRange() != nil else {
            return nil
        }
        return self.length - range.location - 1
    }
    func contains(s: String) -> Bool {
        return (self.range(of: s) != nil) ? true : false
    }
}


extension NSTextField {
    var isFirstResponder: Bool {
        currentEditor() == window?.firstResponder
    }
}

extension NSBezierPath {
    
    public var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            case .cubicCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            @unknown default:
                break // Handle unknown cases safely
            }
        }
        
        return path   }
}

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

extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}

extension NSTextField{
    func setFocus(){
        self.selectText(self)
        self.currentEditor()?.selectedRange = NSRange(location: self.stringValue.count, length: 0)
    }
    
    func setFocusAndSelectText(){
        self.selectText(self)
        self.currentEditor()?.selectedRange = NSRange(location: 0, length: self.stringValue.count)
    }
}


extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow:  Date { return Date().dayAfter }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
}


// MARK: - Web to native access-token refresh (REQUEST_ACCESS_TOKEN)

final class AccessTokenRefreshCoordinator {
    static let shared = AccessTokenRefreshCoordinator()
    private init() {}

    // Most recent requestId we've been asked to satisfy, keyed by screen path.
    private var latestRequestIdByScreen: [String: String] = [:]

    func isLatest(_ requestId: String, for screen: String) -> Bool {
        return latestRequestIdByScreen[screen] == requestId
    }

    // Records the request as the latest for `screen`, then performs a silent refresh.
    // `completion` runs on the main thread with a fresh JWT, or nil on failure.
    func handleRequest(requestId: String, reason: String, screen: String,
                       completion: @escaping (_ token: String?) -> Void) {
        latestRequestIdByScreen[screen] = requestId
        addLog(text: "[token-refresh] REQUEST_ACCESS_TOKEN reason=\(reason) screen=\(screen) requestId=\(requestId)")

        guard let appdelegate = appdelegate else {
            DispatchQueue.main.async { completion(nil) }
            return
        }

        // Silent refresh. Auth0 renews automatically when the cached token is expired.
        appdelegate.credentialsManager.credentials { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let credentials):
                    if appdelegate.credential?.accessToken != credentials.accessToken {
                        appdelegate.credential = credentials
                        _ = appdelegate.credentialsManager.store(credentials: credentials)
                        appdelegate.user = AuthUser(from: credentials.accessToken)
                    }
                    addLog(text: "[token-refresh] silent refresh ok requestId=\(requestId)")
                    completion(credentials.accessToken)
                case .failure(let error):
                    // Gentle failure: no logout / no modal here (unlike setCredentialAndUserInfo).
                    // The web view shows its own retry / reload screen.
                    addLog(text: "[token-refresh] silent refresh failed: \(error.localizedDescription) requestId=\(requestId)")
                    completion(nil)
                }
            }
        }
    }
}

final class AccessTokenRequestHandler: NSObject, WKScriptMessageHandler {
    static let messageName = "request_access_token"
    static let shared = AccessTokenRequestHandler()

    func userContentController(_ userContentController: WKUserContentController,
                              didReceive message: WKScriptMessage) {
        guard message.name == AccessTokenRequestHandler.messageName else { return }

        // Body is a JSON string per the spec.
        guard
            let jsonString = message.body as? String,
            let data = jsonString.data(using: .utf8),
            let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
            let requestId = dict["requestId"] as? String
        else {
            addLog(text: "[token-refresh] could not parse REQUEST_ACCESS_TOKEN body")
            return
        }
        let reason = dict["reason"] as? String ?? "unknown"
        let screen = dict["screen"] as? String ?? ""
        // Capture the *sending* web view so we can route the reply by identity.
        // (Screen URLs are not unique: /webview/settings is used by several VCs.)
        let requestWebView = message.webView

        AccessTokenRefreshCoordinator.shared.handleRequest(requestId: requestId, reason: reason, screen: screen) { token in
            guard token != nil else { return } // failure -> web retries / shows reload screen

            // Only complete the wait for the newest request for this screen.
            guard AccessTokenRefreshCoordinator.shared.isLatest(requestId, for: screen) else {
                addLog(text: "[token-refresh] stale requestId=\(requestId); not injecting")
                return
            }

            // Route by the *sending* web view's identity. Each VC reads the now-fresh
            // appdelegate.credential and re-injects via the same loader it used on
            // initial load, carrying the requestId so web can match the reply.
            if requestWebView === taskPlayerVcObj?.webView {
                taskPlayerVcObj?.setAccessTokenToWebView(requestId: requestId)
            } else if requestWebView === selectJsonVcObj?.webview {
                selectJsonVcObj?.setSettingsToWebView(requestId: requestId)
            } else if requestWebView === editHabitRoutineVcObj?.webView {
                editHabitRoutineVcObj?.setSettingsToWebView(requestId: requestId)
            } else if requestWebView === surveyVcObj?.webView {
                surveyVcObj?.setAccessTokenToWebView(requestId: requestId)
            } else if requestWebView === manageSubscriptionVcObj?.webView {
                manageSubscriptionVcObj?.setAccessTokenToWebView(requestId: requestId)
            } else if requestWebView === addTaskVcObj?.webView {
                addTaskVcObj?.applyRefreshedAccessToken(requestId: requestId)
            } else if requestWebView === installHabitPacksVcObj?.webView {
                installHabitPacksVcObj?.applyRefreshedAccessToken(requestId: requestId)
            } else {
                addLog(text: "[token-refresh] no loader mapping for screen=\(screen)")
            }
        }
    }
}



