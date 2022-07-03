//
//  AzureChatModel.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 26.05.22.
//

import SwiftUI
import AzureCommunicationCommon
import AzureCommunicationChat
import CoreText

public class AzureChatModel: ObservableObject, ChatModel {
    
    public var delegate: ChatModelDelegate?
    
    private var displayName: String = ""
    private var identifier: String = ""
    private var token: String = ""
    
    private var chatClient: ChatClient?
    private var chatThreadClient: ChatThreadClient? {
        didSet {
            self.getThreadMessages()
        }
    }
    
    private var hasChatThreadClient: Bool {
        self.chatThreadClient != nil
    }
    
    @Published public var threadId: String? {
        didSet {
            self.delegate?.modelSetupFinished()
            if let threadId = self.threadId {
                do {
                    self.chatThreadClient = try self.chatClient?.createClient(forThread: threadId)
                } catch {
                    print("ChatThreadClient couldn't be initialized.")
                }
            }
        }
    }
    
    @Published public var completedMessageFetch = false
    
    public init() {}
    
    public func initChatModel(endpoint: String, identifier: String, token: String, displayName: String) throws {
        self.displayName = displayName
        self.identifier = identifier
        self.token = token
        
        /// Create chat client
        let credentialOptions = CommunicationTokenRefreshOptions(initialToken: self.token, tokenRefresher: { result in
            print("Refreshed token.")
        })
        let credential = try CommunicationTokenCredential(withOptions: credentialOptions)
        let options = AzureCommunicationChatClientOptions()
        self.chatClient = try ChatClient(endpoint: endpoint, credential: credential, withOptions: options)
    }
    
    public func startRealTimeNotifications() {
        /// Receive chat messages
        self.chatClient?.startRealTimeNotifications { result in
            switch result {
            case .success:
                print("Real-time notifications started.")
            case .failure:
                print("Failed to start real-time notifications.")
            }
        }
        
        self.chatClient?.register(event: .chatMessageReceived) { response in
            switch response {
            case let .chatMessageReceivedEvent(event):
                DispatchQueue.main.async {
                    self.delegate?.handleChatMessageReceived(event: event)
                    return
                }
            default:
                return
            }
        }
        self.chatClient?.register(event: .readReceiptReceived) { response in
            switch(response) {
            case let .readReceiptReceived(event):
                DispatchQueue.main.async {
                    self.delegate?.handleReadReceipt(event: event)
                    return
                }
            default:
                return
            }
        }
    }
    
    public func startChat(partnerIdentifier: String, partnerDisplayName: String) {
        self.initThread(partnerIdentifier: partnerIdentifier, partnerDisplayName: partnerDisplayName)
    }
    
    // TODO: Manchmal falsche Reihenfolge
    public func getThreadMessages() {
        let options = ListChatMessagesOptions(maxPageSize: 200)
        self.chatThreadClient?.listMessages(withOptions: options) { result, _ in
            switch result {
            case let .success(listMessagesResponse):
                if let items = listMessagesResponse.items {
                    self.delegate?.handleGetThreadMessages(items: items.sorted(by: { $0.createdOn.value.compare($1.createdOn.value) == .orderedAscending }))
                    
                    self.completedMessageFetch = true
                    self.delegate?.sendReadReceipts()
                    self.updateMessageStati()
                    
                    return
                }
            case let .failure(error):
                print("Error while listing messages: \(error.localizedDescription)")
            }
        }
    }
    
    public func sendReadReceipt(for messageId: String) {
        if let chatThreadClient = chatThreadClient {
            chatThreadClient.sendReadReceipt(forMessage: messageId) { result, _ in
                switch result {
                case .success:
                    print("Read receipt was send for message with id \(messageId)")
                case let .failure(error):
                    print("Error while sending read receipt for message with id \(messageId): \(error.localizedDescription)")
                }
            }
        }
    }
    
    public func sendMessage(message: ChatMessage, completion: @escaping (String) -> Void) {
        var metadata: [String: String] = ["messageId": message.id.uuidString]
        if let file = message.file {
            metadata["fileId"] = file.id.uuidString
            metadata["type"] = file.type.rawValue
            metadata["fileName"] = file.name
        }
        
        let messageRequest = SendChatMessageRequest(
            content: message.message ?? "",
            senderDisplayName: self.displayName,
            type: .text,
            metadata: metadata
        )
        
        self.chatThreadClient!.send(message: messageRequest) { result, _ in
            switch result {
            case let .success(result):
                return completion(result.id)
            case .failure:
                print("Failed to send message")
            }
        }
    }
    
    public func deleteMessage(messageId: String, completion: @escaping (Bool) -> Void) {
        self.chatThreadClient?.delete(message: messageId) { result, response in
            switch result {
            case .success:
                self.delegate?.invalidateMessage(with: messageId)
                return completion(true)
            case let .failure(error):
                print("Error while trying to delete a file \(error.localizedDescription)")
                return completion(false)
            }
        }
    }
    
    public func invalidate() {
        self.chatThreadClient = nil
    }
    
    private func updateMessageStati() {
        if let chatThreadClient = self.chatThreadClient {
            chatThreadClient.listReadReceipts() { result, _ in
                switch result {
                case let .success(readReceipts):
                    if let items = readReceipts.items {
                        self.delegate?.handleChatMessageStati(items: items)
                        return
                    }
                case let .failure(error):
                    print("Error while fetching read receipts: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func initThread(partnerIdentifier: String, partnerDisplayName: String) {
        self.getActiveThread { chatThreadItem in
            if let chatThreadItem = chatThreadItem {
                self.threadId = chatThreadItem.id
                self.addParticipant(partnerIdentifier: partnerIdentifier, partnerDisplayName: partnerDisplayName)
            } else {
                
                let request = CreateChatThreadRequest(
                    topic: "Quickstart",
                    participants: [
                        ChatParticipant(
                            id: CommunicationUserIdentifier(self.identifier),
                            displayName: self.displayName
                        )
                    ]
                )
                
                self.chatClient?.create(thread: request) { result, _ in
                    switch result {
                    case let .success(result):
                        self.threadId = result.chatThread?.id
                        self.addParticipant(partnerIdentifier: partnerIdentifier, partnerDisplayName: partnerDisplayName)
                    case .failure:
                        fatalError("Failed to create thread.")
                    }
                }
            }
        }
    }
    
    private func getActiveThread(completion: @escaping (ChatThreadItem?) -> Void) {
        self.chatClient?.listThreads { result, _ in
            switch result {
            case let .success(threads):
                guard let chatThreadItems = threads.pageItems else {
                    print("No threads returned.")
                    return
                }
                
                return completion(chatThreadItems.first)
            case .failure:
                print("Failed to list threads")
                return completion(nil)
            }
        }
    }
    
    private func addParticipant(partnerIdentifier: String, partnerDisplayName: String) {
        self.getParticipants { participants in
            let id = CommunicationUserIdentifier(partnerIdentifier)
            if let participants = participants, participants.contains(where: { ($0.id as? CommunicationUserIdentifier)?.identifier ?? "" == id.identifier }) {
                /// participant already exists
                print("Participant already exists.")
            } else {
                /// Add participant
                let user = ChatParticipant(
                    id: id,
                    displayName: partnerDisplayName
                )

                self.chatThreadClient?.add(participants: [user]) { result, _ in
                    switch result {
                    case let .success(result):
                        result.invalidParticipants == nil ? print("Added participant") : print("Error while adding participant")
                    case .failure:
                        print("Failed to add the participant")
                    }
                }
            }
        }
    }
    
    private func getParticipants(completion: @escaping ([ChatParticipant]?) -> Void) {
        self.chatThreadClient?.listParticipants { result, _ in
            switch result {
            case let .success(participantsResult):
                guard let participants = participantsResult.pageItems else {
                    print("No participants returned.")
                    return completion(nil)
                }
                return completion(participants)
            case .failure:
                print("Failed to list participants")
                completion(nil)
            }
        }
    }
}
