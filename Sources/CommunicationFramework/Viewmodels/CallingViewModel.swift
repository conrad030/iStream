//
//  CallingViewModel.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 01.06.22.
//

import SwiftUI
import Combine
import PushKit
import CallKit
import AVFoundation

public class CallingViewModel: ObservableObject {
    
    @Published private var callingModel: CallingModel
    private var anyCancellable: AnyCancellable? = nil
    
    public var localVideoStreamModel: VideoStreamModel? {
        self.callingModel.localVideoStreamModel
    }
    public var remoteVideoStreamModel: VideoStreamModel? {
        self.callingModel.remoteVideoStreamModel
    }
    @Published public var localeVideoIsOn: Bool = true
    @Published public var remoteVideoIsOn: Bool = false
    @Published public var isMuted: Bool = false
    
    @Published public var enableCallButton: Bool = false
    @Published public var presentCallView: Bool = false
    
    @Published public var displayName: String?
        
    public init<Model: CallingModel & ObservableObject>(callingModel: Model) {
        self.callingModel = callingModel
        self.callingModel.delegate = self
        /// Has to be linked to AnyCancellable, so changes of the ObservableObject are getting detected
        self.anyCancellable = callingModel.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        _ = PushRegistryDelegate.shared
        self.initPushRegistry()
        self.initProvider()
        self.requestAudioAndVideoPermission { _ in }
    }
    
    public func initCallingViewModel(identifier: String, displayName: String, token: String) {
        if !identifier.isEmpty && !displayName.isEmpty && !token.isEmpty {
            self.displayName = displayName
            self.callingModel.initCallingModel(identifier: identifier, token: token, displayName: displayName)
        } else {
            print("CallingModel couldn't be initialized. Credentials are missing.")
        }
    }
    
    public func setVoipToken(token: Data?) {
        self.callingModel.voipToken = token
    }
    
    public func startCall(identifier: String) {
        self.requestAudioPermission { success in
            if !success {
                print("Audio permission denied.")
                return
            }
            self.requestVideoPermission { success in
                if !success {
                    print("Video permission denied.")
                    return
                }
                
                self.callingModel.startCall(calleeIdentifier: identifier)
            }
        }
    }
    
    public func endCall() {
        self.callingModel.endCall()
    }
    
    public func toggleVideo() {
        if self.localeVideoIsOn {
            self.stopVideo()
        } else {
            self.startVideo()
        }
    }
    
    private func startVideo() {
        self.callingModel.startVideo()
    }
    
    private func stopVideo() {
        self.callingModel.stopVideo()
    }
    
    public func toggleMute() {
        if self.isMuted {
            self.unmute()
        } else {
            self.mute()
        }
    }
    
    private func mute() {
        self.callingModel.mute()
    }
    
    private func unmute() {
        self.callingModel.unmute()
    }
    
    private func handlePushNotification(payload: PKPushPayload) {
        self.callingModel.handlePushNotification(payload: payload)
    }
    
    private func initPushRegistry() {
        PushRegistryDelegate.shared.setVoipToken = { token in
            self.setVoipToken(token: token)
        }
        PushRegistryDelegate.shared.handlePushNotification = { payload in
            self.handlePushNotification(payload: payload)
        }
    }
    
    private func initProvider() {
        ProviderDelegate.shared.acceptCall = { callId in
            self.requestAudioAndVideoPermission { authorized in
                if !authorized {
                    print("Record permissions not denied.")
                    return
                }
                // TODO: Funktioniert nur, wenn die App geöffnet ist, weil incomingCall erst dann existiert.
                self.callingModel.acceptIncomingCall(callId: callId)
            }
        }

        // TODO: Wird auch aufgerufen, wenn Anruf von Callee beendet wird
        ProviderDelegate.shared.endCall = { callId in
            self.callingModel.endCall(callId: callId)
        }

        ProviderDelegate.shared.muteCall = { callId in
            self.callingModel.toggleMute(callId: callId)
        }
    }
    
    // MARK: - Permission management.

    private func requestAudioAndVideoPermission(completion: @escaping (Bool) -> Void) {
        self.requestAudioPermission { authorized in
            if !authorized {
                return completion(false)
            } else {
                self.requestVideoPermission { authorized in
                    return completion(authorized)
                }
            }
        }
    }
    /// Request for audio permission
    private func requestAudioPermission(completion: @escaping (Bool) -> Void) {
        let audioSession = AVAudioSession.sharedInstance()
        switch audioSession.recordPermission {
        case .undetermined:
            audioSession.requestRecordPermission { granted in
                if granted {
                    completion(true)
                } else {
                    print("User did not grant audio permission")
                    completion(false)
                }
            }
        case .denied:
            print("User did not grant audio permission, it should redirect to Settings")
            completion(false)
        case .granted:
            completion(true)
        @unknown default:
            print("Audio session record permission unknown case detected")
            completion(false)
        }
    }

    /// Request for video permission
    private func requestVideoPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { authorized in
                if authorized {
                    completion(true)
                } else {
                    print("User did not grant video permission")
                    completion(false)
                }
            }
        case .restricted, .denied:
            print("User did not grant video permission, it should redirect to Settings")
            completion(false)
        case .authorized:
            completion(true)
        @unknown default:
            print("AVCaptureDevice authorizationStatus unknown case detected")
            completion(false)
        }
    }
}

extension CallingViewModel: CallingModelDelegate {
    
    public func pushNotificationsRegistered() {
        self.enableCallButton = true
    }
    
    public func muteCall(callId: UUID, mute: Bool) {
        CallController.shared.setMutedCall(callId: callId, muted: mute) { error in
            if let error = error {
                print("Failed to setMutedCall: \(error.localizedDescription)\n")
            } else {
                print("setMutedCall \(mute) successfully.\n")
                DispatchQueue.main.async {
                    self.isMuted = mute
                }
            }
        }
    }
    
    public func toggleMuteSucceeded(with mute: Bool) {
        self.isMuted = mute
    }
    
    public func toggleVideoSucceeded(with videoOn: Bool) {
        self.localeVideoIsOn = videoOn
    }
    
    public func startCall(callId: UUID) {
        CallController.shared.startCall(callId: callId, handle: self.displayName ?? "Anonymous", isVideo: true) { error in
            if let error = error {
                print("Outgoing call failed: \(error.localizedDescription)")
            } else {
                print("outgoing call started.")
            }
        }
    }
    
    public func endCall(callId: UUID) {
        CallController.shared.endCall(callId: callId) { error in
            if let error = error {
                print("EndCall request failed: \(error.localizedDescription)\n")
            } else {
                print("EndCall request succeeded.\n")
                DispatchQueue.main.async {
                    self.presentCallView = false
                }
            }
        }
    }
    
    public func onCallStarted(callId: UUID) {
        ProviderDelegate.shared.startedConnectingAt(callId: callId)
        ProviderDelegate.shared.connectedAt(callId: callId)
        self.presentCallView = true
    }
    
    public func onCallEnded(callId: UUID) {
        ProviderDelegate.shared.reportCallEnded(callId: callId, reason: CXCallEndedReason.remoteEnded)
        self.presentCallView = false
    }
}
