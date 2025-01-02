import Cocoa

class PopoverViewControllerForSearch: NSViewController {

    @IBOutlet weak var tblView: NSTableView!
    var itemsarr = [[String : Any]]()
    var textFieldObj:PopoverAwareSearchField?

    override func viewDidLoad() {
        super.viewDidLoad()
        tblView.doubleAction = #selector(doubleClicked)
        tblView.delegate = self
        tblView.dataSource = self
        
        self.view.wantsLayer = true
        self.view.layer?.cornerRadius = 5
    }
    
    @objc func ReloadData(arr:[[String:Any]]){
        itemsarr = arr
//        for i in 0..<arr.count{
//            itemsarr.append(["id":i, "title":arr[i]])
//        }
    }
    @objc func doubleClicked(){
        addLog(text:"[user-action] rememberNextHabitVc:- doubleClicked")
        var id = ""
        var object:NSView?
        
        if tblView.selectedRow != -1{
            textFieldObj?.stringValue = itemsarr[tblView.selectedRow]["title"] as? String ?? ""
            id = itemsarr[tblView.selectedRow]["tabId"] as? String ?? ""
            object = itemsarr[tblView.selectedRow]["object"] as? NSView
            textFieldObj?.selectedItemId = id
            textFieldObj?.Close()
        }
        
        textFieldObj?.parentVcObj?.optionSelectedByUser(id: id, object: object)
    }
    
    @objc func selectNext(){
        if tblView == nil{
            return
        }
        let selectedRow = tblView.selectedRow
        tblView.selectRowIndexes(IndexSet(arrayLiteral: selectedRow+1), byExtendingSelection: false)
        
//        if tblView.selectedRow != -1{
//            textFieldObj?.stringValue = itemsarr[tblView.selectedRow]
//            textFieldObj?.Close()
//        }else{
//
//        }
    }
    @objc func selectPrevious(){
        if tblView == nil{
            return
        }
        let selectedRow = tblView.selectedRow
        tblView.selectRowIndexes(IndexSet(arrayLiteral: selectedRow-1), byExtendingSelection: false)
    }
    override func keyUp(with theEvent: NSEvent) {
        super.keyUp(with: theEvent)
        if theEvent.keyCode == 53{
            textFieldObj?.Close()
            return
        }
        if theEvent.keyCode == 36 || theEvent.keyCode == 76{
            doubleClicked()
            return
        }

    }
}

extension PopoverViewControllerForSearch: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return itemsarr.count
        
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var cellView: NSTableCellView?
        
        
        
        let item = itemsarr[row]
        cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Popover"), owner: nil) as? NSTableCellView
        cellView?.textField?.stringValue = item["title"] as? String ?? ""
//        let font = NSFont(name: "System", size: 10)
//        cellView?.textField?.font = font
        
        
        
        return cellView!
        
    }
    
//    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
//        var rowHeight: CGFloat?
//        if tableView == self.addPhoneTableView || tableView == self.addEmailTableView {
//            rowHeight = 26
//        } else if tableView == self.attachmentTableView {
//            rowHeight = 17
//        }
//        return rowHeight!
//    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
//        if tblView.selectedRow != -1{
//            textFieldObj?.stringValue = itemsarr[tblView.selectedRow]
//            textFieldObj?.Close()
//        }

        
    }
    
    
}
