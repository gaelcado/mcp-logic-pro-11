import AppKit
import ApplicationServices
import Foundation

struct LogicVersion: Equatable {
    let raw: String
    let major: Int
    let minor: Int
    let patch: Int

    init?(_ raw: String) {
        let pieces = raw.split(separator: ".", omittingEmptySubsequences: false)
        guard (2...3).contains(pieces.count),
              let major = Int(pieces[0]), let minor = Int(pieces[1]),
              major >= 0, minor >= 0 else { return nil }
        let patch = pieces.count == 3 ? Int(pieces[2]) : 0
        guard let patch, patch >= 0 else { return nil }
        self.raw = raw
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    var profile: String? {
        guard major == 11, minor == 1 || minor == 2 else { return nil }
        return "11.\(minor)"
    }
}

struct ProbeResult {
    let status: String
    let version: String?
    let profile: String?
    let accessibilityGranted: Bool
    let windowCount: Int?
    let note: String

    var dictionary: [String: Any] {
        ["status": status,
         "logicVersion": version as Any? ?? NSNull(),
         "profile": profile as Any? ?? NSNull(),
         "accessibilityGranted": accessibilityGranted,
         "windowCount": windowCount as Any? ?? NSNull(),
         "verification": "unqualified_without_logic_pilots",
         "note": note]
    }
}

enum LogicProbe {
    static let bundleID = "com.apple.logic10"

    static func inspect() -> ProbeResult {
        let trusted = AXIsProcessTrusted()
        let matches = NSWorkspace.shared.runningApplications.filter { $0.bundleIdentifier == bundleID && !$0.isTerminated }
        guard matches.count == 1, let app = matches.first else {
            let status = matches.isEmpty ? "logic_not_running" : "ambiguous_logic_processes"
            return ProbeResult(status: status, version: nil, profile: nil,
                               accessibilityGranted: trusted, windowCount: nil,
                               note: matches.isEmpty ? "Ouvrez Logic Pro puis réessayez." : "Plusieurs processus Logic correspondent ; aucune action n'est autorisée.")
        }
        guard let url = app.bundleURL, let bundle = Bundle(url: url), bundle.bundleIdentifier == bundleID,
              let raw = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              let parsed = LogicVersion(raw) else {
            return ProbeResult(status: "version_unreadable", version: nil, profile: nil,
                               accessibilityGranted: trusted, windowCount: nil,
                               note: "La version du paquet Logic n'est pas lisible ; aucune action n'est autorisée.")
        }
        let count: Int?
        if trusted {
            let element = AXUIElementCreateApplication(app.processIdentifier)
            var value: CFTypeRef?
            let code = AXUIElementCopyAttributeValue(element, kAXWindowsAttribute as CFString, &value)
            count = code == .success ? (value as? [Any])?.count : nil
        } else {
            count = nil
        }
        let profile = parsed.profile
        return ProbeResult(status: profile == nil ? "unsupported_logic_version" : "detected",
                           version: raw, profile: profile, accessibilityGranted: trusted,
                           windowCount: count,
                           note: profile == nil ? "Seules les versions 11.1 et 11.2 sont ciblées." :
                            "Profil choisi automatiquement. Les actions Logic restent à qualifier sur les deux versions.")
    }
}
