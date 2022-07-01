//
//  CallingModelDelegate.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 01.06.22.
//

import SwiftUI

protocol CallingModelDelegate {
    func pushNotificationsRegistered()
    func muteCall(callId: UUID, mute: Bool)
    func toggleMuteSucceeded(with mute: Bool)
    func toggleVideoSucceeded(with videoOn: Bool)
    func startCall(callId: UUID)
    func endCall(callId: UUID)
    func onCallStarted(callId: UUID)
    func onCallEnded(callId: UUID)
}
