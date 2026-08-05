import AppKit

let cliArgs = CommandLine.arguments

if cliArgs.contains("--install-hooks") {
    do {
        try HooksInstaller.install()
        print("Claudme hooks installed into ~/.claude/settings.json")
        print("Backup: ~/.claude/settings.json.bak-claudme")
        print("Note: already-running Claude sessions need a restart to pick them up.")
    } catch {
        FileHandle.standardError.write(Data("Install failed: \(error)\n".utf8))
        exit(1)
    }
    exit(0)
}

if cliArgs.contains("--remove-hooks") {
    do {
        try HooksInstaller.remove()
        print("Claudme hooks removed from ~/.claude/settings.json")
    } catch {
        FileHandle.standardError.write(Data("Remove failed: \(error)\n".utf8))
        exit(1)
    }
    exit(0)
}

let app = NSApplication.shared
let appDelegate = AppDelegate()
app.delegate = appDelegate
app.setActivationPolicy(.accessory)
app.run()
