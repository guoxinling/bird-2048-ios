import AVFoundation
import Foundation

final class SoundPlayer {
    enum Effect: String {
        case move
        case merge
    }

    nonisolated(unsafe) static let live = SoundPlayer()

    private let playEffect: ((Effect) -> Void)?
    private var players: [Effect: AVAudioPlayer] = [:]

    init(bundle: Bundle = .main) {
        playEffect = nil
        for effect in [Effect.move, .merge] {
            guard let url = bundle.url(forResource: effect.rawValue, withExtension: "mp3") else {
                continue
            }

            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[effect] = player
            }
        }
    }

    init(playEffect: @escaping (Effect) -> Void) {
        self.playEffect = playEffect
    }

    func play(_ effect: Effect) {
        if let playEffect {
            playEffect(effect)
            return
        }

        guard let player = players[effect] else {
            return
        }

        player.currentTime = 0
        player.play()
    }
}
