//
//  StreamView.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 02.06.22.
//

import SwiftUI

struct StreamView: View {
    
    @ObservedObject var videoStreamModel: VideoStreamModel
    
    var body: some View {
        
        ZStack {
            
            if let videoStreamView = self.videoStreamModel.videoStreamView {
                
                videoStreamView
            } else {
                
                Rectangle()
                    .foregroundColor(.black)
                    .edgesIgnoringSafeArea(.all)
                
                Text("Video is disabled")
                    .foregroundColor(.white)
            }
            
            VStack {
                
                HStack {
                    
                    Spacer()
                    
                    Text(self.videoStreamModel.displayName)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    
                    Image(systemName: "speaker.wave.2")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .padding()
                    
                    Spacer()
                }
                .padding(.top, 30)
                
                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

//struct StreamView_Previews: PreviewProvider {
//    static var previews: some View {
//        StreamView()
//    }
//}
