import Cocoa

class TextFieldNumberFormatter: NumberFormatter {
    
    @IBInspectable var maxLength: Int = Int(Int32.max)
    @IBInspectable var fractionDigits: Int = 2
    @IBInspectable var roundingDigits: Int = 2
    @IBInspectable var isInteger: Bool = false
    
    override func string(for obj: Any?) -> String? {
        
        if let stringValue = obj as? String {
            
            if isInteger {
                return Int(stringValue)?.description ?? "0"
            }
            
            let value = (stringValue as NSString).doubleValue
            let interimValue = (value.fractionDigits(digits: roundingDigits, roundingMode: .halfEven) as NSString).doubleValue
            return interimValue.fractionDigits(digits: fractionDigits, roundingMode: .halfEven)
            
        }
        
        return nil
        
    }
    
    
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        
        obj?.pointee = string as AnyObject
        return true
        
    }
    
    
    override func isPartialStringValid(_ partialStringPtr: AutoreleasingUnsafeMutablePointer<NSString>, proposedSelectedRange proposedSelRangePtr: NSRangePointer?, originalString origString: String, originalSelectedRange origSelRange: NSRange, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {

        let partialStringPtr = partialStringPtr
        if partialStringPtr.pointee.length > maxLength {
            return false
        }
        
        if isInteger {
            if !partialStringPtr.pointee.isNumber {
                return false
            }
        } else {
            if !partialStringPtr.pointee.isNumberOrDouble {
                return false
            }
        }
        
        return true

    }
    
    
}

extension NSString {
    
    var isNumberOrDouble: Bool {
        let regex = try! NSRegularExpression(pattern: "[^-0-9.]", options: .caseInsensitive)
        return !(regex.firstMatch(in: self as String, options: [], range: NSMakeRange(0, self.length)) != nil)
        
        // this does not allow -ve values
        //return Int(self as String) != nil || Double(self as String) != nil
    }
    var isNumber: Bool {
        let regex = try! NSRegularExpression(pattern: "[^-0-9]", options: .caseInsensitive)
        return !(regex.firstMatch(in: self as String, options: [], range: NSMakeRange(0, self.length)) != nil)
        
        // this does not allow negative values
        //return Int(self as String) != nil
    }
    
}

extension Double {
    
    func fractionDigits(digits: Int? = 2, roundingMode: NumberFormatter.RoundingMode) -> String {
        
        let formatter = NumberFormatter()
        formatter.thousandSeparator = ""
        formatter.maximumFractionDigits = digits!
        formatter.minimumFractionDigits = digits!
        formatter.roundingMode = roundingMode
        formatter.numberStyle = .decimal
        
        return formatter.string(for: self) ?? "0"
        
    }
    
}
