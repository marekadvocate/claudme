import CoreAudio
import Foundation

/// Is anything on this Mac making noise right now?
///
/// Reads `kAudioDevicePropertyDeviceIsRunningSomewhere` on the default output device.
/// That flag is true whenever *any* process has the output running, so it catches
/// Spotify, YouTube, a game — anything. It is a plain public CoreAudio property, so
/// this needs no microphone permission and never touches the audio itself.
final class AudioSense {
    /// Fired on the main thread whenever playback starts or stops.
    var onChange: ((Bool) -> Void)?
    private(set) var isPlaying = false

    private let queue = DispatchQueue(label: "claudme.audio", qos: .utility)
    private var timer: DispatchSourceTimer?

    func start() {
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + 1, repeating: 1.5)
        t.setEventHandler { [weak self] in self?.poll() }
        t.resume()
        timer = t
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func poll() {
        let playing = Self.defaultOutputDevice().map(Self.isRunning) ?? false
        guard playing != isPlaying else { return }
        isPlaying = playing
        DispatchQueue.main.async { [weak self] in self?.onChange?(playing) }
    }

    private static func defaultOutputDevice() -> AudioDeviceID? {
        var device = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device)
        return status == noErr && device != kAudioObjectUnknown ? device : nil
    }

    private static func isRunning(_ device: AudioDeviceID) -> Bool {
        var running: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &running)
        return status == noErr && running != 0
    }
}
