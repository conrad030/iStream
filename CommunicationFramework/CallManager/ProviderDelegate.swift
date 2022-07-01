//
//  ProviderDelegate.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 21.04.22.
//

import SwiftUI
import CallKit
import AVFoundation

class ProviderDelegate: NSObject {
    
    public static let shared: ProviderDelegate = ProviderDelegate()
    private(set) var provider: CXProvider?
    
    // MARK: - Callback events

    public var hasIncomingCall: ((UUID, String, Bool) -> Void)?

    public var acceptCall: ((UUID) -> Void)?

    public var endCall: ((UUID) -> Void)?

    public var muteCall: ((UUID) -> Void)?

    deinit {
        self.provider?.invalidate()
    }
    
    public func configureProvider() {
        let configuration = CXProviderConfiguration()
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportsVideo = true
        configuration.iconTemplateImageData = UIImage(systemName: "video")?.pngData()
        self.provider = CXProvider(configuration: configuration)
        self.provider?.setDelegate(self, queue: DispatchQueue.main)
    }

    // MARK: - Configure AudioSession

    public func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            if audioSession.category != .playAndRecord {
                try audioSession.setCategory(AVAudioSession.Category.playAndRecord, options: [AVAudioSession.CategoryOptions.allowBluetooth, AVAudioSession.CategoryOptions.duckOthers])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            }
            if audioSession.mode != .voiceChat {
                try audioSession.setMode(.voiceChat)
            }
        } catch {
            print("Error configuring AVAudioSession: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle incoming call

    /// Reports a new incoming call with the specified unique identifier to the provider.
    /// - Parameters:
    ///   - callId: The unique identifier of the call.
    ///   - handle: The handle for the caller.
    ///   - hasVideo: If `true`, the call can include video.
    ///   - completion: A closure that is executed once the call is allowed or disallowed by the system.
    public func reportNewIncomingCall(callId: UUID, handle: String, hasVideo: Bool = false, completion: @escaping ((Error?) -> Void)) {
        // Construct a CXCallUpdate describing the incoming call, including the caller.
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: "Incoming call")
        update.localizedCallerName = handle
        update.hasVideo = hasVideo

        // Report the incoming call to the system.
        provider?.reportNewIncomingCall(with: callId, update: update) { error in
            if let error = error {
                completion(error)
            } else {
                self.configureAudioSession()
                completion(nil)
            }
        }
    }

    // MARK: - Handle outgoing call

    /// Reports to the provider that an outgoing call with the specified unique identifier started connecting at a particular time.
    /// - Parameter callId: The unique identifier of the call.
    public func startedConnectingAt(callId: UUID) {
        self.configureAudioSession()
        self.provider?.reportOutgoingCall(with: callId, startedConnectingAt: Date())
    }

    /// Reports to the provider that an outgoing call with the specified unique identifier finished connecting at a particular time.
    /// - Parameter callId: The unique identifier of the call.
    public func connectedAt(callId: UUID) {
        self.provider?.reportOutgoingCall(with: callId, connectedAt: Date())
    }

    // MARK: - Handle ended calls

    /// Reports to the provider that a call with the specified identifier ended at a given date for a particular reason.
    /// - Parameter callId: The unique identifier of the call.
    public func reportCallEnded(callId: UUID, reason: CXCallEndedReason) {
        self.provider?.reportCall(with: callId, endedAt: Date(), reason: reason)
    }
}

extension ProviderDelegate: CXProviderDelegate {

    // MARK: - Handle CallKitUI actions

    /// Called when the provider begins.
    public func providerDidBegin(_: CXProvider) {
        print("providerDidBegin")
    }

    /// Called when the provider is reset.
    public func providerDidReset(_: CXProvider) {
        print("providerDidReset")
    }

    /// Called when the provider performs the specified start call action.
    public func provider(_: CXProvider, perform action: CXStartCallAction) {
        print("CXProvider tried to start a call from system.")
        action.fulfill()
    }

    /// Called when the provider performs the specified answer call action.
    public func provider(_: CXProvider, perform action: CXAnswerCallAction) {
        self.acceptCall?(action.callUUID)
        action.fulfill()
    }

    /// Called when the provider performs the specified end call action.
    public func provider(_: CXProvider, perform action: CXEndCallAction) {
        self.endCall?(action.callUUID)
        action.fulfill()
    }

    /// Called when the provider performs the specified set held call action.
    public func provider(_: CXProvider, perform action: CXSetHeldCallAction) {
        action.fulfill()
    }

    /// Called when the provider performs the specified set muted call action.
    public func provider(_: CXProvider, perform action: CXSetMutedCallAction) {
        self.muteCall?(action.callUUID)
        action.fulfill()
    }

    /// Called when the provider performs the specified set group call action.
    public func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
        action.fulfill()
    }

    /// Called when the provider performs the specified action times out.
    public func provider(_: CXProvider, timedOutPerforming _: CXAction) {}
}

