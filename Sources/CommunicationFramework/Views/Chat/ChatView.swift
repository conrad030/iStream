//
//  ChatView.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 29.04.22.
//

import SwiftUI

public struct ChatView: View {
    
    @EnvironmentObject var chatViewModel: ChatViewModel
    @StateObject var snackBarViewModel = SnackBarViewModel()
    
    @State private var message = ""
    private var dates: [Date] {
        var dates: [Date] = []
        for message in self.chatViewModel.chatMessages {
            if !dates.contains(where: { $0.isSameDay(as: message.createdOn) }) {
                print(message.createdOn)
                dates.append(message.createdOn)
            }
        }
        return dates.sorted { $0.compare($1) == .orderedAscending }
    }
    @State private var showActionSheet = false
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var inputImage: UIImage?
    @State private var openFileImporter = false
    @State private var pdfFile: PDFFile?
    private var file: FileRepresentable? {
        if let image = self.inputImage {
            return image
        } else if let pdf = self.pdfFile {
            return pdf
        }
        return nil
    }
    
    public init() {}
    
    public var body: some View {
        
        VStack(spacing: 0) {
            
            if self.chatViewModel.loadedMessages {
                
                ScrollView {
                    
                    ScrollViewReader { value in
                        
                        VStack(spacing: 10) {
                            
                            ForEach(self.dates, id: \.self) { date in
                                
                                Divider()
                                    .padding(.top)
                                
                                Text(date.dateString)
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(.systemGray2))
                                
                                ForEach(self.chatViewModel.chatMessages.filter { $0.createdOn.isSameDay(as: date) }.sorted { $0.createdOn.compare($1.createdOn) == .orderedAscending }) { message in
                                    
                                    MessageView(chatMessage: message)
                                        .id(message.id)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .onChange(of: self.chatViewModel.chatMessages.count) { _ in
                            withAnimation {
                                value.scrollTo(self.chatViewModel.chatMessages.sorted { $0.createdOn.compare($1.createdOn) == .orderedAscending }.last?.id)
                            }
                        }
                        .onAppear {
                            value.scrollTo(self.chatViewModel.chatMessages.sorted { $0.createdOn.compare($1.createdOn) == .orderedAscending }.last?.id)
                        }
                    }
                }
            } else {
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            VStack(spacing: 0) {
                
                if let file = self.file {
                    
                    ZStack {
                        
                        file.view
                            .shadow(radius: 5)
                            .padding(.horizontal, 30)
                        
                        HStack {
                            
                            Spacer(minLength: 0)
                            
                            Button {
                                self.inputImage = nil
                                self.pdfFile = nil
                                HapticsManager.shared.standardVibration()
                            } label: {
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 25))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    .frame(height: 150)
                }
                
                HStack(spacing: 15) {
                    
                    Button {
                        self.showActionSheet = true
                    } label: {
                        
                        Image(systemName: "plus")
                            .font(.system(size: 25))
                            .foregroundColor(.blue)
                    }
                    
                    TextField("Schreibe eine Nachricht...", text: self.$message)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 10).foregroundColor(Color(.white)))
                    
                    if !self.message.isEmpty || self.file != nil {

                        Button {
                            self.chatViewModel.sendMessage(text: self.message.trimmingCharacters(in: .whitespacesAndNewlines), fileRepresentable: self.file)
                            self.message = ""
                            self.inputImage = nil
                            self.pdfFile = nil
                        } label: {
                            
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 35))
                                .rotationEffect(Angle(degrees: 45))
                                .foregroundColor(.blue)
                        }
                        .zIndex(1)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .frame(height: 40)
                .padding()
            }
            .animation(.easeInOut(duration: 0.2))
            .background(
                Color(.systemGray6)
                    .shadow(radius: 5)
                    .edgesIgnoringSafeArea(.bottom)
                    .animation(.easeInOut(duration: 0.2))
            )
        }
        .background(Color(.white))
        .snackBar(snackBarViewModel: self.snackBarViewModel)
        .confirmationDialog("", isPresented: self.$showActionSheet, titleVisibility: .hidden) {
            Button("Kamera") {
                self.sourceType = .camera
                self.showImagePicker = true
            }
            Button("Fotomediathek") {
                self.sourceType = .photoLibrary
                self.showImagePicker = true
            }
            Button("Dokument") {
                self.openFileImporter = true
            }
            Button("Abbrechen", role: .cancel) {
            }
        }
        .fullScreenCover(isPresented: self.$showImagePicker, onDismiss: {
            if self.inputImage != nil {
                self.pdfFile = nil
            }
        }) {
            ImagePicker(image: self.$inputImage, sourceType: self.sourceType)
                .edgesIgnoringSafeArea(.all)
        }
        .fileImporter(isPresented: self.$openFileImporter, allowedContentTypes: [.pdf]) { res in
            self.inputImage = nil
            do {
                self.pdfFile = PDFFile(url: try res.get())
            } catch {
                print("Error: \(error.localizedDescription)")
            }
            self.openFileImporter = false
        }
        .navigationBarTitle("Chat mit \(self.chatViewModel.chatPartnerName ?? "")", displayMode: .inline)
        .onAppear {
            UIScrollView.appearance().keyboardDismissMode = .onDrag
        }
        .onDisappear {
            UIScrollView.appearance().keyboardDismissMode = .interactive
            self.chatViewModel.leaveChat()
        }
        .environmentObject(self.snackBarViewModel)
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
            .environmentObject(ChatViewModel(chatModel: AzureChatModel()))
    }
}
