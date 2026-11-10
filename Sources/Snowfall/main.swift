import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

// If another copy is already running (for example the one in /Applications),
// ask it to show its controls and exit instead of stacking up duplicate snow.
if let bundleIdentifier = Bundle.main.bundleIdentifier {
    let otherCopies = NSRunningApplication
        .runningApplications(withBundleIdentifier: bundleIdentifier)
        .filter { $0.processIdentifier != getpid() }

    if let existing = otherCopies.first {
        DistributedNotificationCenter.default().postNotificationName(
            .snowfallShowControls,
            object: nil,
            deliverImmediately: true
        )
        existing.activate(options: [.activateIgnoringOtherApps])
        exit(0)
    }
}

let delegate = AppDelegate()
app.delegate = delegate
app.run()
