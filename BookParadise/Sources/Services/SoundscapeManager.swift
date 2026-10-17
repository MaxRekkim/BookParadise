import Foundation
import AVFoundation
import CoreAudio
import SwiftUI

public enum SoundscapeType: String, CaseIterable, Identifiable {
    case none = "none"
    case rain = "rain"
    case fireplace = "fireplace"
    case coffeehouse = "coffeehouse"
    case forest = "forest"
    case customMix = "customMix"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .none: return "Тишина"
        case .rain: return "Дождь за окном"
        case .fireplace: return "Камин в библиотеке"
        case .coffeehouse: return "Уютная кофейня"
        case .forest: return "Лесной бриз"
        case .customMix: return "Свой микс (Студия)"
        }
    }

    public var icon: String {
        switch self {
        case .none: return "speaker.slash"
        case .rain: return "cloud.rain.fill"
        case .fireplace: return "flame.fill"
        case .coffeehouse: return "cup.and.saucer.fill"
        case .forest: return "leaf.fill"
        case .customMix: return "slider.horizontal.3"
        }
    }

    public var accentColor: Color {
        switch self {
        case .none: return .secondary
        case .rain: return .blue
        case .fireplace: return .orange
        case .coffeehouse: return Color(red: 0.6, green: 0.4, blue: 0.2)
        case .forest: return .green
        case .customMix: return Color(red: 0.52, green: 0.14, blue: 0.20)
        }
    }
}

public struct SoundscapePreset: Identifiable {
    public let id = UUID()
    public let name: String
    public let icon: String
    public let rain: Float
    public let fire: Float
    public let coffee: Float
    public let forest: Float
}

@MainActor
public class SoundscapeManager: ObservableObject {
    public static let shared = SoundscapeManager()

    @Published public var currentMode: SoundscapeType = .none
    @Published public var isPlaying: Bool = false

    // Каналы микшера (0.0 ... 1.0)
    @Published public var rainVolume: Float = 0.6
    @Published public var fireplaceVolume: Float = 0.0
    @Published public var coffeehouseVolume: Float = 0.0
    @Published public var forestVolume: Float = 0.0

    @Published public var volume: Float = 0.6 {
        didSet {
            engine?.mainMixerNode.outputVolume = volume
        }
    }

    public let presets: [SoundscapePreset] = [
        SoundscapePreset(name: "Только дождь", icon: "cloud.heavyrain.fill", rain: 0.8, fire: 0.0, coffee: 0.0, forest: 0.0),
        SoundscapePreset(name: "У камина в грозу", icon: "flame.fill", rain: 0.4, fire: 0.75, coffee: 0.0, forest: 0.0),
        SoundscapePreset(name: "Кофейня в ливень", icon: "cup.and.saucer.fill", rain: 0.5, fire: 0.0, coffee: 0.7, forest: 0.0),
        SoundscapePreset(name: "Лесной домик", icon: "leaf.fill", rain: 0.2, fire: 0.5, coffee: 0.0, forest: 0.75)
    ]

    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?

    private init() {}

    public func setMode(_ mode: SoundscapeType) {
        if mode == .none {
            stop()
            currentMode = .none
            return
        }

        currentMode = mode
        switch mode {
        case .rain:
            applyVolumes(rain: 0.8, fire: 0, coffee: 0, forest: 0)
        case .fireplace:
            applyVolumes(rain: 0, fire: 0.8, coffee: 0, forest: 0)
        case .coffeehouse:
            applyVolumes(rain: 0, fire: 0, coffee: 0.8, forest: 0)
        case .forest:
            applyVolumes(rain: 0, fire: 0, coffee: 0, forest: 0.8)
        case .customMix, .none:
            break
        }

        if !isPlaying {
            startEngine()
        }
    }

    public func applyPreset(_ preset: SoundscapePreset) {
        currentMode = .customMix
        applyVolumes(rain: preset.rain, fire: preset.fire, coffee: preset.coffee, forest: preset.forest)
        if !isPlaying {
            startEngine()
        }
        HapticManager.shared.lightTap()
    }

    public func applyVolumes(rain: Float, fire: Float, coffee: Float, forest: Float) {
        self.rainVolume = rain
        self.fireplaceVolume = fire
        self.coffeehouseVolume = coffee
        self.forestVolume = forest
    }

    public func togglePlayback() {
        if isPlaying {
            stop()
        } else {
            if currentMode == .none {
                setMode(.rain)
            } else {
                startEngine()
            }
        }
    }

    public func stop() {
        if let engine = engine, engine.isRunning {
            engine.stop()
        }
        engine = nil
        sourceNode = nil
        isPlaying = false
    }

    private func startEngine() {
        stop()

        do {
            #if os(iOS) && !targetEnvironment(macCatalyst)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            #endif

            let newEngine = AVAudioEngine()
            let format = newEngine.outputNode.outputFormat(forBus: 0)

            // Процедурный мульти-канальный генератор
            var rainSampleState: Float = 0.0
            var fireSampleState: Float = 0.0
            var coffeeSampleState: Float = 0.0
            var forestSampleState: Float = 0.0
            var crackleCounter: Int = 0
            var lfoPhase: Float = 0.0

            let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
                guard let self = self else { return noErr }
                let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
                let sampleRate = Float(format.sampleRate > 0 ? format.sampleRate : 44100.0)

                let currentRain = self.rainVolume
                let currentFire = self.fireplaceVolume
                let currentCoffee = self.coffeehouseVolume
                let currentForest = self.forestVolume

                for frame in 0..<Int(frameCount) {
                    lfoPhase += 1.0 / sampleRate
                    if lfoPhase > 1000.0 { lfoPhase = 0.0 }

                    var mixedSample: Float = 0.0

                    // 1. Дождь
                    if currentRain > 0.01 {
                        let white = Float.random(in: -1.0...1.0)
                        rainSampleState = (rainSampleState + (0.02 * white)) / 1.02
                        let wave = 0.8 + 0.2 * sin(lfoPhase * 0.4)
                        mixedSample += (rainSampleState * 3.2 * wave) * currentRain
                    }

                    // 2. Камин
                    if currentFire > 0.01 {
                        let white = Float.random(in: -1.0...1.0)
                        fireSampleState = (fireSampleState + (0.015 * white)) / 1.015
                        var crackle: Float = 0.0
                        crackleCounter += 1
                        if crackleCounter > 8000 && Float.random(in: 0...1) < 0.0035 {
                            crackle = Float.random(in: 0.3...0.85) * (Float.random(in: 0...1) > 0.5 ? 1 : -1)
                            crackleCounter = 0
                        }
                        mixedSample += ((fireSampleState * 2.4) + crackle) * currentFire
                    }

                    // 3. Кофейня
                    if currentCoffee > 0.01 {
                        let white = Float.random(in: -1.0...1.0)
                        coffeeSampleState = (coffeeSampleState + (0.01 * white)) / 1.01
                        let breath = 0.85 + 0.15 * sin(lfoPhase * 0.25)
                        mixedSample += (coffeeSampleState * 2.6 * breath) * currentCoffee
                    }

                    // 4. Лес
                    if currentForest > 0.01 {
                        let white = Float.random(in: -1.0...1.0)
                        forestSampleState = (forestSampleState + (0.03 * white)) / 1.03
                        let wind = 0.7 + 0.3 * sin(lfoPhase * 0.18)
                        mixedSample += (forestSampleState * 2.8 * wind) * currentForest
                    }

                    // Лимитер
                    let clamped = max(-1.0, min(1.0, mixedSample))

                    for buffer in ablPointer {
                        let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                        buf[frame] = clamped
                    }
                }
                return noErr
            }

            self.sourceNode = node
            self.engine = newEngine

            newEngine.attach(node)
            newEngine.connect(node, to: newEngine.mainMixerNode, format: format)
            newEngine.mainMixerNode.outputVolume = volume

            try newEngine.start()
            isPlaying = true
        } catch {
            print("Failed to start soundscape audio engine: \(error)")
            isPlaying = false
        }
    }
}
