//
//  ChatViewModel.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 27.04.22.
//

import SwiftUI
import Combine
import AzureCommunicationCommon
import AzureCommunicationChat
import CoreData

public class ChatViewModel: NSObject, ObservableObject {
    
    @Published private var chatModel: ChatModel
    private var anyCancellable: AnyCancellable? = nil
    
    private var fileStorageModel: FileStorage = AmplifyFileStorage()
    
    private var context: NSManagedObjectContext
    @Published public var chatMessages: [ChatMessage] = [] {
        didSet {
            self.setFileDataForMessages()
        }
    }
    @Published public var chatIsSetup = false
    @Published private(set) var identifier: String?
    @Published private(set) var displayName: String?
    @Published private(set) var chatPartnerName: String?
    public var loadedMessages: Bool {
        return self.chatModel.completedMessageFetch
    }
    @Published private(set) var initFinished = false
    
    init<Model: ChatModel & ObservableObject>(chatModel: Model, context: NSManagedObjectContext? = nil) {
        self.chatModel = chatModel
        if let context = context {
            self.context = context
        } else {
            let container = NSPersistentContainer(name: "ChatStore")
            container.loadPersistentStores { description, error in
                if let error = error {
                    print("Core Data failed to load: \(error.localizedDescription)")
                }
            }
            self.context = container.viewContext
        }
        super.init()
        self.chatMessages = self.readData()
        self.chatModel.delegate = self
        /// Has to be linked to AnyCancellable, so changes of the ObservableObject are getting detected
        self.anyCancellable = chatModel.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        _ = HapticsManager.shared
    }
    
    private func readData() -> [ChatMessage] {
        let fetchRequest: NSFetchRequest<ChatMessage> = ChatMessage.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ChatMessage.createdOn_, ascending: true)]
        do {
            let messages = try self.context.fetch(fetchRequest)
            return messages
        } catch let error as NSError {
            print("Error fetching chat messages: \(error.localizedDescription), \(error.userInfo)")
            return []
        }
    }
    
    public func initChatViewModel(identifier: String, displayName: String, endpoint: String, token: String) {
        self.identifier = identifier
        self.displayName = displayName
        if !endpoint.isEmpty && !identifier.isEmpty && !token.isEmpty {
            do {
                try self.chatModel.initChatModel(endpoint: endpoint, identifier: identifier, token: token, displayName: displayName)
                self.initFinished = true
            } catch {
                print("ChatClient couldn't be initialized. Error: \(error.localizedDescription)")
            }
            self.startRealTimeNotifications()
        } else {
            print("ChatModel couldn't be initialized. Credentials are missing.")
        }
    }
    
    private func startRealTimeNotifications() {
        self.chatModel.startRealTimeNotifications()
    }
    
    public func startChat(with identifier: String, partnerDisplayName: String) {
        if self.identifier?.isEmpty ?? true || self.displayName?.isEmpty ?? true {
            print("Identifier and/or displayname are missing. Couldn't initialize chat model.")
        } else {
            self.chatPartnerName = displayName
            self.chatModel.startChat(partnerIdentifier: identifier, partnerDisplayName: partnerDisplayName)
        }
    }
    
    private func setFileDataForMessages() {
        let semaphore = DispatchSemaphore(value: 1)
        for message in self.chatMessages {
            if let file = message.file, file.data == nil {
                semaphore.wait()
                self.downloadFileData(file: file) {
                    DispatchQueue.main.async {
                        message.objectWillChange.send()
                    }
                    semaphore.signal()
                }
            }
        }
    }
    
    private func downloadFileData(file: File, completion: @escaping () -> Void) {
        self.fileStorageModel.getFile(for: file.id.uuidString) { data, error in
            if let error = error {
                print("An error accured while downloading file: \(error.localizedDescription)")
            } else if let data = data {
                DispatchQueue.main.async {
                    file.data = data
                    try? self.context.save()
                    withAnimation {
                        self.chatMessages = self.readData()
                    }
                }
            }
            completion()
        }
    }
    
    /// Send a message in a thread
    public func sendMessage(text: String, fileRepresentable: FileRepresentable?) {
        
        if let identifier = self.identifier {
            if text.isEmpty && fileRepresentable == nil { return }
            
            let chatMessage = ChatMessage(context: self.context)
            chatMessage.id = UUID()
            chatMessage.senderIdentifier = identifier
            chatMessage.message = !text.isEmpty ? text : nil
            chatMessage.createdOn = Date()
            if let fileRepresentable = fileRepresentable {
                let file = File(context: self.context)
                file.id = UUID()
                file.name = fileRepresentable.name
                file.type = fileRepresentable.fileType
                file.data = fileRepresentable.data
                chatMessage.file = file
            }
            withAnimation {
                self.save(message: chatMessage)
            }
            
            if let fileRepresentable = fileRepresentable {
                self.uploadFile(id: chatMessage.file!.id, fileRepresentable: fileRepresentable) { success in
                    if success {
                        self.chatModel.sendMessage(message: chatMessage) { messageId in
                            self.setChatMessageId(for: chatMessage, id: messageId)
                        }
                    } else {
                        print("File couldn't be uploaded.")
                    }
                }
            } else {
                self.chatModel.sendMessage(message: chatMessage) { messageId in
                    self.setChatMessageId(for: chatMessage, id: messageId)
                }
            }
        } else {
            print("Identifier in ChatViewModel is unset.")
        }
    }
    
    private func setChatMessageId(for chatMessage: ChatMessage, id: String) {
        chatMessage.chatMessageId = id
        withAnimation {
            chatMessage.status = .sent
            chatMessage.objectWillChange.send()
        }
        try? self.context.save()
    }
    
    private func uploadFile(id: UUID, fileRepresentable: FileRepresentable, completion: @escaping (Bool) -> Void) {
        self.fileStorageModel.uploadFile(key: id.uuidString, data: fileRepresentable.data) { id, error in
            if let error = error {
                print("Error occured while uploading file: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    public func deleteMessageLocally(message: ChatMessage) {
        if let messageId = message.chatMessageId {
            withAnimation {
                self.chatMessages.removeAll { $0.chatMessageId == messageId }
            }
            try? self.context.save()
        } else {
            print("message doesn't have a chatMessageId.")
        }
    }
    
    public func deleteMessageForAll(message: ChatMessage, completion: @escaping (Bool) -> Void) {
        if message.status == .read {
            return completion(false)
        }
        
        if let messageId = message.chatMessageId {
            self.chatModel.deleteMessage(messageId: messageId) { success in
                return completion(success)
            }
        }
    }
    
    private func save(message: ChatMessage) {
        withAnimation {
            self.chatMessages.append(message)
        }
        try? self.context.save()
    }
    
    public func leaveChat() {
        self.chatModel.invalidate()
    }
}

// MARK: ChatModelDelegate methods
extension ChatViewModel: ChatModelDelegate {
    
    public func handleChatMessageReceived(event: ReceivedChatMessageResponse) {
        /// Only add message if sender is the chat partner
        if let senderIdentifier = event.senderIdentifier, senderIdentifier != self.identifier {
            if let id = event.messageId, !self.chatMessages.contains(where: { $0.id.uuidString == id }) {
                withAnimation {
                    let chatMessage = ChatMessage(context: self.context)
                    chatMessage.id = UUID(uuidString: id) ?? UUID()
                    chatMessage.senderIdentifier = senderIdentifier
                    chatMessage.message = event.text
                    chatMessage.createdOn = event.createdAt ?? Date()
                    chatMessage.chatMessageId = event.chatMessageId
                    if let id = event.fileId, let typeString = event.fileType, let type = FileType.getTypeForString(string: typeString), let fileName = event.fileName {
                        let file = File(context: self.context)
                        file.id = UUID(uuidString: id) ?? UUID()
                        file.name = fileName
                        file.type = type
                        chatMessage.file = file
                        self.downloadFileData(file: file) {
                            DispatchQueue.main.async {
                                chatMessage.objectWillChange.send()
                            }
                        }
                    }
                    self.save(message: chatMessage)
                    self.chatModel.sendReadReceipt(for: event.chatMessageId)
                }
            }
        }
    }
    
    public func handleReadReceipt(event: ReadReceiptResponse) {
        let ownMessages = self.chatMessages.filter { message in message.senderIdentifier == self.identifier }
        for (index, message) in ownMessages.reversed().enumerated() {
            
            if message.chatMessageId == event.messageId {
                withAnimation {
                    message.status = .read
                    message.objectWillChange.send()
                }
                
                // Setze so lange folgende eigene Nachrichten auf read, bis eine gefunden wurde die bereits gesetzt wurde
                if index + 1 <= ownMessages.count - 1 {
                    for message in ownMessages.reversed()[index + 1...ownMessages.count - 1] {
                        if message.status == .read { break }
                        withAnimation {
                            message.status = .read
                            message.objectWillChange.send()
                        }
                    }
                }
                try? self.context.save()
                break
            }
        }
        if let message = self.chatMessages.first(where: { $0.chatMessageId == event.messageId }) {
            withAnimation {
                message.status = .read
                message.objectWillChange.send()
            }
            try? self.context.save()
        }
    }
    
    public func handleGetThreadMessages(items: [ReceivedChatMessageResponse]) {
        for item in items {
            if let id = item.messageId, !self.chatMessages.contains(where: { $0.id.uuidString == id }), let senderIdentifier = item.senderIdentifier {
                let chatMessage = ChatMessage(context: self.context)
                chatMessage.id = UUID(uuidString: id) ?? UUID()
                chatMessage.chatMessageId = item.chatMessageId
                chatMessage.senderIdentifier = senderIdentifier
                chatMessage.message = item.text
                chatMessage.createdOn = item.createdAt ?? Date()
                if let id = item.fileId, let typeString = item.fileType, let type = FileType.getTypeForString(string: typeString), let fileName = item.fileName {
                    let file = File(context: self.context)
                    file.id = UUID(uuidString: id) ?? UUID()
                    file.name = fileName
                    file.type = type
                    chatMessage.file = file
                }
                self.save(message: chatMessage)
            }
        }
    }
    
    // TODO: Nicht schön. Diese Methode wird direkt nach handleGetThreadMessages in AzureChatModel aufgerufen... Lässt sich bestimmt irgendwie zusamenfassen.
    public func sendReadReceipts() {
        if let message = self.chatMessages.filter({ $0.senderIdentifier != self.identifier && $0.status != .read }).last, let messageId = message.chatMessageId {
            self.chatModel.sendReadReceipt(for: messageId)
        }
    }
    
    public func handleChatMessageStati(items: [ReadReceiptResponse]) {
        var messageFound = false
        for message in self.chatMessages.reversed().filter({ message in message.senderIdentifier == self.identifier }) {
            // Wenn eine Nachricht gefunden wurde, die bereits gelesen wurde, ist klar, dass alle Nachfolger auch schon gelesen sein müssen und die Schleife kann abgebrochen werden
            if message.status == .read { break }
            // Wenn messageFound noch false ist, dann muss geprüft werden, ab welcher eigenen Nachricht es eine Lesebestätigung gibt. Wenn eine gefunden wurde, wird messageFound auf true gesetzt, damit diese Prüfung für alle Nachfolger nicht mehr nötig ist.
            // Wenn messageFound schon true ist, muss nicht mehr geprüft werden, ob es Lesebestätigungen für die letzten Nachrichten gibt und diese und alle folgenden Nachrichten können sofort als gelesen markiert werden
            if messageFound || items.contains(where: { $0.messageId == message.chatMessageId }) {
                withAnimation {
                    message.status = .read
                    message.objectWillChange.send()
                }
                messageFound = true
            }
        }
        try? self.context.save()
    }
    
    public func invalidateMessage(with messageId: String) {
        if let message = self.chatMessages.first(where: { $0.chatMessageId == messageId }) {
            message.isInvalidated = true
            if let  file = message.file {
                self.fileStorageModel.deleteFile(for: file.id.uuidString) { id, error in
                    if let error = error {
                        print("Error while deleting file: \(error.localizedDescription)")
                    } else if let id = id {
                        print("File with id \(id) successfully deleted.")
                    }
                }
                self.context.delete(file)
            }
            withAnimation {
                try? self.context.save()
            }
        }
    }
    
    public func modelSetupFinished() {
        self.chatIsSetup = true
    }
}
