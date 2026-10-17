import Foundation
import SwiftUI
import Combine
#if canImport(CoreMotion)
import CoreMotion
#endif

/// Менеджер пространственной ориентации и гироскопа (Apple CoreMotion Parallax Engine).
/// Обеспечивает плавное 60 FPS отслеживание физического наклона устройства (pitch & roll)
/// с автоматической калибровкой нейтрального положения в руках пользователя.
@MainActor
public final class DeviceMotionManager: ObservableObject {
    public static let shared = DeviceMotionManager()

    #if canImport(CoreMotion)
    private let motionManager = CMMotionManager()
    #endif

    /// Нормализованный крен влево/вправо (-1.0 ... +1.0)
    @Published public private(set) var roll: Double = 0.0

    /// Нормализованный наклон вперед/назад (-1.0 ... +1.0)
    @Published public private(set) var pitch: Double = 0.0

    /// Активен ли гироскоп в данный момент
    @Published public private(set) var isMotionActive: Bool = false

    /// Доступен ли аппаратный гироскоп на данном устройстве
    public var isMotionAvailable: Bool {
        #if canImport(CoreMotion)
        return motionManager.isDeviceMotionAvailable
        #else
        return false
        #endif
    }

    /// Базовые углы для калибровки при открытии книги
    private var basePitch: Double? = nil
    private var baseRoll: Double? = nil

    /// Коэффициент экспоненциального сглаживания (low-pass filter)
    private let smoothingFactor: Double = 0.16

    /// Счетчик активных экранов (для полной остановки сенсора при закрытии)
    private var activeSubscribersCount: Int = 0

    private init() {
        #if canImport(CoreMotion)
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        #endif
    }

    /// Запуск отслеживания при открытии экрана книги
    public func startUpdates() {
        activeSubscribersCount += 1
        guard activeSubscribersCount == 1 else { return }

        basePitch = nil
        baseRoll = nil

        #if canImport(CoreMotion)
        guard motionManager.isDeviceMotionAvailable else {
            isMotionActive = false
            return
        }

        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else { return }

            let rawPitch = motion.attitude.pitch
            let rawRoll = motion.attitude.roll

            // Калибровка нейтрального угла в момент взятия телефона в руки
            if self.basePitch == nil {
                self.basePitch = rawPitch
                self.baseRoll = rawRoll
            }

            let deltaPitch = rawPitch - (self.basePitch ?? rawPitch)
            let deltaRoll = rawRoll - (self.baseRoll ?? rawRoll)

            // Нормализация диапазона наклона (~25 градусов комфортного движения руки)
            let maxAngle = Double.pi / 7.0
            let targetPitch = max(-1.0, min(1.0, deltaPitch / maxAngle))
            let targetRoll = max(-1.0, min(1.0, deltaRoll / maxAngle))

            // Экспоненциальное сглаживание для шелковой плавности
            self.pitch = self.pitch * (1.0 - self.smoothingFactor) + targetPitch * self.smoothingFactor
            self.roll = self.roll * (1.0 - self.smoothingFactor) + targetRoll * self.smoothingFactor
            self.isMotionActive = true
        }
        #endif
    }

    /// Остановка гироскопа при закрытии экрана для сбережения 100% заряда батареи
    public func stopUpdates() {
        activeSubscribersCount = max(0, activeSubscribersCount - 1)
        guard activeSubscribersCount == 0 else { return }

        #if canImport(CoreMotion)
        motionManager.stopDeviceMotionUpdates()
        #endif
        isMotionActive = false
        basePitch = nil
        baseRoll = nil
        withAnimation(.easeOut(duration: 0.3)) {
            pitch = 0.0
            roll = 0.0
        }
    }

    /// Повторная калибровка нейтрального угла наклона
    public func recalibrate() {
        basePitch = nil
        baseRoll = nil
    }

    /// Ручная установка наклона (для жестов перетаскивания пальцем, мыши на macOS и тестов)
    public func setManualOffset(pitch: Double, roll: Double) {
        self.pitch = max(-1.0, min(1.0, pitch))
        self.roll = max(-1.0, min(1.0, roll))
    }
}
