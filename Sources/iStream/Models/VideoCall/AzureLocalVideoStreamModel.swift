//
//  LocalVideoStreamModel.swift
//  iStream
//
//  Created by Conrad Felgentreff on 21.04.22.
//

import SwiftUI
import AzureCommunicationCalling

public class AzureLocalVideoStreamModel: AzureVideoStreamModel {
    
    public func createView(localVideoStream: LocalVideoStream?) {
        do {
            if let localVideoStream = localVideoStream {
                let renderer = try VideoStreamRenderer(localVideoStream: localVideoStream)
                self.renderer = renderer
                self.videoStreamView = VideoStreamView(view: (try renderer.createView()))
            }
        } catch {
            print("Failed starting VideoStreamView for \(String(describing: displayName)) : \(error.localizedDescription)")
        }
    }
}

