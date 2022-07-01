//
//  ChatMessageReadReceipt.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 27.05.22.
//

import AzureCommunicationChat

extension ChatMessageReadReceipt: ReadReceiptResponse {
    public var messageId: String {
        self.chatMessageId
    }
}
