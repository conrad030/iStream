//
//  RemoteVideoStreamModel.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 21.04.22.
//
// TODO: Problem: CallingViewModel bekommt nicht mit, wenn VideoStreamModel sich ändert.
// - Information muss irgendwie nach außen getragen werden
// - Kann StreamView selber damit umgehen? Wenn View nicht mehr da ist, muss diese Disposed werden (updateUIViewRepresentable?)

import SwiftUI
import AzureCommunicationCalling

public class AzureRemoteVideoStreamModel: AzureVideoStreamModel {
    
    @Published public var isMicrophoneMuted: Bool = false
    @Published public var scalingMode: ScalingMode = .crop

    public var remoteParticipant: RemoteParticipant?

    public init(identifier: String, displayName: String, remoteParticipant: RemoteParticipant?) {
        self.remoteParticipant = remoteParticipant
        super.init(identifier: identifier, displayName: displayName)
        self.remoteParticipant!.delegate = self
        self.isMicrophoneMuted = false
        self.checkStream()
    }

    public func checkStream() {
        if let remoteParticipant = self.remoteParticipant {
            if remoteParticipant.videoStreams.count > 0 && self.videoStreamView == nil {
                self.addStream(remoteVideoStream: remoteParticipant.videoStreams.first!)
            }
        }
    }

    private func addStream(remoteVideoStream: RemoteVideoStream) {
        do {
            let renderer = try VideoStreamRenderer(remoteVideoStream: remoteVideoStream)
            self.renderer = renderer
            self.videoStreamView = VideoStreamView(view: (try renderer.createView()))
            print("Remote VideoStreamView started!")
        } catch {
            print("Failed starting VideoStreamView for \(String(describing: displayName)) : \(error.localizedDescription)")
        }
    }

    private func removeStream(stream: RemoteVideoStream?) {
        if stream != nil {
            self.renderer?.dispose()
            self.renderer = nil
            self.videoStreamView = nil
            print("Removed remote VideoStreamView.")
        }
    }
}

extension AzureRemoteVideoStreamModel: RemoteParticipantDelegate {
    
    public func remoteParticipant(_ remoteParticipant: RemoteParticipant, didChangeState args: PropertyChangedEventArgs) {
        print("\n-------------------------")
        print("onParticipantStateChanged")
        print("-------------------------\n")

        if remoteParticipant.identifier is CommunicationUserIdentifier {
            let remoteParticipantIdentity = remoteParticipant.identifier as! CommunicationUserIdentifier
            print("RemoteParticipant identifier:  \(String(describing: remoteParticipantIdentity.identifier))")
            print("RemoteParticipant displayName \(String(describing: remoteParticipant.displayName))")
        } else {
            print("remoteParticipant.identity: UnknownIdentifier")
        }
    }
    
    public func remoteParticipant(_ remoteParticipant: RemoteParticipant, didChangeSpeakingState args: PropertyChangedEventArgs) {
        print("\n-------------------")
        print("onIsSpeakingChanged")
        print("-------------------\n")
        print("remoteParticipant.isSpeaking: \(remoteParticipant.isSpeaking)")
    }
    
    public func remoteParticipant(_ remoteParticipant: RemoteParticipant, didUpdateVideoStreams args: RemoteVideoStreamsEventArgs) {
        print("\n---------------------")
        print("onVideoStreamsUpdated")
        print("---------------------\n")
        
        print("RemoteParticipant identifier:  \(String(describing: remoteParticipant.identifier))")
        print("RemoteParticipant displayName \(String(describing: remoteParticipant.displayName))")
        
        print("addedStreams: \(args.addedRemoteVideoStreams.count)")
        if let stream = args.addedRemoteVideoStreams.first {
            self.addStream(remoteVideoStream: stream)
        }
        
        print("RemovedStreams: \(args.removedRemoteVideoStreams.count)")
        if let stream = args.removedRemoteVideoStreams.first {
            self.removeStream(stream: stream)
        }
    }
    
    public func remoteParticipant(_ remoteParticipant: RemoteParticipant, didChangeMuteState args: PropertyChangedEventArgs) {
        print("\n----------------")
        print("onIsMutedChanged")
        print("----------------\n")
        self.isMicrophoneMuted = remoteParticipant.isMuted
        print("remoteParticipant.isMuted: \(remoteParticipant.isMuted)")
    }
}
