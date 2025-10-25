import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Tiny audio player for short, bundled sounds. No-ops if assets missing.
final class AudioPlayer {
    static let shared = AudioPlayer()
    private init() {}

    #if canImport(AVFoundation)
    private var player: AVAudioPlayer?
    private var sessionConfigured = false
    #endif

    func play(named name: String, ext: String = "caf", volume: Float = 1.0) {
        #if canImport(AVFoundation)
        configureSessionIfNeeded()
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            prepareAndPlay(url: url, volume: volume)
            return
        }
        #if canImport(UIKit)
        if let asset = NSDataAsset(name: name) {
            prepareAndPlay(data: asset.data, volume: volume)
            return
        }
        #endif
        #endif
    }

    func stop() {
        #if canImport(AVFoundation)
        player?.stop()
        player = nil
        #endif
    }

    #if canImport(AVFoundation)
    private func configureSessionIfNeeded() {
        guard !sessionConfigured else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])
            sessionConfigured = true
        } catch {
            // Ignore and keep default session configuration.
        }
    }

    private func prepareAndPlay(url: URL, volume: Float) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = volume
            player?.prepareToPlay()
            player?.play()
        } catch {
            // Intentionally mute errors
        }
    }

    private func prepareAndPlay(data: Data, volume: Float) {
        do {
            player = try AVAudioPlayer(data: data)
            player?.volume = volume
            player?.prepareToPlay()
            player?.play()
        } catch {
            // Intentionally mute errors
        }
    }
    #endif
}
