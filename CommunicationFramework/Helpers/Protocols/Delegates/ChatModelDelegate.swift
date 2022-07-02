//
//  ChatModelDelegate.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 27.05.22.
//

import Foundation

public protocol ChatModelDelegate {
    func handleChatMessageReceived(event: ReceivedChatMessageResponse)
    func handleReadReceipt(event: ReadReceiptResponse)
    func handleGetThreadMessages(items: [ReceivedChatMessageResponse])
    func sendReadReceipts()
    func handleChatMessageStati(items: [ReadReceiptResponse])
    func invalidateMessage(with messageId: String)
    func modelSetupFinished()
}
