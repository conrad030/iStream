//
//  MockCallingModel.swift
//  iStreamTests
//
//  Created by Conrad Felgentreff on 24.06.22.
//

import Foundation
import PushKit
@testable import iStream

class MockCallingModel: ObservableObject, CallingModel {
    
    var delegate: CallingModelDelegate?
    
    var localVideoStreamModel: VideoStreamModel?
    
    var remoteVideoStreamModel: VideoStreamModel?
    
    var voipToken: Data?
    
    public var callId: UUID?
    private var isMuted = false
    
    private(set) var initCallingModelCalled = false
    private(set) var registerPushNotificationsCalled = false
    private(set) var acceptIncomingCallCalled = false
    private(set) var endCallWithIdCalled = false
    private(set) var toggleMuteCalled = false
    private(set) var handlePushNotificationCalled = false
    private(set) var startCallCalled = false
    private(set) var endCallCalled = false
    private(set) var muteCalled = false
    private(set) var unmuteCalled = false
    private(set) var startVideoCalled = false
    private(set) var stopVideoCalled = false
    
    func initCallingModel(identifier: String, token: String, displayName: String) {
        self.initCallingModelCalled = true
    }
    
    func registerPushNotifications(voipToken: Data) {
        self.registerPushNotificationsCalled = true
        self.delegate?.pushNotificationsRegistered()
    }
    
    func acceptIncomingCall(callId: UUID) {
        self.acceptIncomingCallCalled = true
        self.callId = callId
        self.delegate?.toggleVideoSucceeded(with: true)
    }
    
    func endCall(callId: UUID) {
        self.endCallWithIdCalled = true
        if self.callId == callId {
            self.delegate?.endCall(callId: callId)
        }
    }
    
    func toggleMute(callId: UUID) {
        self.toggleMuteCalled = true
        self.isMuted.toggle()
        self.delegate?.toggleMuteSucceeded(with: self.isMuted)
    }
    
    func handlePushNotification(payload: PKPushPayload) {
        self.handlePushNotificationCalled = true
    }
    
    func startCall(calleeIdentifier: String) {
        self.startCallCalled = true
        self.callId = UUID()
        self.startVideo()
        self.delegate?.startCall(callId: self.callId!)
        self.delegate?.onCallStarted(callId: self.callId!)
    }
    
    func endCall() {
        self.endCallCalled = true
        if let callId = self.callId {
            self.delegate?.endCall(callId: callId)
            self.delegate?.onCallEnded(callId: callId)
        }
    }
    
    func mute() {
        self.muteCalled = true
        if let callId = self.callId {
            self.delegate?.muteCall(callId: callId, mute: true)
            self.delegate?.toggleMuteSucceeded(with: true)
        }
    }
    
    func unmute() {
        self.unmuteCalled = true
        if let callId = self.callId {
            self.delegate?.muteCall(callId: callId, mute: false)
            self.delegate?.toggleMuteSucceeded(with: false)
        }
    }
    
    func startVideo() {
        self.startVideoCalled = true
        if self.callId != nil {
            self.delegate?.toggleVideoSucceeded(with: true)
        }
    }
    
    func stopVideo() {
        self.stopVideoCalled = true
        if self.callId != nil {
            self.delegate?.toggleVideoSucceeded(with: false)
        }
    }
}
