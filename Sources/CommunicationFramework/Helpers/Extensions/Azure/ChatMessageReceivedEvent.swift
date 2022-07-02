//
//  File.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 26.05.22.
//

import AzureCommunicationChat
import AzureCommunicationCommon

extension ChatMessageReceivedEvent: ReceivedChatMessageResponse {
    
    public var messageId: String? {
        self.metadata?["messageId"] ?? nil
    }
    
    public var senderIdentifier: String? {
        let sender = self.sender as? CommunicationUserIdentifier
        return sender?.identifier
    }
    
    public var text: String? {
        self.message
    }
    
    public var chatMessageId: String {
        self.id
    }
    
    public var createdAt: Date? {
        self.createdOn?.value
    }
    
    public var fileId: String? {
        self.metadata?["fileId"] ?? nil
    }
    
    public var fileType: String? {
        self.metadata?["type"] ?? nil
    }
    
    public var fileName: String? {
        self.metadata?["fileName"] ?? nil
    }
}
