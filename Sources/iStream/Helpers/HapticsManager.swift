//
//  HapticsManager.swift
//  iStream
//
//  Created by Conrad Felgentreff on 04.05.22.
//

import CoreHaptics

class HapticsManager: ObservableObject {
    
    static let shared = HapticsManager()
    
    @Published private var engine: CHHapticEngine?
    
    private init() {
        self.prepareHaptics()
    }
    
    func standardVibration() {
        do {
            try self.vibrate()
        } catch {
            self.prepareHaptics()
            try? self.vibrate()
        }
    }
    
    func sharpVibration() {
        do {
            try self.vibrate(intensity: 1, sharpness: 1)
        } catch {
            self.prepareHaptics()
            try? self.vibrate(intensity: 1, sharpness: 1)
        }
    }
    
    func softVibration() {
        do {
            try self.vibrate(intensity: 0.5, sharpness: 0.5)
        } catch {
            self.prepareHaptics()
            try? self.vibrate(intensity: 0.5, sharpness: 0.5)
        }
    }
    
    private func vibrate(intensity: Float = 0.7, sharpness: Float = 1) throws {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events = [CHHapticEvent]()
        
        // create one intense, sharp tap
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        events.append(event)
        
        // convert those events into a pattern and play it immediately
        let pattern = try CHHapticPattern(events: events, parameters: [])
        let player = try engine?.makePlayer(with: pattern)
        try player?.start(atTime: 0)
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            self.engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
    }
}
