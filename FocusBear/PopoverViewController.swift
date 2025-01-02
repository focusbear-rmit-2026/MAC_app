import Cocoa

class PopoverViewController: NSViewController {

    @IBOutlet weak var tblView: NSTableView!
    var itemsarr = [[String : Any]]()
    var textFieldObj:PopoverAwareTextField?

    override func viewDidLoad() {
        super.viewDidLoad()
        tblView.doubleAction = #selector(doubleClicked)
        tblView.delegate = self
        tblView.dataSource = self
        
    }
    
    @objc func ReloadData(arr:[String]){
        itemsarr.removeAll()
        for i in 0..<arr.count{
            itemsarr.append(["id":i, "title":arr[i]])
        }
    }
    @objc func doubleClicked(){
        addLog(text:"[user-action] rememberNextHabitVc:- doubleClicked")
        if tblView.selectedRow != -1{
            textFieldObj?.stringValue = itemsarr[tblView.selectedRow]["title"] as? String ?? ""
            textFieldObj?.selectedItemId = itemsarr[tblView.selectedRow]["id"] as? Int ?? 0
            textFieldObj?.Close()
        }
        
//        textFieldObj?.parentVcObj?.optionSelectedByUser()
    }
    
    @objc func selectNext(){
        if tblView == nil{
            return
        }
        let selectedRow = tblView.selectedRow
        tblView.selectRowIndexes(IndexSet(arrayLiteral: selectedRow+1), byExtendingSelection: false)

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

extension PopoverViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return itemsarr.count
        
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cellView: NSTableCellView?

        let item = itemsarr[row]
        cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Popover"), owner: nil) as? NSTableCellView
        cellView?.textField?.stringValue = item["title"] as? String ?? ""
        return cellView!
    }
    

    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
    }
    
    
}
