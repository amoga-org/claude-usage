import Cocoa
import SwiftUI

// MARK: - Metric Type Enum

enum MetricType: String, CaseIterable {
    case fiveHour = "5-hour Limit"
    case sevenDay = "7-day Limit (All Models)"
    case sevenDaySonnet = "7-day Limit (Sonnet)"

    var displayName: String { rawValue }
}

// MARK: - Preferences Manager

class Preferences {
    static let shared = Preferences()
    private let defaults = UserDefaults.standard

    private let sessionKeyKey = "claudeSessionKey"
    private let metricTypeKey = "selectedMetricType"

    var sessionKey: String? {
        get { defaults.string(forKey: sessionKeyKey) }
        set { defaults.set(newValue, forKey: sessionKeyKey) }
    }

    var selectedMetric: MetricType {
        get {
            if let rawValue = defaults.string(forKey: metricTypeKey),
               let metric = MetricType(rawValue: rawValue) {
                return metric
            }
            return .sevenDay
        }
        set {
            defaults.set(newValue.rawValue, forKey: metricTypeKey)
        }
    }
}

// MARK: - Settings Window Controller

class SettingsWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 350),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.center()

        self.init(window: window)

        let settingsView = SettingsView { [weak self] in
            self?.close()
        }
        let hostingView = NSHostingView(rootView: settingsView)
        window.contentView = hostingView
    }
}

struct SettingsView: View {
    let onClose: () -> Void

    @State private var sessionKey: String = Preferences.shared.sessionKey ?? ""
    @State private var selectedMetric: MetricType = Preferences.shared.selectedMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Claude Usage Settings")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Session Key:")
                    .font(.headline)

                TextField("Enter your Claude session key", text: $sessionKey)
                    .textFieldStyle(.roundedBorder)

                Text("Find this in your browser's cookies at claude.ai")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Display Metric:")
                    .font(.headline)

                Picker("", selection: $selectedMetric) {
                    ForEach(MetricType.allCases, id: \.self) { metric in
                        Text(metric.displayName).tag(metric)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Save") {
                    Preferences.shared.sessionKey = sessionKey
                    Preferences.shared.selectedMetric = selectedMetric

                    NotificationCenter.default.post(name: .settingsChanged, object: nil)

                    onClose()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 450, height: 350)
    }
}

extension Notification.Name {
    static let settingsChanged = Notification.Name("settingsChanged")
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var menu: NSMenu!
    var usageData: UsageResponse?
    var timer: Timer?
    var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "⏱️"
            button.action = #selector(showMenu)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        menu = NSMenu()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChanged),
            name: .settingsChanged,
            object: nil
        )

        fetchUsageData()

        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.fetchUsageData()
        }
    }

    @objc func handleSettingsChanged() {
        fetchUsageData()
    }

    @objc func showMenu() {
        menu.removeAllItems()

        let currentMetric = Preferences.shared.selectedMetric

        if let data = usageData {
            // 5-hour limit
            if let fiveHour = data.five_hour {
                let item = NSMenuItem(
                    title: "\(formatUtilization(fiveHour.utilization))% 5-hour Limit",
                    action: currentMetric == .fiveHour ? nil : #selector(switchToFiveHour),
                    keyEquivalent: ""
                )
                if currentMetric == .fiveHour {
                    item.state = .on
                }
                menu.addItem(item)
                menu.addItem(NSMenuItem(title: "  Resets \(formatRelativeDate(fiveHour.resets_at))", action: nil, keyEquivalent: ""))
                menu.addItem(NSMenuItem.separator())
            }

            // 7-day limit (all models)
            if let sevenDay = data.seven_day {
                let item = NSMenuItem(
                    title: "\(formatUtilization(sevenDay.utilization))% 7-day Limit (All Models)",
                    action: currentMetric == .sevenDay ? nil : #selector(switchToSevenDay),
                    keyEquivalent: ""
                )
                if currentMetric == .sevenDay {
                    item.state = .on
                }
                menu.addItem(item)
                menu.addItem(NSMenuItem(title: "  Resets \(formatRelativeDate(sevenDay.resets_at))", action: nil, keyEquivalent: ""))
                menu.addItem(NSMenuItem.separator())
            }

            // 7-day Sonnet
            if let sevenDaySonnet = data.seven_day_sonnet {
                let item = NSMenuItem(
                    title: "\(formatUtilization(sevenDaySonnet.utilization))% 7-day Limit (Sonnet)",
                    action: currentMetric == .sevenDaySonnet ? nil : #selector(switchToSevenDaySonnet),
                    keyEquivalent: ""
                )
                if currentMetric == .sevenDaySonnet {
                    item.state = .on
                }
                menu.addItem(item)
                menu.addItem(NSMenuItem(title: "  Resets \(formatRelativeDate(sevenDaySonnet.resets_at))", action: nil, keyEquivalent: ""))
                menu.addItem(NSMenuItem.separator())
            }

            // 7-day Opus (if available)
            if let sevenDayOpus = data.seven_day_opus {
                menu.addItem(NSMenuItem(title: "\(formatUtilization(sevenDayOpus.utilization))% 7-day Limit (Opus)", action: nil, keyEquivalent: ""))
                menu.addItem(NSMenuItem(title: "  Resets \(formatRelativeDate(sevenDayOpus.resets_at))", action: nil, keyEquivalent: ""))
                menu.addItem(NSMenuItem.separator())
            }
        } else {
            menu.addItem(NSMenuItem(title: "Loading...", action: nil, keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
        }

        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(refreshClicked), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitClicked), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc func switchToFiveHour() {
        Preferences.shared.selectedMetric = .fiveHour
        updateMenuBarIcon()
    }

    @objc func switchToSevenDay() {
        Preferences.shared.selectedMetric = .sevenDay
        updateMenuBarIcon()
    }

    @objc func switchToSevenDaySonnet() {
        Preferences.shared.selectedMetric = .sevenDaySonnet
        updateMenuBarIcon()
    }

    @objc func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
    }

    @objc func refreshClicked() {
        fetchUsageData()
    }

    @objc func quitClicked() {
        NSApplication.shared.terminate(self)
    }

    func fetchUsageData() {
        var sessionKey = Preferences.shared.sessionKey

        if sessionKey == nil || sessionKey?.isEmpty == true {
            sessionKey = ProcessInfo.processInfo.environment["CLAUDE_SESSION_KEY"]
        }

        guard let sessionKey = sessionKey, !sessionKey.isEmpty else {
            print("Error: No session key found. Please set it in Settings or CLAUDE_SESSION_KEY environment variable")
            DispatchQueue.main.async {
                self.statusItem.button?.title = "❌"
            }
            return
        }

        let urlString = "https://claude.ai/api/organizations/e90506cb-c14f-428f-89d7-1ee0f2d68447/usage"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("sessionKey=\(sessionKey)", forHTTPHeaderField: "Cookie")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            do {
                let decoder = JSONDecoder()
                let usageData = try decoder.decode(UsageResponse.self, from: data)

                DispatchQueue.main.async {
                    self?.usageData = usageData
                    self?.updateMenuBarIcon()
                }
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }

        task.resume()
    }

    func getSelectedMetricData(from data: UsageResponse, metric: MetricType) -> (Double, String, String)? {
        switch metric {
        case .fiveHour:
            guard let limit = data.five_hour else { return nil }
            return (limit.utilization, limit.resets_at, "5-hour Limit")
        case .sevenDay:
            guard let limit = data.seven_day else { return nil }
            return (limit.utilization, limit.resets_at, "7-day Limit")
        case .sevenDaySonnet:
            guard let limit = data.seven_day_sonnet else { return nil }
            return (limit.utilization, limit.resets_at, "7-day Sonnet")
        }
    }

    func updateMenuBarIcon() {
        guard let data = usageData,
              let button = statusItem.button else { return }

        let metric = Preferences.shared.selectedMetric

        guard let (utilization, resetDateString, _) = getSelectedMetricData(from: data, metric: metric) else {
            button.title = "❌"
            return
        }

        // Parse reset date
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let resetDate = formatter.date(from: resetDateString) else {
            // Fallback to old logic if date parsing fails
            let icon = getIconForUtilization(utilization)
            button.title = "\(icon) \(formatUtilization(utilization))%"
            return
        }

        // Calculate window duration based on metric type
        let windowDuration: TimeInterval
        switch metric {
        case .fiveHour:
            windowDuration = 5 * 3600 // 5 hours in seconds
        case .sevenDay, .sevenDaySonnet:
            windowDuration = 7 * 24 * 3600 // 7 days in seconds
        }

        let now = Date()
        let timeRemaining = resetDate.timeIntervalSince(now)

        // If time is invalid, use old logic
        guard timeRemaining > 0 && timeRemaining <= windowDuration else {
            let icon = getIconForUtilization(utilization)
            button.title = "\(icon) \(formatUtilization(utilization))%"
            return
        }

        // Calculate expected consumption based on time elapsed
        let timeElapsed = windowDuration - timeRemaining
        let expectedConsumption = (timeElapsed / windowDuration) * 100.0

        // Compare actual vs expected consumption
        let icon: String
        if utilization < expectedConsumption {
            // Below expected - on track or better
            icon = "✅"
        } else if utilization <= expectedConsumption + 10 {
            // Within 10% over expected - slightly over pace
            icon = "⚠️"
        } else {
            // More than 10% over expected - significantly over pace
            icon = "🚨"
        }

        button.title = "\(icon) \(formatUtilization(utilization))%"
    }

    func getIconForUtilization(_ utilization: Double) -> String {
        if utilization >= 80 {
            return "🚨"
        } else if utilization >= 50 {
            return "⚠️"
        } else {
            return "✅"
        }
    }

    func formatUtilization(_ value: Double) -> String {
        return String(format: "%.0f", value)
    }

    func formatRelativeDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let now = Date()
        let interval = date.timeIntervalSince(now)

        if interval < 0 {
            return "soon"
        }

        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 24 {
            let days = hours / 24
            return "in \(days) day\(days == 1 ? "" : "s")"
        } else if hours > 0 {
            if minutes > 0 {
                return "in \(hours)h \(minutes)m"
            } else {
                return "in \(hours) hour\(hours == 1 ? "" : "s")"
            }
        } else if minutes > 0 {
            return "in \(minutes) min\(minutes == 1 ? "" : "s")"
        } else {
            return "in < 1 min"
        }
    }
}

// MARK: - Data Models

struct UsageResponse: Codable {
    let five_hour: UsageLimit?
    let seven_day: UsageLimit?
    let seven_day_oauth_apps: UsageLimit?
    let seven_day_opus: UsageLimit?
    let seven_day_sonnet: UsageLimit?
    let iguana_necktie: UsageLimit?
    let extra_usage: UsageLimit?
}

struct UsageLimit: Codable {
    let utilization: Double
    let resets_at: String
}

// MARK: - Main Entry Point

@main
struct ClaudeUsageApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
