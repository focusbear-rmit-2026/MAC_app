//
//  officeModeSettingsVc.swift
//  FocusBear
//
//  Created by Jose Vega on 2026-05-19.
//  Copyright © 2026 Focus Bear. All rights reserved.
//
//  "Office Mode" settings panel (#1000).
//    - A direct Office / WFH toggle (mirrors the routine-view segmented control,
//      reusing SettingsManager.applyProfile so the status-bar/dock icon and break
//      activities update the same way).
//    - A "Switch automatically using Wi-Fi networks" sub-section that maps an SSID
//      to a mode, so Focus Bear flips automatically when you join that network.
//
//  Built programmatically — no storyboard scene required.
//  UI styling matches keyboardShortcutsSettingsVc (bold 16pt heading, NSBox
//  separator, secondaryLabelColor descriptions, orange primary buttons).
//

import Cocoa
import CoreLocation

class officeModeSettingsVc: NSViewController {

    // MARK: - UI elements
    private var tableView: NSTableView!
    private var btnAddCurrentNetwork: boxButton!
    private var btnAdd: boxButton!
    private var btnRemove: boxButton!
    private var lblPermissionWarning: NSTextField!
    private var lblHeader: NSTextField?
    private var radioOffice: NSButton!
    private var radioWFH: NSButton!

    // MARK: - State
    private var mappings: [WiFiProfileMapping] = []
    private let locationManager = CLLocationManager()
    /// True while we're waiting on a just-requested Location prompt triggered by
    /// "Use Current Network", so the delegate can resume the action once granted.
    private var pendingUseCurrentNetwork = false

    // MARK: - Strings (loaded from configjson)
    private var settingTitle     = "Office Mode"
    private var descriptionText  = "During office mode, Focus Bear will only give you office friendly break habits (e.g. stretching vs pushups)."
    private var officeModeOptionText = "Office Mode"
    private var wfhModeOptionText     = "WFH Mode"
    private var autoSwitchSectionTitle = "Switch automatically using Wi-Fi networks"
    private var autoSwitchDescription  = "Focus Bear defaults to Office mode and switches to WFH mode only on the Wi-Fi networks you mark as WFH below (e.g. your home network)."
    private var addBtnTitle      = "Add"
    private var addCurrentBtnTitle = "Use Current Network"
    private var removeBtnTitle   = "Remove Selected"
    private var colSSIDTitle     = "Wi-Fi Network (SSID)"
    private var colProfileTitle  = "Mode (WFH / Office)"
    private var alertAddTitle    = "Add Wi-Fi Profile Mapping"
    private var alertAddInfo     = "Enter the Wi-Fi network name (SSID) and the mode to switch to."
    private var alertSSIDPlaceholder     = "Wi-Fi network name (SSID)"
    private var alertModeLabel           = "Mode:"
    private var alertBtnAdd      = "Add"
    private var alertBtnCancel   = "Cancel"
    private var alertNotConnectedTitle   = "Not Connected"
    private var alertNotConnectedMessage = "Focus Bear couldn't read your current Wi-Fi network. Make sure Location Services are enabled for Focus Bear."
    private var permissionWarningText    = "⚠️ Location permission required to read Wi-Fi network name. Enable it in System Settings → Privacy & Security → Location Services."

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadConfigStrings()
        buildUI()
        tableView.delegate = self
        tableView.dataSource = self
        locationManager.delegate = self
        reload()
        // Don't request Location here — only reflect an existing denial. The prompt is
        // raised on demand when the user taps "Use Current Network".
        updateLocationWarning()
        if let header = lblHeader {
            arrForSearchFromSettings.append(["title": settingTitle, "tabId": idOfficeMode, "object": header as Any])
        }
        addLog(text: "officeModeSettingsVc viewDidLoad")
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        // Office mode can change elsewhere (routine view, Wi-Fi auto-switch), so re-sync.
        refreshModeSelection()
    }

    // MARK: - Config strings

    private func loadConfigStrings() {
        guard let info = configjson.value(forKey: "officeModeSettingsVcInfo") as? NSDictionary else { return }
        settingTitle            = info.value(forKey: "settingTitle")            as? String ?? settingTitle
        descriptionText         = info.value(forKey: "descriptionText")         as? String ?? descriptionText
        officeModeOptionText    = info.value(forKey: "officeModeOptionText")    as? String ?? officeModeOptionText
        wfhModeOptionText       = info.value(forKey: "wfhModeOptionText")       as? String ?? wfhModeOptionText
        autoSwitchSectionTitle  = info.value(forKey: "autoSwitchSectionTitle")  as? String ?? autoSwitchSectionTitle
        autoSwitchDescription   = info.value(forKey: "autoSwitchDescription")   as? String ?? autoSwitchDescription
        addBtnTitle             = info.value(forKey: "addBtnTitle")             as? String ?? addBtnTitle
        addCurrentBtnTitle      = info.value(forKey: "addCurrentBtnTitle")      as? String ?? addCurrentBtnTitle
        removeBtnTitle          = info.value(forKey: "removeBtnTitle")          as? String ?? removeBtnTitle
        colSSIDTitle            = info.value(forKey: "colSSIDTitle")            as? String ?? colSSIDTitle
        colProfileTitle         = info.value(forKey: "colProfileTitle")         as? String ?? colProfileTitle
        alertAddTitle           = info.value(forKey: "alertAddTitle")           as? String ?? alertAddTitle
        alertAddInfo            = info.value(forKey: "alertAddInfo")            as? String ?? alertAddInfo
        alertSSIDPlaceholder    = info.value(forKey: "alertSSIDPlaceholder")    as? String ?? alertSSIDPlaceholder
        alertModeLabel          = info.value(forKey: "alertModeLabel")          as? String ?? alertModeLabel
        alertBtnAdd             = info.value(forKey: "alertBtnAdd")             as? String ?? alertBtnAdd
        alertBtnCancel          = info.value(forKey: "alertBtnCancel")          as? String ?? alertBtnCancel
        alertNotConnectedTitle  = info.value(forKey: "alertNotConnectedTitle")  as? String ?? alertNotConnectedTitle
        alertNotConnectedMessage = info.value(forKey: "alertNotConnectedMessage") as? String ?? alertNotConnectedMessage
        permissionWarningText   = info.value(forKey: "permissionWarningText")   as? String ?? permissionWarningText
    }

    // MARK: - UI Construction

    private func buildUI() {
        // ── Header ────────────────────────────────────────────────────────────
        // Match the other settings panes: the title sits vertically centred inside a 50pt-high header
        // band at the top of the pane, with the separator directly below it.
        let headerBand = NSView()
        headerBand.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerBand)

        let header = NSTextField(labelWithString: settingTitle)
        // Match the other settings panes' title font (systemSemibold 14 in Settings.storyboard —
        // AI Features / Micro Breaks / Advanced etc.), rather than a larger bold 16.
        header.font = getSemiBoldFont(size: 14)
        header.translatesAutoresizingMaskIntoConstraints = false
        headerBand.addSubview(header)
        lblHeader = header

        // ── Separator ─────────────────────────────────────────────────────────
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        headerBand.addSubview(separator)

        // ── Description ───────────────────────────────────────────────────────
        let description = NSTextField(wrappingLabelWithString: descriptionText)
        description.textColor = .secondaryLabelColor
        description.font = getRegularFont(size: 13)
        description.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(description)

        // ── Office / WFH radio buttons ────────────────────────────────────────
        // Two radios sharing the same superview + action act as one mutually-exclusive group.
        let rOffice = NSButton(radioButtonWithTitle: officeModeOptionText, target: self,
                               action: #selector(modeRadioChanged(_:)))
        rOffice.translatesAutoresizingMaskIntoConstraints = false
        rOffice.font = getRegularFont(size: 13)
        view.addSubview(rOffice)
        radioOffice = rOffice

        let rWFH = NSButton(radioButtonWithTitle: wfhModeOptionText, target: self,
                            action: #selector(modeRadioChanged(_:)))
        rWFH.translatesAutoresizingMaskIntoConstraints = false
        rWFH.font = getRegularFont(size: 13)
        view.addSubview(rWFH)
        radioWFH = rWFH

        // ── Auto-switch sub-section header ────────────────────────────────────
        let autoHeader = NSTextField(labelWithString: autoSwitchSectionTitle)
        autoHeader.font = getBoldFont(size: 13)
        autoHeader.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(autoHeader)

        let autoDescription = NSTextField(wrappingLabelWithString: autoSwitchDescription)
        autoDescription.textColor = .secondaryLabelColor
        autoDescription.font = getRegularFont(size: 12)
        autoDescription.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(autoDescription)

        // ── Permission warning ────────────────────────────────────────────────
        let warning = NSTextField(wrappingLabelWithString: "")
        warning.translatesAutoresizingMaskIntoConstraints = false
        warning.isHidden = true
        warning.textColor = .systemOrange
        view.addSubview(warning)
        lblPermissionWarning = warning

        // ── Table scroll view ─────────────────────────────────────────────────
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.autohidesScrollers = true
        
        let tv = NSTableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        let colSSID = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ssid"))
        colSSID.title = colSSIDTitle
        colSSID.minWidth = 100
        colSSID.width = 200
        tv.addTableColumn(colSSID)
        let colProfile = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("profile"))
        colProfile.title = colProfileTitle
        colProfile.minWidth = 80
        tv.addTableColumn(colProfile)
        tv.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        scrollView.documentView = tv
        view.addSubview(scrollView)
        tableView = tv

        // ── Buttons ───────────────────────────────────────────────────────────
        // boxButton initialises its layer, tracking area, and cursor in init(frame:)
        // — unlike Button which only does so in awakeFromNib (not called for programmatic creation).

        // Remove Selected: secondary (white bg, gray border) — left side
        let btnR = boxButton(frame: .zero)
        btnR.translatesAutoresizingMaskIntoConstraints = false
        btnR.setTitle(removeBtnTitle)
        btnR.setImage(NSImage(systemSymbolName: "trash", accessibilityDescription: nil))
        // Match the button's black title. Without this the icon uses the default tint (labelColor),
        // which turns white in Dark Mode and disappears against the light secondary-button background.
        btnR.setImageTint(.black)
        btnR.target = self
        btnR.action = #selector(btnRemoveClicked(_:))
        btnR.isHidden = true  // shown only while a row is selected
        view.addSubview(btnR)
        btnRemove = btnR

        // Add: secondary (white bg, gray border) — right group
        let btnA = boxButton(frame: .zero)
        btnA.translatesAutoresizingMaskIntoConstraints = false
        btnA.setTitle(addBtnTitle)
        btnA.setImage(NSImage(systemSymbolName: "plus", accessibilityDescription: nil))
        // Match the button's black title. Without this the icon uses the default tint (labelColor),
        // which turns white in Dark Mode and disappears against the light secondary-button background.
        btnA.setImageTint(.black)
        btnA.target = self
        btnA.action = #selector(btnAddClicked(_:))
        view.addSubview(btnA)
        btnAdd = btnA

        // Use Current Network: primary (orange) — rightmost
        let btnC = boxButton(frame: .zero)
        btnC.translatesAutoresizingMaskIntoConstraints = false
        btnC.setTitle(addCurrentBtnTitle)
        btnC.setImage(NSImage(systemSymbolName: "wifi", accessibilityDescription: nil))
        btnC.target = self
        btnC.action = #selector(btnAddCurrentNetworkClicked(_:))
        btnC.setButtonColor(NSColor(named: "dark_OrangeColor") ?? .orange)
        btnC.borderColor = NSColor(named: "dark_OrangeColor") ?? .orange
        btnC.setTitleColor(.white)
        btnC.setImageTint(.white)   // match the white title on the orange primary button
        view.addSubview(btnC)
        btnAddCurrentNetwork = btnC

        // ── Auto Layout ───────────────────────────────────────────────────────
        NSLayoutConstraint.activate([
            // Header band: a 50pt-high strip at the top, full width — matches the other settings panes.
            headerBand.topAnchor.constraint(equalTo: view.topAnchor),
            headerBand.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBand.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBand.heightAnchor.constraint(equalToConstant: 50),

            // Title: vertically centred inside the header band, with the standard 24pt content inset.
            header.centerYAnchor.constraint(equalTo: headerBand.centerYAnchor),
            header.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: 20),
            header.trailingAnchor.constraint(lessThanOrEqualTo: headerBand.trailingAnchor, constant: -20),

            // Separator: directly below the header band, spanning the FULL width (0pt leading/trailing)
            // to match the other settings panes (their separator runs edge to edge, content stays inset).
            separator.bottomAnchor.constraint(equalTo: headerBand.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),

            // Description: 8pt below separator
            description.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 8),
            description.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            description.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Radio group: Office Mode then WFH Mode, stacked vertically
            rOffice.topAnchor.constraint(equalTo: description.bottomAnchor, constant: 16),
            rOffice.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            rOffice.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            rWFH.topAnchor.constraint(equalTo: rOffice.bottomAnchor, constant: 8),
            rWFH.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            rWFH.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            // Auto-switch sub-section header: 24pt below the radio block
            autoHeader.topAnchor.constraint(equalTo: rWFH.bottomAnchor, constant: 24),
            autoHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            autoHeader.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            // Auto-switch description: 6pt below its header
            autoDescription.topAnchor.constraint(equalTo: autoHeader.bottomAnchor, constant: 6),
            autoDescription.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            autoDescription.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Permission warning: below auto-switch description (hidden when not needed)
            warning.topAnchor.constraint(equalTo: autoDescription.bottomAnchor, constant: 8),
            warning.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            warning.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Table: 12pt below warning, ~40% of view height
            scrollView.topAnchor.constraint(equalTo: warning.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.40),

            // Buttons: 16pt below table
            // Remove Selected: left side
            btnR.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 16),
            btnR.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            btnR.heightAnchor.constraint(equalToConstant: 32),

            // Use Current Network: rightmost
            btnC.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 16),
            btnC.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            btnC.heightAnchor.constraint(equalToConstant: 32),

            // Add: to the left of Use Current Network
            btnA.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 16),
            btnA.trailingAnchor.constraint(equalTo: btnC.leadingAnchor, constant: -8),
            btnA.heightAnchor.constraint(equalToConstant: 32),
        ])

        refreshModeSelection()
    }

    // MARK: - Office Mode radio group

    /// Reflect the current office-mode state in the radio buttons.
    private func refreshModeSelection() {
        let isOffice = SettingsManagerObject.isOfficeModeEnabled
        radioOffice?.state = isOffice ? .on : .off
        radioWFH?.state = isOffice ? .off : .on
    }

    @objc private func modeRadioChanged(_ sender: NSButton) {
        let isOffice = (sender == radioOffice)
        addLog(text: "[user-action] officeModeSettingsVc: mode set -> \(isOffice ? "office" : "wfh")")
        // Enabling office mode needs at least one office-friendly break activity — otherwise the shared
        // reFillBreakActivitiesArray path silently turns office mode back OFF (and desyncs the icon).
        // Offer to add one. This prompt is deliberately only on THIS explicit user click; the Wi-Fi
        // auto-switch calls applyProfile directly and stays silent (no alert in the background).
        if isOffice, !arrAllbreakActivities.contains(where: { $0.isOfficeFriendly }) {
            promptToAddOfficeFriendlyActivityThenEnable()
            return
        }
        // Reuse the shared profile switch so the status-bar/dock icon and break
        // activities update exactly as they do from the routine view / Wi-Fi auto-switch.
        SettingsManagerObject.applyProfile(named: isOffice ? "office" : "wfh")
    }

    /// No office-friendly break activity yet: offer to add one (mirrors the routine view's check at
    /// firstViewController.segmentControlOfficeModeClicked). Yes → add it and switch to office; No →
    /// revert the radios to the unchanged (WFH) state and don't switch.
    private func promptToAddOfficeFriendlyActivityThenEnable() {
        let alert = NSAlert()
        alert.setSharingType()
        var text = "You don't have any office friendly break activities. Do you want me to add one for you to stand up and stretch for 20 seconds?"
        var firstBtn = "Yeah sounds good"
        var secondBtn = "No I'm a machine! I don't need breaks"
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary {
            text = menuInfo.value(forKey: "noOfficeFriendlyActivityAlertText") as? String ?? text
            firstBtn = menuInfo.value(forKey: "noOfficeFriendlyActivityButtonFirstText") as? String ?? firstBtn
            secondBtn = menuInfo.value(forKey: "noOfficeFriendlyActivityButtonSecondText") as? String ?? secondBtn
        }
        alert.messageText = text
        alert.addButton(withTitle: firstBtn)
        alert.addButton(withTitle: secondBtn)
        NSApplication.shared.activate(ignoringOtherApps: true)
        guard let window = self.view.window else { refreshModeSelection(); return }
        alert.beginSheetModal(for: window) { [weak self] result in
            guard let self = self else { return }
            if result == .alertFirstButtonReturn {
                menuViewControllerObj?.addOfficeFriendlyActivityInSettings()
                SettingsManagerObject.applyProfile(named: "office")
            }else{
                self.refreshModeSelection()
            }
            
        }
    }

    // MARK: - Data

    private func reload() {
        mappings = WiFiProfileMapping.loadAll()
        tableView.reloadData()
        btnRemove?.isHidden = true
    }

    // MARK: - Actions

    @objc private func btnAddCurrentNetworkClicked(_ sender: Any) {
        // Request Location on demand — this is the only place we prompt for it. macOS needs
        // Location Services authorisation before CoreWLAN returns a real SSID.
        switch locationManager.authorizationStatus {
        case .notDetermined:
            // First use: ask now; we'll read the SSID once the user responds (see delegate).
            pendingUseCurrentNetwork = true
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            updateLocationWarning()
            showAlert(title: alertNotConnectedTitle, message: permissionWarningText)
        default:
            useCurrentNetwork()
        }
    }

    /// Read the current SSID and open the add-mapping sheet pre-filled with it.
    ///
    /// The read is a blocking XPC call (see `readCurrentSSID()`), so it happens off the main thread
    /// and the sheet opens when the answer arrives. Doing it inline froze the settings window for as
    /// long as the WiFi daemon took to reply — right after a click, where a freeze reads as a
    /// dropped click.
    private func useCurrentNetwork() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let currentSSID = WiFiMonitorService.shared.readCurrentSSID() ?? ""
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard !currentSSID.isEmpty else {
                    self.showAlert(title: self.alertNotConnectedTitle, message: self.alertNotConnectedMessage)
                    return
                }
                self.showAddMappingSheet(ssid: currentSSID)
            }
        }
    }

    @objc private func btnAddClicked(_ sender: Any) {
        showAddMappingSheet(ssid: "")
    }

    @objc private func btnRemoveClicked(_ sender: Any) {
        let row = tableView.selectedRow
        guard row >= 0 && row < mappings.count else { return }
        WiFiProfileMapping.remove(id: mappings[row].id)
        reload()
    }

    // MARK: - Add Sheet

    private func showAddMappingSheet(ssid: String) {
        let alert = NSAlert()
        alert.messageText = alertAddTitle
        alert.informativeText = alertAddInfo
        alert.addButton(withTitle: alertBtnAdd)
        alert.addButton(withTitle: alertBtnCancel)

        // SSID text field on top, then a Mode radio group (Office / WFH) — no free-text typing.
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 92))

        let ssidField = NSTextField(frame: NSRect(x: 0, y: 60, width: 300, height: 24))
        ssidField.placeholderString = alertSSIDPlaceholder
        ssidField.font = getRegularFont(size: 13)
        ssidField.stringValue = ssid
        container.addSubview(ssidField)

        let modeLabel = NSTextField(labelWithString: alertModeLabel)
        modeLabel.frame = NSRect(x: 0, y: 34, width: 300, height: 18)
        modeLabel.font = getRegularFont(size: 11)
        modeLabel.textColor = .secondaryLabelColor
        container.addSubview(modeLabel)

        // Two radios sharing the same action + superview form one mutually-exclusive group.
        let rOffice = NSButton(radioButtonWithTitle: officeModeOptionText, target: self,
                               action: #selector(sheetModeRadioNoop(_:)))
        rOffice.frame = NSRect(x: 0, y: 6, width: 145, height: 20)
        container.addSubview(rOffice)

        let rWFH = NSButton(radioButtonWithTitle: wfhModeOptionText, target: self,
                            action: #selector(sheetModeRadioNoop(_:)))
        rWFH.frame = NSRect(x: 150, y: 6, width: 145, height: 20)
        rWFH.state = .on   // Office is the default mode, so adding a WFH network is the usual action
        container.addSubview(rWFH)

        alert.accessoryView = container

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let newSSID = ssidField.stringValue.trimmingCharacters(in: .whitespaces)
            guard !newSSID.isEmpty else { return }
            // Store a canonical key ("Office"/"WFH") regardless of UI language, so
            // SettingsManager.applyProfile's `== "office"` check keeps working.
            let profileName = (rOffice.state == .on) ? "Office" : "WFH"
            let mapping = WiFiProfileMapping(ssid: newSSID, profileName: profileName)
            WiFiProfileMapping.upsert(mapping)
            reload()
        }
    }

    /// No-op: radio buttons only need a shared action+superview to behave as one group;
    /// the chosen value is read from their state when the sheet is confirmed.
    @objc private func sheetModeRadioNoop(_ sender: NSButton) {}

    // MARK: - Location Permission

    /// Show the "permission needed" warning only if Location is already denied/restricted.
    /// Never requests authorisation — the prompt is raised on demand from "Use Current Network".
    private func updateLocationWarning() {
        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            lblPermissionWarning.isHidden = false
            lblPermissionWarning.stringValue = permissionWarningText
        default:
            lblPermissionWarning.isHidden = true
        }
    }

    // MARK: - Helpers

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.setSharingType()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        if let window = view.window {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }
}

// MARK: - NSTableViewDataSource / Delegate

extension officeModeSettingsVc: NSTableViewDataSource, NSTableViewDelegate {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return mappings.count
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        // Show "Remove Selected" only while a row is actually selected.
        btnRemove.isHidden = tableView.selectedRow < 0
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let mapping = mappings[row]
        let identifier = NSUserInterfaceItemIdentifier("WiFiMappingCell")
        if let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
            if tableColumn?.identifier.rawValue == "ssid" {
                cell.textField?.stringValue = mapping.ssid
            } else {
                cell.textField?.stringValue = mapping.profileName
            }
            return cell
        }
        let cellView = NSTableCellView()
        cellView.identifier = identifier
        let textField = NSTextField(labelWithString: "")
        textField.font = getRegularFont(size: 13)
        textField.translatesAutoresizingMaskIntoConstraints = false
        cellView.addSubview(textField)
        cellView.textField = textField
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 4),
            textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -4),
            textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
        ])
        if tableColumn?.identifier.rawValue == "ssid" {
            cellView.textField?.stringValue = mapping.ssid
        } else {
            cellView.textField?.stringValue = mapping.profileName
        }
        return cellView
    }
}

// MARK: - CLLocationManagerDelegate

extension officeModeSettingsVc: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateLocationWarning()
            // Resume a "Use Current Network" tap that was waiting on the first-time prompt.
            guard self.pendingUseCurrentNetwork, status != .notDetermined else { return }
            self.pendingUseCurrentNetwork = false
            switch status {
            case .denied, .restricted:
                self.showAlert(title: self.alertNotConnectedTitle, message: self.permissionWarningText)
            default:
                self.useCurrentNetwork()
            }
        }
    }
}
