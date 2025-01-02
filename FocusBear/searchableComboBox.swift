import Cocoa

protocol SearchableComboBoxDelegate {
    func itemSelectedByUser(comboBox: searchableComboBox)
}


class searchableComboBox: NSComboBox, NSComboBoxCellDataSource, NSComboBoxDataSource, NSComboBoxDelegate {
    
    var items = [""]
    var filterdItems = [""]
    var menuShowByButton = true
    var customDelegate: SearchableComboBoxDelegate?
    
    init() {
        super.init(frame: NSZeroRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.delegate = self
        self.dataSource = self
        (self.cell as! NSComboBoxCell).dataSource = self
    }
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        print("SubString = \(string)")
        print(filterdItems.count)
        let filteredArray = filterdItems.filter {$0.caseInsensitiveCompare(string) == .orderedSame}
        if filteredArray.count != 0{
            self.stringValue = filteredArray.first!
        }
        return string
    }

    func filterData(comboBox:NSComboBox, selectedText:String){
        filterdItems.removeAll()
        if selectedText == ""{
            filterdItems = items
            comboBox.reloadData()
            for i in 0..<filterdItems.count{
                let item = filterdItems[i]
                if item.caseInsensitiveCompare(self.stringValue) == .orderedSame {
                    comboBox.selectItem(at: i)
                }
            }
        }else{
            for item in items{
                if item.localizedCaseInsensitiveContains(selectedText){
                    filterdItems.append(item)
                }
            }
            comboBox.reloadData()
        }
    }
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return(filterdItems.count)
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return(filterdItems[index] as AnyObject)
    }
    
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        var i = 0
        for str in filterdItems {
            if str == string{
                return i
            }
            i += 1
        }
        return -1
    }
    func controlTextDidChange(_ obj: Notification) {
        print("controlTextDidChange")
        if let object = obj.object as? NSComboBox{
            filterData(comboBox: object, selectedText: object.stringValue)
            expandPopUp(comboBox: object, value: object.stringValue)
        }
    }
    func controlTextDidEndEditing(_ obj: Notification) {
        print("textDidEndEditing123")
        customDelegate?.itemSelectedByUser(comboBox: self)
    }
    func comboBoxWillPopUp(_ notification: Notification) {
        if menuShowByButton == false{
            menuShowByButton = true
            if let object = notification.object as? NSComboBox{
                filterData(comboBox: object, selectedText: object.stringValue)
            }
        }else{
            if let object = notification.object as? NSComboBox{
                filterData(comboBox: object, selectedText: "")
            }
            
        }
    }
    func expandPopUp(comboBox:NSComboBox, value:String){
        let isValueEmpty = value.isEmpty
        let isPopUpExpanded = comboBox.isAccessibilityExpanded()
        
        if (isValueEmpty && isPopUpExpanded){
            comboBox.cell?.setAccessibilityExpanded(false)
        }
        if (!isValueEmpty && !isPopUpExpanded){
            comboBox.cell?.setAccessibilityExpanded(true)
            menuShowByButton = false
        }
    }
}
