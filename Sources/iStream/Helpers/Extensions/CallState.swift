//
//  CallState.swift
//  iStream
//
//  Created by Conrad Felgentreff on 22.04.22.
//

import AzureCommunicationCalling

extension CallState {
    var name: String {
        switch self {
        case .none: return "None" // 0
        case .earlyMedia: return "EarlyMedia" // 1
        case .connecting: return "Connecting" // 3
        case .ringing: return "Ringing" // 4
        case .connected: return "Connected" // 5
        case .localHold: return "Hold" // 6
        case .disconnecting: return "Disconnecting" // 7
        case .disconnected: return "Disconnected" // 8
        default: return "Unknown"
        }
    }
}
