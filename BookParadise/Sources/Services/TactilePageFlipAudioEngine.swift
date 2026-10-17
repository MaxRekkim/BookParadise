import Foundation
import AVFoundation
import SwiftUI

/// Акустический движок тактильного шелеста страниц (Tactile Page-Flip Audio Engine)
/// Синтезирует процедурные звуки перелистывания бумаги разной плотности с динамической огибающей.
@MainActor
public final class TactilePageFlipAudioEngine: ObservableObject {
    public static let shared = TactilePageFlipAudioEngine()

    @Published public var isSoundEnabled: Bool = true
    @Published public var paperWeight: PaperWeight = .standard
    @Published public var volume: Float = 0.65

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var cachedBuffers: [PaperWeight: AVAudioPCMBuffer] = [:]
    private var isConfigured: Bool = false

    private init() {
        prepareEngine()
    }

    /// Предварительная инициализация и компиляция буферов звука бумаги в памяти
    public func prepareEngine() {
        guard !isConfigured else { return }

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()

        engine.attach(player)
        let mainMixer = engine.mainMixerNode
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!

        engine.connect(player, to: mainMixer, format: format)
        mainMixer.outputVolume = volume

        do {
            #if os(iOS) && !targetEnvironment(macCatalyst)
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try? session.setActive(true)
            #endif

            try engine.start()
            self.audioEngine = engine
            self.playerNode = player
            self.isConfigured = true

            // Синтезируем аудио-буферы для всех 3 типов бумаги заранее
            for weight in PaperWeight.allCases {
                if let buf = synthesizePaperRustleBuffer(weight: weight, format: format) {
                    cachedBuffers[weight] = buf
                }
            }
        } catch {
            print("TactilePageFlipAudioEngine: could not start engine (\(error.localizedDescription))")
        }
    }

    /// Воспроизведение звука перелистывания страницы с адаптацией под скорость жеста
    public func playPageFlip(velocity: CGFloat = 1.0) {
        guard isSoundEnabled else { return }

        // Если движок не запущен, пробуем мягкий перезапуск
        if audioEngine == nil || audioEngine?.isRunning == false {
            isConfigured = false
            prepareEngine()
        }

        guard let player = playerNode, let engine = audioEngine, engine.isRunning else { return }
        guard let buffer = cachedBuffers[paperWeight] else { return }

        // Подстраиваем громкость под скорость жеста (0.4...1.0)
        let normalizedVelocity = max(0.5, min(1.5, Float(velocity)))
        player.volume = min(1.0, (volume * 0.9) * normalizedVelocity)

        if player.isPlaying {
            player.stop()
        }

        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    // MARK: - Процедурный синтез шелеста бумаги (Dynamic Envelope + Bandpass Noise)
    private func synthesizePaperRustleBuffer(weight: PaperWeight, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = 44100.0
        // Длительность звука: от 0.16с (легкая) до 0.26с (верже)
        let durationSeconds: Double = {
            switch weight {
            case .lightweight: return 0.16
            case .standard: return 0.21
            case .heavyVerge: return 0.26
            }
        }()

        let frameCount = AVAudioFrameCount(sampleRate * durationSeconds)
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        pcmBuffer.frameLength = frameCount

        let channels = Int(format.channelCount)
        let floatBuffers = pcmBuffer.floatChannelData

        guard let leftData = floatBuffers?[0] else { return nil }
        let rightData = channels > 1 ? floatBuffers?[1] : nil

        let pitchMult = weight.basePitchMultiplier
        var noiseStateLeft: Float = 0.0
        var noiseStateRight: Float = 0.0

        for frame in 0..<Int(frameCount) {
            let progress = Double(frame) / Double(frameCount)

            // 1. Огибающая громкости (Attack -> Air Leaf Flutter -> Crisp Landing Decay)
            let attackPhase = min(1.0, progress / 0.12)
            let decayPhase = max(0.0, 1.0 - pow(progress, 1.4))
            let airFlutter = 0.85 + 0.15 * sin(progress * .pi * 8.0)
            let envelope = Float(attackPhase * decayPhase * airFlutter)

            // 2. Розовый / полосовой шум с акцентом на шероховатость волокон бумаги
            let whiteLeft = Float.random(in: -1.0...1.0)
            let whiteRight = Float.random(in: -1.0...1.0)

            // Сглаживание шума в зависимости от плотности бумаги
            let smoothing: Float = (0.045 / pitchMult)
            noiseStateLeft = (noiseStateLeft + (smoothing * whiteLeft)) / (1.0 + smoothing)
            noiseStateRight = (noiseStateRight + (smoothing * whiteRight)) / (1.0 + smoothing)

            // Микро-треск бумажных волокон при перегибе в середине движения
            var fiberCrack: Float = 0.0
            if progress > 0.35 && progress < 0.65 && Float.random(in: 0...1) < 0.015 {
                fiberCrack = Float.random(in: 0.15...0.35) * (Float.random(in: 0...1) > 0.5 ? 1 : -1)
            }

            let sampleL = ((noiseStateLeft * 2.8) + fiberCrack) * envelope * 0.45
            let sampleR = ((noiseStateRight * 2.8) + fiberCrack) * envelope * 0.45

            leftData[frame] = max(-1.0, min(1.0, sampleL))
            rightData?[frame] = max(-1.0, min(1.0, sampleR))
        }

        return pcmBuffer
    }
}
