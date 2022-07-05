//
//  VideoStreamModel.swift
//  iStream
//
//  Created by Conrad Felgentreff on 03.06.22.
//

import SwiftUI

public class VideoStreamModel: NSObject, ObservableObject {
    
    public var displayName: String
    @Published var videoStreamView: VideoStreamView?
    
    public init(displayName: String) {
        self.displayName = displayName
    }
}
