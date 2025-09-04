import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif

/// Tiny audio player for short, bundled sounds. No-ops if assets missing.
final class AudioPlayer {
    static let shared = AudioPlayer()
    private init() {}

    #if canImport(AVFoundation)
    private var player: AVAudioPlayer?
    #endif

    func play(named name: String, ext: String = "caf", volume: Float = 1.0) {
        #if canImport(AVFoundation)
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = volume
            player?.prepareToPlay()
            player?.play()
        } catch {
            // Intentionally ignore in scaffold
        }
        #endif
    }

    func stop() {
        #if canImport(AVFoundation)
        player?.stop()
        player = nil
        #endif
    }
}

