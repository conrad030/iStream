//
//  ChatModel.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 01.06.22.
//

import Foundation
import PushKit

public protocol CallingModel {
    var delegate: CallingModelDelegate? { get set }
    var localVideoStreamModel: VideoStreamModel? { get }
    var remoteVideoStreamModel: VideoStreamModel? { get }
    var voipToken: Data? { get set }
    func initCallingModel(identifier: String, token: String, displayName: String)
    func registerPushNotifications(voipToken: Data)
    func acceptIncomingCall(callId: UUID)
    func endCall(callId: UUID)
    func toggleMute(callId: UUID)
    func handlePushNotification(payload: PKPushPayload)
    func startCall(calleeIdentifier: String)
    func endCall()
    func mute()
    func unmute()
    func startVideo()
    func stopVideo()
}
