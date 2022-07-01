//
//  MessageView.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 29.04.22.
//

import SwiftUI

struct MessageView: View {
    
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var snackBarViewModel: SnackBarViewModel
    
    @ObservedObject var chatMessage: ChatMessage
    private var isOwnMessage: Bool {
        self.chatMessage.senderIdentifier == self.chatViewModel.identifier
    }
    private var isLastOwnReadMessage: Bool {
        let ownReadMessages = self.chatViewModel.chatMessages.filter { $0.senderIdentifier == self.chatViewModel.identifier && $0.status == .read && !$0.isInvalidated }
        return ownReadMessages.last?.id == self.chatMessage.id
    }
    private let cornerRadius: CGFloat = 15
    @State private var showFileExporter = false
    @State private var showSaveSuccessAlert = false
    @State private var showSaveErrorAlert = false
    @State private var showDeleteLocalAlert = false
    @State private var showDeleteForAllAlert = false
    
    private var messageView: some View {
        
        VStack(spacing: 10) {
            
            if let file = self.chatMessage.file {
                
                ZStack {
                    
                    if let data = file.data {
                        
                        Text("")
                            .fileExporter(isPresented: self.$showFileExporter, document: PDFFile(data: data), contentType: .pdf) { result in
                                switch result {
                                case .success:
                                    self.showSaveSuccessAlert = true
                                case .failure(let error):
                                    print("Error while trying to save pdf file: \(error.localizedDescription)")
                                    self.showSaveErrorAlert = true
                                }
                            }
                    }
                    
                    Button {
                        self.showFileExporter = true
                    } label: {
                        file.view
                    }
                    .frame(width: 200)
                    .disabled(file.type == .jpg || file.data == nil)
                }
            }
            
            HStack(spacing: 15) {
                
                Text(self.chatMessage.message ?? "")
                    .font(.system(size: 17))
                
                Text(self.chatMessage.createdOn.timeString)
                    .font(.system(size: 13))
                    .opacity(0.5)
            }
        }
    }
    
    private var readView: some View {

        Text("Gelesen")
            .foregroundColor(.gray)
            .font(.system(size: 15))
    }
    
    private var deletedMessageView: some View {
        
        Text("\(Image(systemName: "nosign")) Diese Nachricht wurde gelöscht.")
            .italic()
            .font(.system(size: 17))
            .opacity(0.35)
    }
    
    var body: some View {
        
        ZStack {
            
            Text("")
                .alert(Text("Erfolgreich heruntergeladen"), isPresented: self.$showSaveSuccessAlert) {
                    Button("Ok", role: .cancel) { }
                }
            
            Text("")
                .alert(Text("Fehler"), isPresented: self.$showSaveErrorAlert, actions: {
                    Button("Ok", role: .cancel) { }
                }) {
                    Text("Beim herunterladen ist ein Fehler aufgetreten.")
                }
            
            Text("")
                .alert(Text("Nachricht löschen?"), isPresented: self.$showDeleteLocalAlert, actions: {
                    
                    Button(role: .destructive) {
                        self.chatViewModel.deleteMessageLocally(message: self.chatMessage)
                    } label: {
                        Text("Löschen")
                    }
                    
                    Button(role: .cancel) {
                    } label: {
                        Text("Abbrechen")
                    }
                }) {
                    Text("Die Nachricht wird unwiderruflich für dich gelöscht.")
                }
            
            Text("")
                .alert(Text("Nachricht löschen?"), isPresented: self.$showDeleteForAllAlert, actions: {
                    
                    Button(role: .destructive) {
                        self.chatViewModel.deleteMessageForAll(message: self.chatMessage) { success in
                            if !success {
                                self.snackBarViewModel.showMessage(message: "Nachricht konnte nicht gelöscht werden.")
                            }
                        }
                    } label: {
                        Text("Löschen")
                    }
                    
                    Button(role: .cancel) {
                    } label: {
                        Text("Abbrechen")
                    }
                }) {
                    Text("Die Nachricht wird unwiderruflich für alle gelöscht.")
                }
            
            HStack {
                
                if self.isOwnMessage {
                    
                    Spacer(minLength: 0)
                }
                
                VStack(alignment: .trailing, spacing: 3) {
                    
                    ZStack {
                        
                        if !self.chatMessage.isInvalidated {
                            
                            self.messageView
                        } else {
                            
                            self.deletedMessageView
                        }
                    }
                    .padding(10)
                    .foregroundColor(self.isOwnMessage ? .black : .white)
                    .background(
                        RoundedCorners(color: self.isOwnMessage ? Color(.systemGray4) : .blue, tl: self.cornerRadius, tr: self.cornerRadius, bl: self.isOwnMessage ? self.cornerRadius : 0, br: self.isOwnMessage ? 0 : self.cornerRadius)
                            .shadow(radius: 3)
                    )
                    .opacity(self.isOwnMessage && self.chatMessage.status == .pending ? 0.5 : 1)
                    .disabled(self.isOwnMessage && self.chatMessage.status == .pending)
                    .contextMenu {
                        
                        Button(role: .destructive) {
                            self.showDeleteLocalAlert = true
                        } label: {
                            Label("Für mich löschen", systemImage: "trash")
                        }
                        
                        if self.isOwnMessage && self.chatMessage.status != .read {
                            
                            Button(role: .destructive) {
                                self.showDeleteForAllAlert = true
                            } label: {
                                Text("Für alle löschen")
                            }
                        }
                    }
                    
                    if self.isLastOwnReadMessage {
                        
                        self.readView
                    }
                }
                
                if !self.isOwnMessage {
                    
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(chatMessage: ChatMessage())
    }
}
