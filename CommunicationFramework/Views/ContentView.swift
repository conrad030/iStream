//
//  ContentView.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 21.04.22.
//

// MARK: Stellvertretend für Client. Wird später noch ausgelagert.

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var callingViewModel: CallingViewModel
    @EnvironmentObject var chatViewModel: ChatViewModel
    
    @State private var presentCallView = false
    @State private var presentChatView = false
    @State private var showChatLoadingIndicator = false
    
    var body: some View {
        
        NavigationView {
            
            VStack(spacing: 20) {
                
                NavigationLink(destination: ChatView().environmentObject(self.chatViewModel), isActive: self.$presentChatView) {
                    Text("")
                }
                
                Button {
                    // iPhone 12: 8:acs:7d8a86e0-5ac4-4d37-a9dd-dabf0f99e29b_00000011-00ed-af4e-65f0-ad3a0d000130
                    // iPhone 6s: 8:acs:7d8a86e0-5ac4-4d37-a9dd-dabf0f99e29b_00000011-00b5-7de7-59fe-ad3a0d00fee0
                    self.callingViewModel.startCall(identifier: "8:acs:7d8a86e0-5ac4-4d37-a9dd-dabf0f99e29b_00000011-00b5-7de7-59fe-ad3a0d00fee0")
                } label: {
                    
                    Text("Start call")
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 15).foregroundColor(.blue))
                }
                .fullScreenCover(isPresented: self.$presentCallView) {
                    
                    CallView()
                        .environmentObject(self.callingViewModel)
                }
                .disabled(!self.callingViewModel.enableCallButton)
                .opacity(self.callingViewModel.enableCallButton ? 1 : 0.5)
                
                Button {
                    self.showChatLoadingIndicator = true
                    self.chatViewModel.startChat(with: "8:acs:7d8a86e0-5ac4-4d37-a9dd-dabf0f99e29b_00000011-00b5-7de7-59fe-ad3a0d00fee0", partnerDisplayName: "Conrad iPhone 6s")
                } label: {
                    
                    ZStack {
                        
                        if self.showChatLoadingIndicator {
                            
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            
                            Text("Start chat")
                                .bold()
                                .foregroundColor(.white)
                        }
                    }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 15).foregroundColor(.green))
                }
                .disabled(!self.chatViewModel.initFinished)
                .opacity(self.chatViewModel.initFinished ? 1 : 0.5)
            }
            .navigationBarTitle("Communication Framework", displayMode: .inline)
        }
        .onReceive(self.callingViewModel.$presentCallView) {
            self.presentCallView = $0
        }
        .onReceive(self.chatViewModel.$chatIsSetup) {
            if $0 {
                DispatchQueue.main.async {
                    self.presentChatView = true
                    self.showChatLoadingIndicator = false
                }
            }
        }
        .onAppear {
            /// Get identifier and token from Server
            let domain = getPlistInfo(resourceName: "Info", key: "DOMAIN")
            let endpoint = getPlistInfo(resourceName: "Info", key: "ENDPOINT")
            let query = getPlistInfo(resourceName: "Info", key: "QUERY")
            
            let defaults = UserDefaults.standard
            var urlString = domain + endpoint
            // If there is an existing identifier, refresh token instead of creating a new identity
            if let identifier = defaults.string(forKey: "identifier") {
                urlString += query + identifier
            }
            let url = URL(string: urlString)!
            var request = URLRequest(url: url)
            request.setValue(getPlistInfo(resourceName: "Info", key: "API_KEY"), forHTTPHeaderField: "API-Key")
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error with fetching credentials: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Error with the response, unexpected status code: \(String(describing: response))")
                    return
                }
                
                if let data = data {
                    do {
                        guard let credentials = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else { return print("Couldn't decode credentials from data") }
                        let displayName = "Conrad"
                        let token = credentials["token"]!
                        let identifier = credentials["identifier"]!
                        let endpoint = getPlistInfo(resourceName: "Info", key: "ACSENDPOINT")
                        // Store identifier in user defaults
                        defaults.set(identifier, forKey: "identifier")
                        /// Init user token credentials
                        DispatchQueue.main.async {
                            self.callingViewModel.initCallingViewModel(identifier: identifier, displayName: displayName, token: token)
                            self.chatViewModel.initChatViewModel(identifier: identifier, displayName: displayName, endpoint: endpoint, token: token)
                        }
                    } catch {
                        print("There was an error while trying to decode credentials: \(error.localizedDescription)")
                    }
                }
            }
            task.resume()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        ContentView()
            .environmentObject(CallingViewModel(callingModel: AzureCallingModel()))
            .environmentObject(ChatViewModel(chatModel: AzureChatModel()))
    }
}
