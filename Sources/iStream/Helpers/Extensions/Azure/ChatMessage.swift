//
//  ChatMessage.swift
//  iStream
//
//  Created by Conrad Felgentreff on 27.05.22.
//

import AzureCommunicationChat
import AzureCommunicationCommon

extension AzureCommunicationChat.ChatMessage: ReceivedChatMessageResponse {
    public var messageId: String? {
        self.metadata?["messageId"] ?? nil
    }
    
    public var senderIdentifier: String? {
        let sender = self.sender as? CommunicationUserIdentifier
        return sender?.identifier
    }
    
    public var text: String? {
        self.content?.message
    }
    
    public var chatMessageId: String {
        self.id
    }
    
    public var createdAt: Date? {
        self.createdOn.value
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
