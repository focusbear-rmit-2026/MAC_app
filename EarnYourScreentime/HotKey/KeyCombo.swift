import AppKit

public struct KeyCombo: Equatable {
    public static func ==(lhs: KeyCombo, rhs: KeyCombo) -> Bool {
        return true
    }
    

	// MARK: - Properties

	public var carbonKeyCode: UInt32
	public var carbonModifiers: UInt32

	public var key: Key? {
		get {
			return Key(carbonKeyCode: carbonKeyCode)
		}

		set {
			carbonKeyCode = newValue?.carbonKeyCode ?? 0
		}
	}

	public var modifiers: NSEvent.ModifierFlags {
		get {
			return NSEvent.ModifierFlags(carbonFlags: carbonModifiers)
		}

		set {
			carbonModifiers = modifiers.carbonFlags
		}
	}

	public var isValid: Bool {
		return carbonKeyCode >= 0
	}

	// MARK: - Initializers

	public init(carbonKeyCode: UInt32, carbonModifiers: UInt32 = 0) {
		self.carbonKeyCode = carbonKeyCode
		self.carbonModifiers = carbonModifiers
	}

	public init(key: Key, modifiers: NSEvent.ModifierFlags = []) {
		self.carbonKeyCode = key.carbonKeyCode
		self.carbonModifiers = modifiers.carbonFlags
	}
    public init(stkey: String, modifiers: NSEvent.ModifierFlags = []) {
        
            var Key:Key?
        
            switch stkey.lowercased() {
            case "a": Key = .a
            case "s": Key = .s
            case "d": Key = .d
            case "f": Key = .f
            case "h": Key = .h
            case "g": Key = .g
            case "z": Key = .z
            case "x": Key = .x
            case "c": Key = .c
            case "v": Key = .v
            case "b": Key = .b
            case "q": Key = .q
            case "w": Key = .w
            case "e": Key = .e
            case "r": Key = .r
            case "y": Key = .y
            case "t": Key = .t
            case "one", "1": Key = .one
            case "two", "2": Key = .two
            case "three", "3": Key = .three
            case "four", "4": Key = .four
            case "six", "6": Key = .six
            case "five", "5": Key = .five
            case "equal", "=": Key = .equal
            case "nine", "9": Key = .nine
            case "seven", "7": Key = .seven
            case "minus", "-": Key = .minus
            case "eight", "8": Key = .eight
            case "zero", "0": Key = .zero
            case "rightBracket", "]": Key = .rightBracket
            case "o": Key = .o
            case "u": Key = .u
            case "leftBracket", "[": Key = .leftBracket
            case "i": Key = .i
            case "p": Key = .p
            case "l": Key = .l
            case "j": Key = .j
            case "quote", "\"": Key = .quote
            case "k": Key = .k
            case "semicolon", ";": Key = .semicolon
            case "backslash", "\\": Key = .backslash
            case "comma", ",": Key = .comma
            case "slash", "/": Key = .slash
            case "n": Key = .n
            case "m": Key = .m
            case "period", ".": Key = .period
            case "grave", "`", "ˋ", "｀": Key = .grave
            case "keypaddecimal": Key = .keypadDecimal
            case "keypadmultiply": Key = .keypadMultiply
            case "keypadplus": Key = .keypadPlus
            case "keypadclear", "⌧": Key = .keypadClear
            case "keypaddivide": Key = .keypadDivide
            case "keypadenter": Key = .keypadEnter
            case "keypadminus": Key = .keypadMinus
            case "keypadequals": Key = .keypadEquals
            case "keypad0": Key = .keypad0
            case "keypad1": Key = .keypad1
            case "keypad2": Key = .keypad2
            case "keypad3": Key = .keypad3
            case "keypad4": Key = .keypad4
            case "keypad5": Key = .keypad5
            case "keypad6": Key = .keypad6
            case "keypad7": Key = .keypad7
            case "keypad8": Key = .keypad8
            case "keypad9": Key = .keypad9
            case "return", "\r", "↩︎", "⏎", "⮐": Key = .return
            case "tab", "\t", "⇥": Key = .tab
            case "space", " ", "␣": Key = .space
            case "delete", "⌫": Key = .delete
            case "escape", "⎋": Key = .escape
            case "command", "⌘", "": Key = .command
            case "shift", "⇧": Key = .shift
            case "capslock", "⇪": Key = .capsLock
            case "option", "⌥": Key = .option
            case "control", "⌃": Key = .control
            case "rightcommand": Key = .rightCommand
            case "rightshift": Key = .rightShift
            case "rightoption": Key = .rightOption
            case "rightcontrol": Key = .rightControl
            case "function", "fn": Key = .function
            case "f17", "F17": Key = .f17
            case "volumeup", "🔊": Key = .volumeUp
            case "volumedown", "🔉": Key = .volumeDown
            case "mute", "🔇": Key = .mute
            case "f18", "F18": Key = .f18
            case "f19", "F19": Key = .f19
            case "f20", "F20": Key = .f20
            case "f5", "F5": Key = .f5
            case "f6", "F6": Key = .f6
            case "f7", "F7": Key = .f7
            case "f3", "F3": Key = .f3
            case "f8", "F8": Key = .f8
            case "f9", "F9": Key = .f9
            case "f11", "F11": Key = .f11
            case "f13", "F13": Key = .f13
            case "f16", "F16": Key = .f16
            case "f14", "F14": Key = .f14
            case "f10", "F10": Key = .f10
            case "f12", "F12": Key = .f12
            case "f15", "F15": Key = .f15
            case "help", "?⃝": Key = .help
            case "home", "↖": Key = .home
            case "pageup", "⇞": Key = .pageUp
            case "forwarddelete", "⌦": Key = .forwardDelete
            case "f4", "F4": Key = .f4
            case "end", "↘": Key = .end
            case "f2", "F2": Key = .f2
            case "pagedown", "⇟": Key = .pageDown
            case "f1", "F1": Key = .f1
            case "leftarrow", "←": Key = .leftArrow
            case "rightarrow", "→": Key = .rightArrow
            case "downarrow", "↓": Key = .downArrow
            case "uparrow", "↑": Key = .upArrow
            default: Key = nil
            if Key == nil{
                Key = .a
            }
        }
      
        
        self.carbonKeyCode = (Key?.carbonKeyCode)!
        self.carbonModifiers = modifiers.carbonFlags
    }
     func getKey(key: String)->Key? {
        //self.carbonKeyCode = key.carbonKeyCode
    
            switch key.lowercased() {
            case "a": return .a
            case "s": return .s
            case "d": return .d
            case "f": return .f
            case "h": return .h
            case "g": return .g
            case "z": return .z
            case "x": return .x
            case "c": return .c
            case "v": return .v
            case "b": return .b
            case "q": return .q
            case "w": return .w
            case "e": return .e
            case "r": return .r
            case "y": return .y
            case "t": return .t
            case "one", "1": return .one
            case "two", "2": return .two
            case "three", "3": return .three
            case "four", "4": return .four
            case "six", "6": return .six
            case "five", "5": return .five
            case "equal", "=": return .equal
            case "nine", "9": return .nine
            case "seven", "7": return .seven
            case "minus", "-": return .minus
            case "eight", "8": return .eight
            case "zero", "0": return .zero
            case "rightBracket", "]": return .rightBracket
            case "o": return .o
            case "u": return .u
            case "leftBracket", "[": return .leftBracket
            case "i": return .i
            case "p": return .p
            case "l": return .l
            case "j": return .j
            case "quote", "\"": return .quote
            case "k": return .k
            case "semicolon", ";": return .semicolon
            case "backslash", "\\": return .backslash
            case "comma", ",": return .comma
            case "slash", "/": return .slash
            case "n": return .n
            case "m": return .m
            case "period", ".": return .period
            case "grave", "`", "ˋ", "｀": return .grave
            case "keypaddecimal": return .keypadDecimal
            case "keypadmultiply": return .keypadMultiply
            case "keypadplus": return .keypadPlus
            case "keypadclear", "⌧": return .keypadClear
            case "keypaddivide": return .keypadDivide
            case "keypadenter": return .keypadEnter
            case "keypadminus": return .keypadMinus
            case "keypadequals": return .keypadEquals
            case "keypad0": return .keypad0
            case "keypad1": return .keypad1
            case "keypad2": return .keypad2
            case "keypad3": return .keypad3
            case "keypad4": return .keypad4
            case "keypad5": return .keypad5
            case "keypad6": return .keypad6
            case "keypad7": return .keypad7
            case "keypad8": return .keypad8
            case "keypad9": return .keypad9
            case "return", "\r", "↩︎", "⏎", "⮐": return .return
            case "tab", "\t", "⇥": return .tab
            case "space", " ", "␣": return .space
            case "delete", "⌫": return .delete
            case "escape", "⎋": return .escape
            case "command", "⌘", "": return .command
            case "shift", "⇧": return .shift
            case "capslock", "⇪": return .capsLock
            case "option", "⌥": return .option
            case "control", "⌃": return .control
            case "rightcommand": return .rightCommand
            case "rightshift": return .rightShift
            case "rightoption": return .rightOption
            case "rightcontrol": return .rightControl
            case "function", "fn": return .function
            case "f17", "F17": return .f17
            case "volumeup", "🔊": return .volumeUp
            case "volumedown", "🔉": return .volumeDown
            case "mute", "🔇": return .mute
            case "f18", "F18": return .f18
            case "f19", "F19": return .f19
            case "f20", "F20": return .f20
            case "f5", "F5": return .f5
            case "f6", "F6": return .f6
            case "f7", "F7": return .f7
            case "f3", "F3": return .f3
            case "f8", "F8": return .f8
            case "f9", "F9": return .f9
            case "f11", "F11": return .f11
            case "f13", "F13": return .f13
            case "f16", "F16": return .f16
            case "f14", "F14": return .f14
            case "f10", "F10": return .f10
            case "f12", "F12": return .f12
            case "f15", "F15": return .f15
            case "help", "?⃝": return .help
            case "home", "↖": return .home
            case "pageup", "⇞": return .pageUp
            case "forwarddelete", "⌦": return .forwardDelete
            case "f4", "F4": return .f4
            case "end", "↘": return .end
            case "f2", "F2": return .f2
            case "pagedown", "⇟": return .pageDown
            case "f1", "F1": return .f1
            case "leftarrow", "←": return .leftArrow
            case "rightarrow", "→": return .rightArrow
            case "downarrow", "↓": return .downArrow
            case "uparrow", "↑": return .upArrow
            default: return nil
            }
        
        
    }

    
    
	// MARK: - Converting Keys

	public static func carbonKeyCodeToString(_ carbonKeyCode: UInt32) -> String? {
		return nil
	}
}

extension KeyCombo {
	public var dictionary: [String: Any] {
		return [
			"keyCode": Int(carbonKeyCode),
			"modifiers": Int(carbonModifiers)
		]
	}

	public init?(dictionary: [String: Any]) {
		guard let keyCode = dictionary["keyCode"] as? Int,
			let modifiers = dictionary["modifiers"] as? Int
		else {
			return nil
		}

		self.init(carbonKeyCode: UInt32(keyCode), carbonModifiers: UInt32(modifiers))
	}
}

extension KeyCombo: CustomStringConvertible {
    public var description: String {
        var output = modifiers.description

        if let keyDescription = key?.description {
            output += keyDescription
        }

        return output
    }
}
