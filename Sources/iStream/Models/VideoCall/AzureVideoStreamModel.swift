//
//  VideoStreamModel.swift
//  iStream
//
//  Created by Conrad Felgentreff on 21.04.22.
//

import SwiftUI
import AzureCommunicationCalling

public class AzureVideoStreamModel: VideoStreamModel, Identifiable {
    
    public var identifier: String
    public var renderer: VideoStreamRenderer?

    public init(identifier: String, displayName: String) {
        self.identifier = identifier
        super.init(displayName: displayName)
    }
}
