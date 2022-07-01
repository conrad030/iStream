//
//  CommunicationUserTokenModel.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 21.04.22.
//

import Foundation

public struct CommunicationUserTokenModel: Codable {

    public var token: String?
    public var expiresOn: Date?
    public var communicationUserId: String?
    public var displayName: String?

    public init(token: String? = nil, expiresOn: Date? = nil, communicationUserId: String? = nil, displayName: String? = nil) {
        self.token = token
        self.expiresOn = expiresOn
        self.communicationUserId = communicationUserId
        self.displayName = displayName
    }

}
