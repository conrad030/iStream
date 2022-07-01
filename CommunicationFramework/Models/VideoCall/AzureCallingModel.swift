//
//  CallingViewmodel.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 21.04.22.
//

// MARK: Viewmodel for managing calls. Singleton, so the object can be accessed in other classes

import AzureCommunicationCalling
import PushKit

public class AzureCallingModel: NSObject, ObservableObject, CallingModel {
    
    var delegate: CallingModelDelegate?
    
    private var callClient: CallClient = CallClient()
    private var callAgent: CallAgent?
    private var call: Call?
    private var deviceManager: DeviceManager?
    private var incomingCall: IncomingCall?
    public var voipToken: Data?
    private var localVideoStream: LocalVideoStream?
    
    private var displayName: String = ""
    private var identifier: String = ""
    
    @Published public var callState: CallState = CallState.none
    @Published private var azureLocalVideoStreamModel: AzureLocalVideoStreamModel?
    public var localVideoStreamModel: VideoStreamModel? {
        self.azureLocalVideoStreamModel
    }
    @Published private var azureRemoteVideoStreamModel: AzureRemoteVideoStreamModel?
    public var remoteVideoStreamModel: VideoStreamModel? {
        self.azureRemoteVideoStreamModel
    }
    @Published public var incomingCallPushNotification: PushNotificationInfo?
    @Published public var isMicrophoneMuted: Bool = false
    @Published public var isLocalVideoStreamEnabled: Bool = false
    @Published public var callViewModelInitialized: Bool = false
    
    private var communicationUserToken: CommunicationUserTokenModel?
    
    public var hasCallAgent: Bool {
        self.callAgent != nil
    }
    
    private var hasLocalVideoStreams: Bool {
        self.localVideoStream != nil
    }
    
    private var hasIncomingCall: ((Bool) -> Void)?
    
    public func initCallingModel(identifier: String, token: String, displayName: String) {
        if !self.hasCallAgent {
            self.identifier = identifier
            self.displayName = displayName
            self.communicationUserToken = CommunicationUserTokenModel(token: token, expiresOn: nil, communicationUserId: identifier, displayName: displayName)
            self.initCallAgent(communicationUserTokenModel: self.communicationUserToken!) { success in
                if !success {
                    print("callAgent not intialized.\n")
                }
            }
        }
    }
    
    private func initCallAgent(communicationUserTokenModel: CommunicationUserTokenModel, completion: @escaping (Bool) -> Void) {
        if let communicationUserId = communicationUserTokenModel.communicationUserId,
           let token = communicationUserTokenModel.token {
            do {
                let communicationTokenCredential = try CommunicationTokenCredential(token: token)
                let callAgentOptions = CallAgentOptions()
                callAgentOptions.displayName = communicationUserTokenModel.displayName ?? communicationUserId
                self.callClient.createCallAgent(userCredential: communicationTokenCredential, options: callAgentOptions) { (callAgent, error) in
                    print("CallAgent successfully created.\n")
                    if self.callAgent != nil {
                        print("\nsomething went wrhong with lifecycle.\n")
                        self.callAgent?.delegate = nil
                    }
                    self.callAgent = callAgent
                    self.callAgent?.delegate = self
                    
                    if let token = self.voipToken {
                        self.registerPushNotifications(voipToken: token)
                    }
                    completion(true)
                }
            } catch {
                print("Error: \(error.localizedDescription)")
                completion(false)
            }
        } else {
            print("Invalid communicationUserTokenModel.\n")
        }
    }
    
    /// Register push notifications with voip token
    public func registerPushNotifications(voipToken: Data) {
        self.callAgent?.registerPushNotifications(deviceToken: voipToken, completionHandler: { error in
            if error == nil {
                print("Successfully registered to VoIP push notification.\n")
                self.delegate?.pushNotificationsRegistered()
            } else {
                print("Failed to register VoIP push notification.\(String(describing: error))\n")
            }
        })
    }
    
    public func handlePushNotification(payload: PKPushPayload) {
        let incomingCallPushNotification = PushNotificationInfo.fromDictionary(payload.dictionaryPayload)
        self.handlePushNotification(incomingCallPushNotification: incomingCallPushNotification)
    }
    
    /// Handle an icoming call push notification
    // TODO: Herausfinden, wieso diese Methode wichtig ist. Wozu callAgent.handlePush?
    private func handlePushNotification(incomingCallPushNotification: PushNotificationInfo) {
        if let callAgent = self.callAgent {
            print("CallAgent found.\n")
            callAgent.handlePush(notification: incomingCallPushNotification, completionHandler: { error in
                self.handlePushCompletion(error: error)
            })
        } else {
            print("CallAgent not found.\nConnecting to Communication Services...\n")

            if let communicationUserToken = self.communicationUserToken {
                self.initCallAgent(communicationUserTokenModel: communicationUserToken) { success in
                    if success {
                        self.callAgent?.handlePush(notification: incomingCallPushNotification) { error in
                            self.handlePushCompletion(error: error)
                        }
                    } else {
                        print("initCallAgent failed.\n")
                    }
                }
            } else {
                print("Missing credentials!")
            }

        }
    }
    
    /// Handle push completion for callAgent
    private func handlePushCompletion(error: Error?) {
        if let error = error {
            print("Handle push notification failed: \(error.localizedDescription)\n")
        } else {
            print("Handle push notification succeeded.\n")
        }
    }
    
    /// Get call for id
    private func getCall(callId: UUID) -> Call? {
        if let call = self.call, call.id == callId.uuidString.lowercased() {
                return call
        } else {
            return nil
        }
    }
    
    /// Get incoming call for id
    private func getIncomingCall(callId: UUID) -> IncomingCall? {
        if let call = self.incomingCall, call.id == callId.uuidString.lowercased() {
                return call
        } else {
            return nil
        }
    }
    
    /// Starts a call
    public func startCall(calleeIdentifier: String) {
        if let callAgent = self.callAgent {
            let callees: [CommunicationUserIdentifier] = [CommunicationUserIdentifier(calleeIdentifier)]
            let startCallOptions = StartCallOptions()
            
            self.getDeviceManager { _ in
                if let localVideoStream = self.localVideoStream {
                    let videoOptions = VideoOptions(localVideoStreams: [localVideoStream])
                    startCallOptions.videoOptions = videoOptions
                }
                callAgent.startCall(participants: callees, options: startCallOptions) { call, error in
                    // TODO: withVideo muss noch anders gehandlet werden
                    self.startCallCompletion(call: call, error: error, withVideo: self.hasLocalVideoStreams)
                }
                print("Outgoing call started.")
            }
        } else {
            print("callAgent not initialized.\n")
        }
    }
    
    /// Handle startCall completion for callAgent
    private func startCallCompletion(call: Call?, error: Error?, withVideo: Bool) {
        if error != nil {
            print("Failed to start call")
        } else {
            print("Successfully started call")
            self.call = call
            
            self.call?.delegate = self
            
            if withVideo {
                self.startVideo()
            }
            
            let callId = UUID(uuidString: (self.call?.id)!)
            self.delegate?.startCall(callId: callId!)
        }
    }
    
    /// Stops a call
    public func endCall() {
        if let call = self.call, let callUUID = UUID(uuidString: call.id) {
            self.delegate?.endCall(callId: callUUID)
        }
    }
    
    /// Mutes the audio in a session
    public func mute() {
        self.setMute(to: true)
    }
    
    /// Unmutes the audio in a session
    public func unmute() {
        self.setMute(to: false)
    }
    
    private func setMute(to mute: Bool) {
        if let call = self.call, let callUUID = UUID(uuidString: call.id) {
            self.delegate?.muteCall(callId: callUUID, mute: mute)
        }
    }
    
    /// Stops the video in a session
    public func stopVideo() {
        if let call = self.call, let localVideoStream = self.localVideoStream {
            call.stopVideo(stream: localVideoStream) { error in
                if let error = error {
                    print("LocalVideo failed to stop: \(error.localizedDescription)\n")
                } else {
                    print("LocalVideo stopped successfully.\n")
                    if let localVideoStreamModel = self.azureLocalVideoStreamModel {
                        self.delegate?.toggleVideoSucceeded(with: false)
                        localVideoStreamModel.renderer?.dispose()
                        localVideoStreamModel.renderer = nil
                        localVideoStreamModel.videoStreamView = nil
                    }
                }
            }
        }
    }
    
    // TODO: Sauberer und unabhängig implementieren
    func startVideo() {
        if let localVideoStreamModel = self.azureLocalVideoStreamModel, let call = self.call, let localVideoStream = self.localVideoStream {
            call.startVideo(stream: localVideoStream) { error in
                if error != nil {
                    print("LocalVideo failed to start.\n")
                } else {
                    print("LocalVideo started successfully.\n")
                    localVideoStreamModel.createView(localVideoStream: localVideoStream)
                    self.delegate?.toggleVideoSucceeded(with: true)
                }
            }
        }
    }
    
    /// Accepts an incoming call
    public func acceptIncomingCall(callId: UUID) {
        print("AcceptCall requested from CallKit.\n")
        // TODO: Warum funktioniert das?
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if let _ = self.callAgent,
               let call = self.getIncomingCall(callId: callId) {
                let acceptCallOptions = AcceptCallOptions()
                self.getDeviceManager { _ in
                    if let localVideoStream = self.localVideoStream {
                        let videoOptions = VideoOptions(localVideoStreams: [localVideoStream])
                        acceptCallOptions.videoOptions = videoOptions
                        call.accept(options: acceptCallOptions) { call, error in
                            if error == nil {
                                print("Incoming call accepted")
                                self.azureLocalVideoStreamModel?.createView(localVideoStream: localVideoStream)
                                self.delegate?.toggleVideoSucceeded(with: true)
                            } else {
                                print("Failed to accept incoming call")
                            }
                        }
                    }
                }
            } else {
                print("Call not found when trying to accept.\n")
                self.hasIncomingCall = { hasIncomingCall in
                    if hasIncomingCall == true {
                        self.acceptIncomingCall(callId: callId)
                        // TODO: Warum?
                        self.hasIncomingCall?(false)
                    }
                }
            }
        }
    }
    
    public func endCall(callId: UUID) {
        print("EndCall requested from CallKit.\n")
        if let call = self.getCall(callId: callId) {
            // TODO: Completion wird garnicht aufgerufen...
            print("endCall in AzureCallingModel")
            call.hangUp(options: HangUpOptions()) { error in
                if let error = error {
                    print("Hangup failed: \(error.localizedDescription).\n")
                } else {
                    print("Hangup succeeded.\n")
                }
            }
        } else {
            print("Call not found when trying to hangup.\n")
        }
    }
    
    public func toggleMute(callId: UUID) {
        print("MuteCall requested from CallKit.\n")
        if let call = self.getCall(callId: callId) {
            if call.isMuted {
                call.unmute(completionHandler:{ (error) in
                    if let error = error {
                        print("Failed to unmute: \(error.localizedDescription)")
                    } else {
                        print("Successfully un-muted")
                        self.delegate?.toggleMuteSucceeded(with: false)
                    }
                })
            } else {
                call.mute(completionHandler: { (error) in
                    if let error = error {
                        print("Failed to mute: \(error.localizedDescription)")
                    } else {
                        print("Successfully muted")
                        self.delegate?.toggleMuteSucceeded(with: true)
                    }
                })
            }
        } else {
            print("Call not found when trying to set mute.\n")
        }
    }
    
    private func getDeviceManager(completion: @escaping (Bool) -> Void) {
        self.callClient.getDeviceManager { deviceManager, error in
            if (error == nil) {
                print("Got device manager instance")
                self.deviceManager = deviceManager
                
                if let videoDeviceInfo: VideoDeviceInfo = deviceManager?.cameras.first {
                    self.localVideoStream = LocalVideoStream(camera: videoDeviceInfo)
                    self.azureLocalVideoStreamModel = AzureLocalVideoStreamModel(identifier: self.identifier, displayName: self.displayName)
                    print("LocalVideoStream instance initialized.")
                    completion(true)
                } else {
                    print("LocalVideoStream instance initialize failed.")
                    completion(false)
                }
            } else {
                print("Failed to get device manager instance: \(String(describing: error))")
                completion(false)
            }
        }
    }
    
    private func invalidateRemoteVideoStreamModel() {
        self.azureRemoteVideoStreamModel?.remoteParticipant?.delegate = nil
        self.azureRemoteVideoStreamModel?.renderer?.dispose()
        self.azureRemoteVideoStreamModel?.renderer = nil
        self.azureRemoteVideoStreamModel?.videoStreamView = nil
        self.azureRemoteVideoStreamModel = nil
    }
}

// MARK: - CallAgentDelegate
extension AzureCallingModel: CallAgentDelegate {
    
    // TODO: Wenn die App noch nicht gestartet ist, wird diese Delegatefunktion nicht aufgerufen und damit existiert auch kein eingehender Anruf
    public func callAgent(_ callAgent: CallAgent, didRecieveIncomingCall incomingCall: IncomingCall) {
        print("Incoming call received.")
        self.incomingCall = incomingCall
        // Subscribe to get OnCallEnded event
        self.incomingCall?.delegate = self
    }
    
    public func callAgent(_ callAgent: CallAgent, didUpdateCalls args: CallsUpdatedEventArgs) {
        print("\n---------------")
        print("onCallsUpdated")
        print("---------------\n")

        if let addedCall = args.addedCalls.first {
            print("addedCalls: \(args.addedCalls.count)")
            self.call = addedCall
            self.call?.delegate = self
            self.callState = addedCall.state
            self.isMicrophoneMuted = addedCall.isMuted
            self.hasIncomingCall?(true)
        }
        
        print("removedCalls: \(args.removedCalls.count)\n")
        if let call = self.call,
           let removedCall = args.removedCalls.first(where: {$0.id == call.id}),
           let removedCallUUID = UUID(uuidString: removedCall.id) {
            self.callState = removedCall.state
            self.call?.delegate = nil
            self.call = nil
            self.incomingCall?.delegate = nil
            self.incomingCall = nil
            
            self.delegate?.onCallEnded(callId: removedCallUUID)
        } else {
            print("removedCall: \(String(describing: args.removedCalls))")
            if let incomingCallPushNotification = self.incomingCallPushNotification {
                self.delegate?.onCallEnded(callId: incomingCallPushNotification.callId)
            }
        }
    }
}

// MARK: - IncomingCallDelegate
extension AzureCallingModel: IncomingCallDelegate {
    
    // Event raised when incoming call was not answered
    public func incomingCall(_ incomingCall: IncomingCall, didEnd args: PropertyChangedEventArgs) {
        print("Incoming call was not answered.")
        self.incomingCall = nil
    }
}

// MARK: - CallDelegate
extension AzureCallingModel: CallDelegate {
    
    public func call(_ call: Call, didChangeState args: PropertyChangedEventArgs) {
        print("\n----------------------------------")
        print("onCallStateChanged: \(String(reflecting: call.state.name))")
        print("----------------------------------\n")
        self.callState = call.state
        
        if call.state == .connected {
            if let callUUID = UUID(uuidString: call.id) {
                self.delegate?.onCallStarted(callId: callUUID)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.azureRemoteVideoStreamModel = AzureRemoteVideoStreamModel(identifier: call.id, displayName: call.callerInfo.displayName, remoteParticipant: call.remoteParticipants[0])
                }
            }
        }
        
        if call.state == .disconnected || call.state == .none {
            self.stopVideo()
            self.endCall()
            self.invalidateRemoteVideoStreamModel()
        }
    }
    
    public func call(_ call: Call, didUpdateLocalVideoStreams args: LocalVideoStreamsUpdatedEventArgs) {
        print("\n--------------------------")
        print("onLocalVideoStreamsChanged")
        print("--------------------------\n")

        print("addedStreams: \(args.addedStreams.count)")
        print("removedStreams: \(args.removedStreams.count)")
    }
    
    // TODO: Wird benötigt?
    public func call(_ call: Call, didUpdateRemoteParticipant args: ParticipantsUpdatedEventArgs) {
        print("\n---------------------------")
        print("onRemoteParticipantsUpdated")
        print("---------------------------\n")
        
        if args.addedParticipants.count > 0 {
            print("addedParticipants: \(String(describing: args.addedParticipants.count))")
            
            args.addedParticipants.forEach { (remoteParticipant) in
                if remoteParticipant.identifier is CommunicationUserIdentifier {
                    let communicationUserIdentifier = remoteParticipant.identifier as! CommunicationUserIdentifier
                    print("addedParticipant identifier:  \(String(describing: communicationUserIdentifier))")
                    print("addedParticipant displayName \(String(describing: remoteParticipant.displayName))")
                    print("addedParticipant streams \(String(describing: remoteParticipant.videoStreams.count))")
                    
                    self.azureRemoteVideoStreamModel = AzureRemoteVideoStreamModel(identifier: communicationUserIdentifier.identifier, displayName: remoteParticipant.displayName, remoteParticipant: remoteParticipant)
                }
            }
        }
        
        if args.removedParticipants.count > 0 {
            print("removedParticipants: \(String(describing: args.removedParticipants.count))")
            
            args.removedParticipants.forEach { (remoteParticipant) in
                if remoteParticipant.identifier is CommunicationUserIdentifier {
                    let communicationUserIdentifier = remoteParticipant.identifier as! CommunicationUserIdentifier
                    print("removedParticipant identifier:  \(String(describing: communicationUserIdentifier))")
                    print("removedParticipant displayName \(String(describing: remoteParticipant.displayName))")
                    
                    if self.azureRemoteVideoStreamModel?.identifier == communicationUserIdentifier.identifier {
                        self.invalidateRemoteVideoStreamModel()
                    }
                }
            }
        }
    }
}
