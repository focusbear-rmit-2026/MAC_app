//
//  debugLogsVc.swift
//  Focus Bear
//
//  Created by Devin AI on 12/02/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

struct AIBlockingLogEntry: Codable {
    let timestamp: Date
    let urlOrApp: String
    let isApp: Bool
    let focusMode: String
    let intention: String
    let tabTitle: String
    let currentTask: String
    let score: Double
    let reason: String
    let payload: [String: Any]?

    // `payload` is a raw [String: Any] API body, not natively Codable — persist it as JSON Data so the
    // whole entry survives an app restart (see load/persist below), and decode it back on load.
    private enum CodingKeys: String, CodingKey {
        case timestamp, urlOrApp, isApp, focusMode, intention, tabTitle, currentTask, score, reason, payloadData
    }

    init(timestamp: Date, urlOrApp: String, isApp: Bool, focusMode: String, intention: String,
         tabTitle: String, currentTask: String, score: Double, reason: String, payload: [String: Any]?) {
        self.timestamp = timestamp; self.urlOrApp = urlOrApp; self.isApp = isApp; self.focusMode = focusMode
        self.intention = intention; self.tabTitle = tabTitle; self.currentTask = currentTask
        self.score = score; self.reason = reason; self.payload = payload
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try c.decode(Date.self, forKey: .timestamp)
        urlOrApp = try c.decode(String.self, forKey: .urlOrApp)
        isApp = try c.decode(Bool.self, forKey: .isApp)
        focusMode = try c.decode(String.self, forKey: .focusMode)
        intention = try c.decode(String.self, forKey: .intention)
        tabTitle = try c.decode(String.self, forKey: .tabTitle)
        currentTask = try c.decode(String.self, forKey: .currentTask)
        score = try c.decode(Double.self, forKey: .score)
        reason = try c.decode(String.self, forKey: .reason)
        if let data = try c.decodeIfPresent(Data.self, forKey: .payloadData) {
            payload = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        } else { payload = nil }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(timestamp, forKey: .timestamp)
        try c.encode(urlOrApp, forKey: .urlOrApp)
        try c.encode(isApp, forKey: .isApp)
        try c.encode(focusMode, forKey: .focusMode)
        try c.encode(intention, forKey: .intention)
        try c.encode(tabTitle, forKey: .tabTitle)
        try c.encode(currentTask, forKey: .currentTask)
        try c.encode(score, forKey: .score)
        try c.encode(reason, forKey: .reason)
        if let payload = payload,
           let data = try? JSONSerialization.data(withJSONObject: payload) {
            try c.encode(data, forKey: .payloadData)
        }
    }
}

let maxAIBlockingLogEntries = 50
private let aiBlockingLogQueue = DispatchQueue(label: "com.focusbear.aiBlockingLog")
var arrAIBlockingLogEntries = [AIBlockingLogEntry]()

private let aiBlockingLogDefaultsKey = "aiBlockingLogEntries"
private var didLoadPersistedAiBlockingLog = false

/// Hydrate the in-memory log from disk once per launch — the store used to be memory-only, so it was
/// wiped on every restart (and the app restarts often: habit edits, Pusher). MUST be called on
/// `aiBlockingLogQueue`.
private func loadPersistedAiBlockingLogIfNeeded() {
    guard !didLoadPersistedAiBlockingLog else { return }
    didLoadPersistedAiBlockingLog = true
    if let data = UserDefaults.standard.data(forKey: aiBlockingLogDefaultsKey),
       let entries = try? JSONDecoder().decode([AIBlockingLogEntry].self, from: data) {
        arrAIBlockingLogEntries = entries
    }
}

/// Persist the (trimmed) log so it survives a restart. MUST be called on `aiBlockingLogQueue`.
private func persistAiBlockingLog() {
    if let data = try? JSONEncoder().encode(arrAIBlockingLogEntries) {
        UserDefaults.standard.set(data, forKey: aiBlockingLogDefaultsKey)
    }
}

/// Run a read/write against the log store on its serial queue, hydrating from disk first.
func withAiBlockingLog<T>(_ body: () -> T) -> T {
    aiBlockingLogQueue.sync {
        loadPersistedAiBlockingLogIfNeeded()
        return body()
    }
}

func addAIBlockingLogEntry(urlOrApp: String, isApp: Bool, focusMode: String, intention: String, tabTitle: String, currentTask: String, score: Double, reason: String, payload: [String: Any]?) {
    let entry = AIBlockingLogEntry(
        timestamp: Date(),
        urlOrApp: urlOrApp,
        isApp: isApp,
        focusMode: focusMode,
        intention: intention,
        tabTitle: tabTitle,
        currentTask: currentTask,
        score: score,
        reason: reason,
        payload: payload
    )
    aiBlockingLogQueue.async {
        loadPersistedAiBlockingLogIfNeeded()
        arrAIBlockingLogEntries.append(entry)
        if arrAIBlockingLogEntries.count > maxAIBlockingLogEntries {
            arrAIBlockingLogEntries.removeFirst(arrAIBlockingLogEntries.count - maxAIBlockingLogEntries)
        }
        persistAiBlockingLog()
    }
}

class DebugLogsVc: NSViewController {

    // MARK: - Score Thresholds
    private enum ScoreThreshold {
        static let high: Double = 0.70      // Green - allowed
        static let medium: Double = 0.50    // Orange - borderline
        // Below 0.50 = Red - blocked
    }

    // MARK: - Static DateFormatter
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    var scrollView: NSScrollView!
    var tblView: NSTableView!
    var lblNoLogs: NSTextField!
    var lblSectionTitle: NSTextField!

    var entryApp = "App"
    var entryUrl = "URL"
    var inputFocus = "Focus:"
    var inputIntention = "Intention:"
    var inputTask = "Task:"
    var buttonBadAiToolTip = "Report bad AI decision"
    
    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        tblView.reloadData()
        updateNoLogsVisibility()
    }

    func setupUI() {
        var title = "AI Blocking Logs"
        var columnType = "Type"
        var columnUrlApp = "URL / App"
        var columnInput = "Input Parameters"
        var columnScore = "Score"
        var columnReason = "Reason"
        var noLogsYet = "No AI blocking logs yet. Logs will appear here when AI evaluates URLs or apps during a focus session."
        
        
        
        if let debugLogsVcInfo = configjson.value(forKey: "debugLogsVcInfo") as? NSDictionary{
            title = debugLogsVcInfo.value(forKey: "title") as? String ?? title
            columnType = debugLogsVcInfo.value(forKey: "columnType") as? String ?? columnType
            columnUrlApp = debugLogsVcInfo.value(forKey: "columnUrlApp") as? String ?? columnUrlApp
            columnInput = debugLogsVcInfo.value(forKey: "columnInput") as? String ?? columnInput
            columnScore = debugLogsVcInfo.value(forKey: "columnScore") as? String ?? columnScore
            columnReason = debugLogsVcInfo.value(forKey: "columnReason") as? String ?? columnReason
            noLogsYet = debugLogsVcInfo.value(forKey: "noLogsYet") as? String ?? noLogsYet
            entryApp = debugLogsVcInfo.value(forKey: "entryApp") as? String ?? entryApp
            entryUrl = debugLogsVcInfo.value(forKey: "entryUrl") as? String ?? entryUrl
            inputFocus = debugLogsVcInfo.value(forKey: "inputFocus") as? String ?? inputFocus
            inputIntention = debugLogsVcInfo.value(forKey: "inputIntention") as? String ?? inputIntention
            inputTask = debugLogsVcInfo.value(forKey: "inputTask") as? String ?? inputTask
            buttonBadAiToolTip = debugLogsVcInfo.value(forKey: "buttonBadAiToolTip") as? String ?? buttonBadAiToolTip
        }
        
        
        lblSectionTitle = NSTextField(labelWithString: title)
        lblSectionTitle.font = NSFont.boldSystemFont(ofSize: 16)
        lblSectionTitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lblSectionTitle)

        scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.horizontalScrollElasticity = .automatic
        scrollView.verticalScrollElasticity = .automatic
        
        scrollView.borderType = .bezelBorder
        view.addSubview(scrollView)

        tblView = NSTableView()
        tblView.delegate = self
        tblView.dataSource = self
        tblView.usesAlternatingRowBackgroundColors = true
        tblView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        tblView.rowHeight = 80

        let colType = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("type"))
        colType.title = columnType
        colType.width = 50
        colType.minWidth = 40
        tblView.addTableColumn(colType)

        let colUrlApp = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("urlApp"))
        colUrlApp.title = columnUrlApp
        colUrlApp.width = 180
        colUrlApp.minWidth = 100
        tblView.addTableColumn(colUrlApp)

        let colInput = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("input"))
        colInput.title = columnInput
        colInput.width = 200
        colInput.minWidth = 120
        tblView.addTableColumn(colInput)

        let colScore = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("score"))
        colScore.title = columnScore
        colScore.width = 60
        colScore.minWidth = 50
        tblView.addTableColumn(colScore)

        let colReason = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("reason"))
        colReason.title = columnReason
        colReason.width = 200
        colReason.minWidth = 100
        tblView.addTableColumn(colReason)

        let colAction = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("action"))
        colAction.title = ""
        colAction.width = 40
        colAction.minWidth = 40
        colAction.maxWidth = 40
        tblView.addTableColumn(colAction)

        scrollView.documentView = tblView

        lblNoLogs = NSTextField(labelWithString: noLogsYet)
        lblNoLogs.translatesAutoresizingMaskIntoConstraints = false
        lblNoLogs.alignment = .center
        lblNoLogs.textColor = .secondaryLabelColor
        lblNoLogs.lineBreakMode = .byWordWrapping
        lblNoLogs.maximumNumberOfLines = 0
        lblNoLogs.preferredMaxLayoutWidth = 400
        view.addSubview(lblNoLogs)

        NSLayoutConstraint.activate([
            lblSectionTitle.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            lblSectionTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            lblSectionTitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            scrollView.topAnchor.constraint(equalTo: lblSectionTitle.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),

            lblNoLogs.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            lblNoLogs.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
        ])

        updateNoLogsVisibility()
    }

    func updateNoLogsVisibility() {
        let hasEntries = withAiBlockingLog { !arrAIBlockingLogEntries.isEmpty }
        lblNoLogs.isHidden = hasEntries
        scrollView.isHidden = !hasEntries
    }

    func formatTimestamp(_ date: Date) -> String {
        return Self.timeFormatter.string(from: date)
    }

    @objc func btnReportBadDecisionClicked(_ sender: NSButton) {
        let row = sender.tag
        let entry: AIBlockingLogEntry? = withAiBlockingLog {
            guard row >= 0 && row < arrAIBlockingLogEntries.count else { return nil }
            return arrAIBlockingLogEntries[row]
        }
        if let entry = entry {
            if entry.isApp {
                showReportBadAIResponseWindow(url: nil, app: entry.urlOrApp, payload: entry.payload)
            } else {
                showReportBadAIResponseWindow(url: entry.urlOrApp, app: nil, payload: entry.payload)
            }
        }
    }
}

extension DebugLogsVc: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return withAiBlockingLog { arrAIBlockingLogEntries.count }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let entries = withAiBlockingLog { arrAIBlockingLogEntries }
        let entry = entries[entries.count - 1 - row]
        let identifier = tableColumn?.identifier.rawValue ?? ""
        
        switch identifier {
        case "type":
            let cellIdentifier = NSUserInterfaceItemIdentifier("TypeCell")
            
            var container = tableView.makeView(withIdentifier: cellIdentifier, owner: self)
            
            if container == nil {
                let textField = NSTextField(labelWithString: "")
                textField.font = NSFont.systemFont(ofSize: 12)
                textField.lineBreakMode = .byTruncatingTail
                
                container = wrapWithTopPadding(
                    textField,
                    identifier: cellIdentifier
                )
            }
            
            if let textField = container?.subviews.first as? NSTextField {
                textField.stringValue = entry.isApp ? entryApp : entryUrl
            }
            
            return container
            
        case "urlApp":
            let cellIdentifier = NSUserInterfaceItemIdentifier("UrlAppCell")
            
            var container = tableView.makeView(withIdentifier: cellIdentifier, owner: self)
            
            if container == nil {
                
                let stack = NSStackView()
                stack.orientation = .vertical
                stack.alignment = .leading
                stack.spacing = 2
                
                let lblTime = NSTextField(labelWithString: "")
                lblTime.font = NSFont.systemFont(ofSize: 10)
                lblTime.textColor = .secondaryLabelColor
                
                let lblUrl = NSTextField(labelWithString: "")
                lblUrl.font = NSFont.systemFont(ofSize: 12, weight: .medium)
                
                let lblTab = NSTextField(labelWithString: "")
                lblTab.font = NSFont.systemFont(ofSize: 10)
                lblTab.textColor = .secondaryLabelColor
                
                stack.addArrangedSubview(lblTime)
                stack.addArrangedSubview(lblUrl)
                stack.addArrangedSubview(lblTab)
                
                container = wrapWithTopPadding(
                    stack,
                    identifier: cellIdentifier
                )
            }
            
            if let stack = container?.subviews.first as? NSStackView,
               let labels = stack.arrangedSubviews as? [NSTextField],
               labels.count >= 3 {
                
                labels[0].stringValue = formatTimestamp(entry.timestamp)
                labels[1].stringValue = entry.urlOrApp
                labels[2].stringValue = entry.tabTitle
                labels[2].isHidden = entry.tabTitle.isEmpty
            }
            
            return container
            
        case "input":
            let cellIdentifier = NSUserInterfaceItemIdentifier("InputCell")
            
            var container = tableView.makeView(withIdentifier: cellIdentifier, owner: self)
            
            if container == nil {
                
                let textField = NSTextField(labelWithString: "")
                textField.font = NSFont.systemFont(ofSize: 11)
                textField.maximumNumberOfLines = 3
                
                container = wrapWithTopPadding(
                    textField,
                    identifier: cellIdentifier
                )
            }
            
            if let textField = container?.subviews.first as? NSTextField {
                
                var inputLines = [String]()
                
                if !entry.focusMode.isEmpty {
                    inputLines.append("\(inputFocus) \(entry.focusMode)")
                }
                
                if !entry.intention.isEmpty {
                    inputLines.append("\(inputIntention) \(entry.intention)")
                }
                
                if !entry.currentTask.isEmpty {
                    inputLines.append("\(inputTask) \(entry.currentTask)")
                }
                
                textField.stringValue = inputLines.joined(separator: "\n")
            }
            
            return container
            
        case "score":
            let cellIdentifier = NSUserInterfaceItemIdentifier("ScoreCell")
            
            var container = tableView.makeView(withIdentifier: cellIdentifier, owner: self)
            
            if container == nil {
                
                let textField = NSTextField(labelWithString: "")
                textField.font = NSFont.monospacedDigitSystemFont(
                    ofSize: 13,
                    weight: .semibold
                )
                textField.alignment = .left
                
                container = wrapWithTopPadding(
                    textField,
                    identifier: cellIdentifier,
                    top: 10,
                    leading: 2
                )
            }
            
            if let textField = container?.subviews.first as? NSTextField {
                
                let scorePercent = Int(entry.score * 100)
                textField.stringValue = "\(scorePercent)%"
                
                if entry.score >= ScoreThreshold.high {
                    textField.textColor = .systemGreen
                }
                else if entry.score >= ScoreThreshold.medium {
                    textField.textColor = .systemOrange
                }
                else {
                    textField.textColor = .systemRed
                }
            }
            
            return container
            
        case "reason":
            let cellIdentifier = NSUserInterfaceItemIdentifier("ReasonCell")
            
            var container = tableView.makeView(withIdentifier: cellIdentifier, owner: self)
            
            if container == nil {
                
                let textField = NSTextField(labelWithString: "")
                textField.font = NSFont.systemFont(ofSize: 11)
                textField.lineBreakMode = .byWordWrapping
                textField.maximumNumberOfLines = 3
                textField.cell?.truncatesLastVisibleLine = true
                container = wrapWithPadding(
                    textField,
                    identifier: cellIdentifier,
                    top: 10,
                    leading: 2,
                    trailing: 2,
                    bottom: 2
                )
            }
            
            if let textField = container?.subviews.first as? NSTextField {
                textField.stringValue = entry.reason
                textField.toolTip = entry.reason
            }
            
            return container
            
        case "action":
            let cellIdentifier = NSUserInterfaceItemIdentifier("ActionCell")
            
            var container = tableView.makeView(withIdentifier: cellIdentifier, owner: self)
            
            if container == nil {
                
                let btn = cursorButton(
                    title: "\u{1F44E}",
                    target: self,
                    action: #selector(btnReportBadDecisionClicked(_:))
                )
                
                btn.toolTip = buttonBadAiToolTip
                btn.bezelStyle = .inline
                btn.isBordered = false
                btn.font = NSFont.systemFont(ofSize: 16)
                
                container = wrapWithTopPadding(
                    btn,
                    identifier: cellIdentifier,
                    leading: 4
                )
            }
            
            if let btn = container?.subviews.first as? NSButton {
                btn.tag = entries.count - 1 - row
            }
            
            return container
            
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 70
    }
    
    func wrapWithTopPadding(_ content: NSView,
                            identifier: NSUserInterfaceItemIdentifier,
                            top: CGFloat = 10,
                            leading: CGFloat = 0,
                            trailing: CGFloat = 0) -> NSView {
        
        let container = NSView()
        container.identifier = identifier
        
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: container.topAnchor, constant: top),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: leading),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -trailing)
        ])
        
        return container
    }
    
    func wrapWithPadding(_ content: NSView,
                            identifier: NSUserInterfaceItemIdentifier,
                            top: CGFloat = 10,
                            leading: CGFloat = 0,
                            trailing: CGFloat = 0,
                            bottom: CGFloat = 0) -> NSView {
        
        let container = NSView()
        container.identifier = identifier
        
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: container.topAnchor, constant: top),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: leading),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -trailing),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -bottom)
        ])
        
        return container
    }
}

