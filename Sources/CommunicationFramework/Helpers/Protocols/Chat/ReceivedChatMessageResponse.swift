//
//  File.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 26.05.22.
//

import Foundation

public protocol ReceivedChatMessageResponse {
    var messageId: String? { get }
    var senderIdentifier: String? { get }
    var text: String? { get }
    var chatMessageId: String { get }
    var createdAt: Date? { get }
    var fileId: String? { get }
    var fileType: String? { get }
    var fileName: String? { get }
}
