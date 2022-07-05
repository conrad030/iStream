//
//  ChatViewModelTests.swift
//  iStreamTests
//
//  Created by Conrad Felgentreff on 10.06.22.
//

import XCTest
import CoreData
@testable import iStream

class ChatViewModelTests: XCTestCase {
    
    var sut: ChatViewModel!
    var mock: MockChatModel = MockChatModel()
    lazy var testContext: NSManagedObjectContext = {
        let modelURL = Bundle(for: ChatViewModel.self).url(forResource: "ChatStore", withExtension: "momd")
        let model = modelURL.flatMap(NSManagedObjectModel.init)!
        
        let container = NSPersistentContainer(name: "ChatStore", managedObjectModel: model)
        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null"))]
        container.loadPersistentStores { description, error in
            XCTAssertNil(error)
        }
        return container.newBackgroundContext()
    }()
    var senderIdentifier = UUID().uuidString
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        self.sut = ChatViewModel(chatModel: self.mock, context: self.testContext)
    }
    
    override func tearDownWithError() throws {
        self.sut = nil
        try super.tearDownWithError()
    }
    
    private func initSutForChat() {
        self.sut.initChatViewModel(identifier: UUID().uuidString, displayName: "Test User", endpoint: "https:://www.testendpoint.com", token: UUID().uuidString)
    }
    
    private func getNewChatMessage(withPdfFile: Bool = false) -> ChatMessage {
        let message = ChatMessage(context: self.testContext)
        message.id = UUID()
        message.senderIdentifier = self.senderIdentifier
        message.message = "test"
        message.status = .sent
        if withPdfFile {
            message.file = self.getNewPdf()
        }
        return message
    }
    
    private func getNewPdf() -> File {
        let file = File(context: self.testContext)
        file.id = UUID()
        file.name = "testFile"
        file.type = .pdf
        let bundle = Bundle(for: ChatViewModelTests.self)
        file.data = NSDataAsset(name: "TestPdfData", bundle: bundle)!.data
        return file
    }
    
    func testSetup() {
        XCTAssertEqual(self.sut.chatMessages.count, 0, "Chat messages from Viewmodel are not empty")
        XCTAssertEqual(self.sut.chatIsSetup, false, "Chat is setup before being initialized")
        XCTAssertEqual(self.sut.chatPartnerName, nil, "Chatpartnername should be nil before Viewmodel is initialized")
        XCTAssertEqual(self.sut.loadedMessages, false, "loadedMessages is true before Viewmodel is initialized")
    }
    
    /// Can only be tested in local database
    func testSendMessage() {
        self.initSutForChat()
        let text = "test"
        self.sut.sendMessage(text: text, fileRepresentable: nil)
        XCTAssertEqual(self.sut.chatMessages.count, 1, "Sent chat message is not included in Viewmodels chat messages")
        XCTAssertEqual(self.sut.chatMessages.last!.message, text, "Text of chat message in Viewmodel is wrong")
        XCTAssertNil(self.sut.chatMessages.last!.file, "File is not nil")
    }
    
    func testSendMessageWithImage() {
        self.initSutForChat()
        let bundle = Bundle(for: ChatViewModelTests.self)
        let image = UIImage(named: "TestImage", in: bundle, with: .none)!
        let text = "imageTest"
        self.sut.sendMessage(text: text, fileRepresentable: image)
        XCTAssertEqual(self.sut.chatMessages.count, 1, "Sent chat message is not included in Viewmodels chat messages")
        XCTAssertEqual(self.sut.chatMessages.last!.message, text, "Text of chat message in Viewmodel is wrong")
        XCTAssertNotNil(self.sut.chatMessages.last!.file, "File is nil")
        XCTAssertEqual(self.sut.chatMessages.last!.file!.name, image.name, "Text of chat message in Viewmodel is wrong")
        XCTAssertEqual(self.sut.chatMessages.last!.file!.type, image.fileType, "Text of chat message in Viewmodel is wrong")
        XCTAssertEqual(self.sut.chatMessages.last!.file!.data, image.data, "Text of chat message in Viewmodel is wrong")
    }
    
    func testSendMessageWithPdf() {
        self.initSutForChat()
        let bundle = Bundle(for: ChatViewModelTests.self)
        let pdfFile = PDFFile(data: NSDataAsset(name: "TestPdfData", bundle: bundle)!.data)
        let text = "pdfTest"
        self.sut.sendMessage(text: text, fileRepresentable: pdfFile)
        XCTAssertEqual(self.sut.chatMessages.count, 1, "Sent chat message is not included in Viewmodels chat messages")
        XCTAssertEqual(self.sut.chatMessages.last!.message, text, "Text of chat message in Viewmodel is wrong")
        XCTAssertNotNil(self.sut.chatMessages.last!.file, "File is nil")
        XCTAssertEqual(self.sut.chatMessages.last!.file!.name, pdfFile.name, "Text of chat message in Viewmodel is wrong")
        XCTAssertEqual(self.sut.chatMessages.last!.file!.type, pdfFile.fileType, "Text of chat message in Viewmodel is wrong")
        XCTAssertEqual(self.sut.chatMessages.last!.file!.data, pdfFile.data, "Text of chat message in Viewmodel is wrong")
    }
    
    func testDeleteMessageLocally() {
        self.initSutForChat()
        let text = "test"
        self.sut.sendMessage(text: text, fileRepresentable: nil)
        self.sut.deleteMessageLocally(message: self.sut.chatMessages.first!)
        XCTAssertEqual(self.sut.chatMessages.count, 0, "Messages of Viewmodel should be empty")
    }
    
    func testDeleteReadMessageRemote() {
        self.initSutForChat()
        let message = self.getNewChatMessage()
        self.sut.deleteMessageForAll(message: message) { success in
            XCTAssertTrue(success, "Message couldn't be deleted")
        }
    }
    
    func testDeleteReadMessage() {
        self.initSutForChat()
        let message = self.getNewChatMessage()
        message.status = .read
        self.sut.deleteMessageForAll(message: message) { success in
            XCTAssertFalse(success, "Message was deleted for everyone, although it's status is read")
        }
    }
}
