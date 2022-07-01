//
//  ChatMessage+CoreDataProperties.swift
//
//
//  Created by Conrad Felgentreff on 16.05.22.
//
//

import Foundation
import CoreData

extension ChatMessage: Identifiable {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatMessage> {
        return NSFetchRequest<ChatMessage>(entityName: "ChatMessage")
    }

    @NSManaged private var id_: UUID?
    @NSManaged public var message: String?
    @NSManaged public var createdOn_: Date?
    @NSManaged public var file: File?
    @NSManaged private var senderIdentifier_: String?
    @NSManaged public var chatMessageId: String?
    @NSManaged public var isInvalidated: Bool
    @NSManaged private var status_: Int16
    
    public var id: UUID {
        get {
            if self.id_ == nil {
                self.id_ = UUID()
            }
            return self.id_!
        }
        set {
            self.id_ = newValue
        }
    }
    
    public var createdOn: Date {
        get {
            self.createdOn_ ?? Date()
        }
        set {
            self.createdOn_ = Date()
        }
    }
    
    public var senderIdentifier: String {
        get {
            self.senderIdentifier_ ?? ""
        }
        set {
            self.senderIdentifier_ = newValue
        }
    }
    
    var status: ChatMessageStatus {
        get {
            ChatMessageStatus(rawValue: self.status_) ?? .pending
        }
        set {
            self.status_ = newValue.rawValue
        }
    }
}
