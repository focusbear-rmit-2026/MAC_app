//
//  addOnsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 19/12/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class addOnsVc: NSViewController {

    @IBOutlet weak var btnConnect: Button!
    @IBOutlet weak var lblDescriptionFocusButton: NSTextField!
    @IBOutlet weak var lblTitleFocusButton: NSTextField!
    @IBOutlet weak var boxFocusButton: NSBox!
    @IBOutlet weak var boxGetLateNoMore: NSBox!
    @IBOutlet weak var lblLateNoMoreAlreadyInstalled: NSTextField!
    @IBOutlet weak var btnGetLateNoMore: Button!
    @IBOutlet weak var lblDescriptionLateNoMore: NSTextField!
    @IBOutlet weak var lblTitleLateNoMore: NSTextField!
    @IBOutlet weak var btnBack: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var stackView: NSStackView!
    
    /// Shows the connected Focus Button's firmware version (e.g. "Firmware: M50-1.5.0").
    var lblFirmwareVersion: NSTextField?
    /// "Check for Updates" / "Flash Firmware" button (mirrors the Windows UI).
    var btnFirmwareUpdate: NSButton?
    /// Spinning indicator shown next to the firmware status while checking/downloading/flashing.
    var firmwareSpinner: NSProgressIndicator?
    private var isFlashingFirmware = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitleFocusButton.stringValue = "Focus Button"
        lblDescriptionFocusButton.stringValue = "The FocusButton device connects to your computer using a USB cable and works together with the app to help manage focus sessions and actions. Once connected, the app automatically detects the device and establishes communication with it."
        btnConnect.title = "Connect"
        
        
        lblLateNoMoreAlreadyInstalled.stringValue = "Late No More already installed"
        lblTitle.stringValue = "Add Ons"
        btnGetLateNoMore.title = "Get Late No More"
        lblTitleLateNoMore.stringValue = "Get Late No More"
        lblDescriptionLateNoMore.stringValue = "Late No More gives notifications that escalate in intensity as it gets closer to the meetings start time. If you ignore the popups, you'll get verbal alerts (or a song)."

        

        if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary{
            lblLateNoMoreAlreadyInstalled.stringValue = settingsNew.value(forKey: "lateNoMoreAlreadyInstalledText") as? String ?? lblLateNoMoreAlreadyInstalled.stringValue
            lblTitle.stringValue = settingsNew.value(forKey: "addOnsTitle") as? String ?? lblTitle.stringValue
            lblTitleLateNoMore.stringValue = settingsNew.value(forKey: "titleGetLateNoMore") as? String ?? lblTitleLateNoMore.stringValue
            btnGetLateNoMore.title = settingsNew.value(forKey: "titleGetLateNoMore") as? String ?? btnGetLateNoMore.title
            
            lblTitleFocusButton.stringValue = settingsNew.value(forKey: "titleFocusButton") as? String ?? lblTitleFocusButton.stringValue
            lblDescriptionFocusButton.stringValue = settingsNew.value(forKey: "descriptionFocusButton") as? String ?? lblDescriptionFocusButton.stringValue
            btnConnect.title = settingsNew.value(forKey: "buttonConnectFocusButton") as? String ?? btnConnect.title
        }
        if let lateNoMorePopUpVcInfo = configjson.value(forKey: "lateNoMorePopUpVcInfo") as? NSDictionary{
            lblDescriptionLateNoMore.stringValue = lateNoMorePopUpVcInfo.value(forKey: "description") as? String ?? lblDescriptionLateNoMore.stringValue
        }
        // Status line first, so the firmware label can pin BELOW it (both used to pin to the Connect
        // button's bottom and overlapped).
        setupFocusButtonStatusUI()
        setupFirmwareVersionLabel()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshFirmwareVersion),
                                               name: focusButtonService.firmwareVersionDidChange,
                                               object: nil)

        arrForSearchFromSettings.append(["title": lblTitleLateNoMore.stringValue, "tabId": idAddOns, "object": boxGetLateNoMore as Any])
    }

    // MARK: - Focus Button connection status

    private var lblConnectionStatus: NSTextField?

    /// Add a live status line under the Connect button and wire the service callbacks so the user can
    /// see what's happening (which ports are seen, connected/failed) instead of a silent grey button.
    private func setupFocusButtonStatusUI() {
        let status = NSTextField(labelWithString: "")
        status.font = .systemFont(ofSize: 11)
        status.textColor = .secondaryLabelColor
        status.lineBreakMode = .byWordWrapping
        status.maximumNumberOfLines = 0
        status.translatesAutoresizingMaskIntoConstraints = false
        if let container = btnConnect.superview {
            container.addSubview(status)
            NSLayoutConstraint.activate([
                status.topAnchor.constraint(equalTo: btnConnect.bottomAnchor, constant: 8),
                status.leadingAnchor.constraint(equalTo: btnConnect.leadingAnchor),
                status.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -12),
            ])
        }
        lblConnectionStatus = status

        focusButtonServiceObject.onDeviceConnected = { [weak self] path in
            DispatchQueue.main.async {
                self?.setFocusButtonStatus("✓ Connected to \(path.replacingOccurrences(of: "/dev/", with: ""))")
                self?.updateFocusButtonUI()
            }
        }
        focusButtonServiceObject.onError = { [weak self] message in
            DispatchQueue.main.async {
                self?.setFocusButtonStatus("⚠️ \(message)")
                self?.updateFocusButtonUI()
            }
        }
        focusButtonServiceObject.onPortDisconnected = { [weak self] in
            DispatchQueue.main.async {
                self?.setFocusButtonStatus("Disconnected.")
                self?.updateFocusButtonUI()
            }
        }
    }

    private func setFocusButtonStatus(_ text: String) {
        // Some status strings (e.g. "Ports detected: …") get long enough that the wrapping label grows
        // past the bottom of its container. Show at most the first 100 characters (with an ellipsis if
        // truncated) and expose the full text as a hover tooltip.
        let maxLength = 100
        let display = text.count > maxLength ? String(text.prefix(maxLength)) + "…" : text
        lblConnectionStatus?.stringValue = display
        lblConnectionStatus?.toolTip = text
    }

    /// Button reflects the REAL state (never stuck disabled): Connect when idle, Cancel while
    /// attempting, Disconnect once the port is actually open.
    private func updateFocusButtonUI() {
        btnConnect.isEnabled = true
        if focusButtonServiceObject.isConnected {
            btnConnect.title = "Disconnect"
        } else if focusButtonServiceObject.isRunning {
            btnConnect.title = "Cancel"
        } else {
            btnConnect.title = "Connect"
        }
    }
    
    override func viewWillAppear() {
        if FileManager.default.fileExists(atPath: "/Applications/Late No More.app"){
            btnGetLateNoMore.isEnabled = false
            lblLateNoMoreAlreadyInstalled.isHidden = false
        }else{
            btnGetLateNoMore.isEnabled = true
            lblLateNoMoreAlreadyInstalled.isHidden = true
        }

        updateFocusButtonUI()
        if focusButtonServiceObject.isConnected {
            setFocusButtonStatus("✓ Connected.")
        } else {
            setFocusButtonStatus("Ports detected: \(focusButtonServiceObject.availablePortsSummary)")
        }
        refreshFirmwareVersion()
    }

    /// Creates the firmware-version label below the Connect button (hidden until
    /// a device reports its version). Mirrors the Windows settings UI which
    /// shows the installed firmware version.
    private func setupFirmwareVersionLabel() {
        guard lblFirmwareVersion == nil, let parent = btnConnect.superview else { return }
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 11)
        label.textColor = NSColor.secondaryLabelColor
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(label)

        let button = NSButton(title: "Check for Updates", target: self,
                              action: #selector(btnFirmwareUpdateClicked))
        button.bezelStyle = .rounded
        button.controlSize = .small
        button.font = NSFont.systemFont(ofSize: 11)
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(button)

        // A spinner beside the status text, animated while checking / downloading / flashing.
        let spinner = NSProgressIndicator()
        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.isDisplayedWhenStopped = false
        spinner.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(spinner)

        // Pin the firmware label BELOW the connection status line (falls back to the Connect button
        // if the status label isn't set up yet) so the two no longer overlap.
        let firmwareTop = lblConnectionStatus?.bottomAnchor ?? btnConnect.bottomAnchor
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: btnConnect.leadingAnchor),
            label.topAnchor.constraint(equalTo: firmwareTop, constant: 6),
            spinner.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            spinner.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            spinner.widthAnchor.constraint(equalToConstant: 14),
            spinner.heightAnchor.constraint(equalToConstant: 14),
            button.leadingAnchor.constraint(equalTo: btnConnect.leadingAnchor),
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 6)
        ])
        lblFirmwareVersion = label
        btnFirmwareUpdate = button
        firmwareSpinner = spinner
    }

    @objc func refreshFirmwareVersion() {
        guard let label = lblFirmwareVersion else { return }
        // While a flash is in progress the update flow owns this label (Checking / Downloading /
        // Flashing status). The device drops off the bus mid-flash, which posts firmwareVersionDidChange
        // and would otherwise hit the `else` below and HIDE the label — wiping the progress text. Leave
        // it alone until finishFirmwareUpdate() re-syncs the real state.
        if isFlashingFirmware { return }
        let connected = focusButtonServiceObject.isRunning
        if connected, let version = focusButtonServiceObject.firmwareVersion {
            label.stringValue = "Firmware: \(version)"
            label.isHidden = false
            btnFirmwareUpdate?.isHidden = false
            btnFirmwareUpdate?.isEnabled = !isFlashingFirmware
        } else {
            label.isHidden = true
            btnFirmwareUpdate?.isHidden = true
        }
    }

    private func setFirmwareStatus(_ text: String) {
        lblFirmwareVersion?.stringValue = text
        lblFirmwareVersion?.isHidden = false
    }

    @objc func btnFirmwareUpdateClicked() {
        guard !isFlashingFirmware,
              focusButtonServiceObject.isRunning,
              let installed = focusButtonServiceObject.firmwareVersion else { return }
        let (_, installedVersion) = FocusButtonFirmwareUpdater.parse(firmwareVersion: installed)
        isFlashingFirmware = true
        btnFirmwareUpdate?.isEnabled = false
        firmwareSpinner?.startAnimation(nil)
        setFirmwareStatus("Checking for updates…")

        Task { @MainActor in
            let updater = FocusButtonFirmwareUpdater.shared
            do {
                let release = try await updater.fetchLatestRelease()
                let latest = release.version.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
                guard FocusButtonFirmwareUpdater.isNewer(latest, than: installedVersion) else {
                    setFirmwareStatus("Firmware: \(installed)")
                    self.showFirmwareAlert(title: "Up to date",
                                           message: "The Focus Button is running the latest firmware (\(installedVersion)).")
                    self.finishFirmwareUpdate()
                    return
                }
                guard self.confirmFlash(from: installedVersion, to: latest) else {
                    self.finishFirmwareUpdate(); return
                }
                setFirmwareStatus("Downloading firmware \(latest)…")
                let bin = try await updater.downloadFirmwareBin(release: release)

                guard let port = focusButtonServiceObject.connectedPortPath else {
                    throw FocusButtonFirmwareUpdater.UpdaterError.flashFailed("device not connected")
                }
                setFirmwareStatus("Flashing firmware \(latest)…")
                focusButtonServiceObject.stop()                 // release the serial port
                try await Task.sleep(nanoseconds: 600_000_000)  // let the port settle

                try await Task.detached(priority: .userInitiated) {
                    try updater.flash(firmwareBin: bin, port: port)
                }.value

                try? await Task.sleep(nanoseconds: 2_000_000_000) // device re-enumerates
                _ = focusButtonServiceObject.start()            // reconnect (re-reads version)
                setFirmwareStatus("Updated to \(latest).")
                self.showFirmwareAlert(title: "Firmware updated",
                                       message: "The Focus Button was updated to \(latest).")
            } catch FocusButtonFirmwareUpdater.UpdaterError.noReleaseFound {
                // We couldn't read the firmware update info from Cloudflare R2 (e.g. the INI is
                // missing/unreachable). This isn't a flashing failure, and we can't claim the
                // device is up to date either — so tell the user we couldn't check rather than
                // asserting either outcome.
                setFirmwareStatus("Firmware: \(installed)")
                self.showFirmwareAlert(title: "Couldn't check for updates",
                                       message: "Couldn't retrieve the latest firmware information right now. Please try again later.")
            } catch {
                setFirmwareStatus("Firmware: \(installed)")
                self.showFirmwareAlert(title: "Firmware update failed",
                                       message: (error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
            }
            self.finishFirmwareUpdate()
        }
    }

    private func finishFirmwareUpdate() {
        isFlashingFirmware = false
        firmwareSpinner?.stopAnimation(nil)
        refreshFirmwareVersion()
    }

    private func confirmFlash(from: String, to: String) -> Bool {
        let alert = NSAlert()
        alert.setSharingType()
        alert.alertStyle = .informational
        alert.messageText = "Update Focus Button firmware?"
        alert.informativeText = "A new version (\(to)) is available — you have \(from). Flashing reboots the device, installs the firmware and restarts it. Your settings and habits are kept."
        alert.addButton(withTitle: "Flash Firmware")
        alert.addButton(withTitle: buttonCancelText)
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func showFirmwareAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.setSharingType()
        alert.alertStyle = .informational
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        if let window = self.view.window {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    @IBAction func btnGetLateNoMoreClicked(_ sender: Any) {
        if let url = URL(string: "https://www.focusbear.io/late-no-more"){
            NSWorkspace.shared.open(url)
        }
    }

    @IBAction func btnBackClicked(_ sender: Any) {
        settingsContainerVcObj?.showAdvancedView()
    }
    
    @IBAction func btnConnectClicked(_ sender: Any) {
        addLog(text: "addOnsVc: button Connect Clicked")
        // Already connected (or mid-attempt) → this button doubles as Disconnect / Cancel.
        if focusButtonServiceObject.isConnected || focusButtonServiceObject.isRunning {
            focusButtonServiceObject.stop()
            setFocusButtonStatus("Disconnected.")
            updateFocusButtonUI()
            return
        }
        setFocusButtonStatus("Connecting…\nPorts detected: \(focusButtonServiceObject.availablePortsSummary)")
        if !focusButtonServiceObject.start() {
            // start() returns false only when no candidate port was found.
            setFocusButtonStatus("No Focus Button device found.\nPorts detected: \(focusButtonServiceObject.availablePortsSummary)\nPlug the device in via USB and click Connect again.")
        }
        updateFocusButtonUI()
        // If the open neither succeeds nor errors within a few seconds, say so (rather than spinning).
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            guard let self = self else { return }
            if focusButtonServiceObject.isRunning && !focusButtonServiceObject.isConnected {
                self.setFocusButtonStatus("Still connecting to \(focusButtonServiceObject.availablePortsSummary)…\nIf this doesn't finish, the device may be held by another app or need re-plugging. Click Cancel to retry.")
            }
            self.updateFocusButtonUI()
        }
    }
}


