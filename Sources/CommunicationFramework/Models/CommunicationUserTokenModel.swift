//
//  CommunicationUserTokenModel.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 21.04.22.
//

import Foundation

public struct CommunicationUserTokenModel: Codable {

    public var token: String
    public var communicationUserId: String
    public var displayName: String
}
