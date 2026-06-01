import Foundation

enum BroadcastAudioInput {
    static func inputArguments(settings: BroadcastSettings) -> [String] {
        switch settings.audioMode {
        case .silent:
            return [
                "-f", "lavfi",
                "-i", "anullsrc=channel_layout=stereo:sample_rate=\(settings.target.recommendedAudioSampleRate)"
            ]
        case .desktopStereoMix:
            return [
                "-thread_queue_size", "1024",
                "-f", "avfoundation",
                "-i", ":\(escapedDeviceName(settings.audioDeviceName))"
            ]
        }
    }

    static func previewName(settings: BroadcastSettings) -> String {
        switch settings.audioMode {
        case .silent:
            return "silent stereo source"
        case .desktopStereoMix:
            return settings.audioDeviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "default desktop mix device" : settings.audioDeviceName
        }
    }

    private static func escapedDeviceName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "default" }
        return trimmed.replacingOccurrences(of: ":", with: "\\:")
    }
}
