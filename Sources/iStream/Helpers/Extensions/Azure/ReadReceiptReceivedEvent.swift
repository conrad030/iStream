//
//  ReadReceiptReceivedEvent.swift
//  iStream
//
//  Created by Conrad Felgentreff on 27.05.22.
//

import AzureCommunicationChat

extension ReadReceiptReceivedEvent: ReadReceiptResponse {
    public var messageId: String {
        self.chatMessageId
    }
}
