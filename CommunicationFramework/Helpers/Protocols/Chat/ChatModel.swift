//
//  ChatModel.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 26.05.22.
//

import Foundation

protocol ChatModel {
    var delegate: ChatModelDelegate? { get set }
    var threadId: String? { get }
    var completedMessageFetch: Bool { get }
    func initChatModel(endpoint: String, identifier: String, token: String, displayName: String) throws
    func startRealTimeNotifications()
    func startChat(partnerIdentifier: String, partnerDisplayName: String)
    func getThreadMessages()
    func sendReadReceipt(for messageId: String)
    func sendMessage(message: ChatMessage, completion: @escaping (String) -> Void)
    func deleteMessage(messageId: String, completion: @escaping (Bool) -> Void)
    func invalidate()
}
