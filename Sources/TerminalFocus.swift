import AppKit
import Darwin

enum TerminalFocus {
    /// Walk up the process tree from the session's claude PID and activate the
    /// first regular GUI app found (the terminal/IDE hosting that session).
    /// Returns the app's name on success.
    @discardableResult
    static func focusApp(forSessionPID pid: Int32) -> String? {
        var current = pid
        for _ in 0..<15 {
            guard let parent = parentPID(of: current), parent > 1 else { return nil }
            if let app = NSRunningApplication(processIdentifier: parent),
               app.activationPolicy == .regular {
                if #available(macOS 14.0, *) {
                    NSApp.yieldActivation(to: app)
                    app.activate()
                } else {
                    app.activate(options: [.activateIgnoringOtherApps])
                }
                return app.localizedName ?? "app"
            }
            current = parent
        }
        return nil
    }

    static func parentPID(of pid: Int32) -> Int32? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        let ok = mib.withUnsafeMutableBufferPointer { mibPtr -> Bool in
            sysctl(mibPtr.baseAddress, 4, &info, &size, nil, 0) == 0
        }
        guard ok, size > 0 else { return nil }
        return info.kp_eproc.e_ppid
    }
}
