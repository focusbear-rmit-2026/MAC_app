//
//  tblCellFocus.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 17/02/22.

//

import Cocoa

class tblCellFocus: NSTableCellView {


  //  @IBOutlet weak var hoursPopupBtn: NSPopUpButton!
    @IBOutlet weak var horizaontalLine: NSBox!
    @IBOutlet weak var lblUntil: NSTextField!
    @IBOutlet weak var lblHour: NSTextField!
    @IBOutlet weak var lblFor: NSTextField!
    @IBOutlet weak var imgViewAppIcon: NSImageView!
    @IBOutlet weak var stepperHourValue: NSStepper!
    @IBOutlet weak var boxColor: NSBox!
    @IBOutlet weak var textFieldCustomHour: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var imgViewCheckMarkSecond: NSImageView!
    @IBOutlet weak var imgViewCheckMarkFirst: NSImageView!
    @IBOutlet weak var boxtitle: customBox!
    @IBOutlet weak var boxChildFirst: customBox!
    @IBOutlet weak var boxChildSecond: customBox!
 //   var isFirstTime = true
    
    var currentRow = 0
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

      //  if isFirstTime{
         //   isFirstTime = false
         //   hoursPopupBtn.removeAllItems()
        //    hoursPopupBtn.addItems(withTitles: ["1","2","3","4","5","6","7","8","9","10","11","12"])
           
        //}
        // Drawing code here.
    }
    
//    @IBAction func stepperClicked(_ sender: Any) {
//        endFocusModeTime = nil
//        textFieldCustomHour.integerValue = stepperHourValue.integerValue
//        arrFocusType[currentRow]["hourValue"] = textFieldCustomHour.integerValue
//        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
//        if timerForFocusMode != nil{
//            timerForFocusMode?.invalidate()
//            timerForFocusMode = nil
//        }
//        let calendar = Calendar.current
//        endFocusModeTime = calendar.date(byAdding: .hour, value: textFieldCustomHour.integerValue, to: Date())
//        isFocusTimeType = ._HOUR_
//        appdelegate?.setFocusModeTimer(hour: textFieldCustomHour.integerValue, minute: nil)
//        menuViewControllerObj?.tblViewFocusMode.reloadData()
//    }
//    @IBAction func btnHourClicked(_ sender: Any) {
//        endFocusModeTime = nil
//        if timerForFocusMode != nil{
//            timerForFocusMode?.invalidate()
//            timerForFocusMode = nil
//        }
//        let calendar = Calendar.current
//        endFocusModeTime = calendar.date(byAdding: .hour, value: textFieldCustomHour.integerValue, to: Date())
//        isFocusTimeType = ._HOUR_
//        appdelegate?.setFocusModeTimer(hour: textFieldCustomHour.integerValue, minute: nil)
//        menuViewControllerObj?.tblViewFocusMode.reloadData()
//    }
//    @IBAction func btnUntilShutOffClicked(_ sender: Any) {
//        endFocusModeTime = nil
//        if timerForFocusMode != nil{
//            timerForFocusMode?.invalidate()
//            timerForFocusMode = nil
//        }
//        isFocusTimeType = ._TILL_SHUTOFF_
//        menuViewControllerObj?.tblViewFocusMode.reloadData()
//    }
    
}

