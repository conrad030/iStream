//
//  CallView.swift
//  iStream
//
//  Created by Conrad Felgentreff on 21.04.22.
//

import SwiftUI
import Combine

public struct CallView<VideoContent: View, SpeakerContent: View, HangupContent: View>: View {
    
    @EnvironmentObject var callingViewModel: CallingViewModel
    private var videoButtonLabel: VideoContent
    private var speakerButtonLabel: SpeakerContent
    private var hangupButtonLabel: HangupContent
    
    public init(@ViewBuilder videoButtonLabel: @escaping () -> VideoContent, @ViewBuilder speakerButtonLabel: @escaping () -> SpeakerContent, @ViewBuilder hangupButtonLabel: @escaping () -> HangupContent) {
        self.videoButtonLabel = videoButtonLabel()
        self.speakerButtonLabel = speakerButtonLabel()
        self.hangupButtonLabel = hangupButtonLabel()
    }
    
    public var body: some View {
        
        GeometryReader { outerGeometry in
            
            ZStack {
                
                if let videoStreamModel = self.callingViewModel.remoteVideoStreamModel {
                    
                    StreamView(videoStreamModel: videoStreamModel)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: outerGeometry.size.width, height: outerGeometry.size.height)
                } else {
                    
                    Rectangle()
                        .edgesIgnoringSafeArea(.all)
                }
                VStack {
                    
                    GeometryReader { geometry in
                        
                        if let localVideoView = self.callingViewModel.localVideoStreamModel?.videoStreamView {
                            
                            localVideoView
                                .cornerRadius(16)
                                .frame(width: geometry.size.width / 3, height: geometry.size.height / 3)
                                .padding([.top, .leading], 30)
                        } else {
                            
                            Rectangle()
                                .cornerRadius(16)
                                .frame(width: geometry.size.width / 3, height: geometry.size.height / 3)
                                .padding([.top, .leading], 30)
                        }
                    }
                    
                    Spacer()
                    
                    HStack {
                        
                        Button {
                            self.callingViewModel.toggleVideo()
                        } label: {
                                HStack {
                                    
                                    Spacer()
                                    
                                    if self.videoButtonLabel is EmptyView {
                                        
                                        if self.callingViewModel.localVideoStreamModel?.videoStreamView != nil {
                                            Image(systemName: "video")
                                                .padding()
                                        } else {
                                            Image(systemName: "video.slash")
                                                .padding()
                                        }
                                    } else {
                                        
                                        self.videoButtonLabel
                                    }
                                    
                                    Spacer()
                                }
                        }
                        
                        Button {
                            self.callingViewModel.toggleMute()
                        } label: {
                            
                            HStack {
                                
                                Spacer()
                                
                                if self.speakerButtonLabel is EmptyView {
                                    
                                    if self.callingViewModel.isMuted {
                                        
                                        Image(systemName: "speaker.slash")
                                            .padding()
                                    } else {
                                        
                                        Image(systemName: "speaker.wave.2")
                                            .padding()
                                    }
                                } else {
                                    
                                    self.speakerButtonLabel
                                }
                                
                                Spacer()
                            }
                        }
                        
                        Button {
                            self.callingViewModel.endCall()
                        } label: {
                            
                            HStack {
                                
                                Spacer()
                                
                                if self.hangupButtonLabel is EmptyView {
                                    
                                    Image(systemName: "phone.down")
                                        .foregroundColor(.red)
                                        .padding()
                                } else {
                                    
                                    self.hangupButtonLabel
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
                .font(.largeTitle)
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

struct CallView_Previews: PreviewProvider {
    static var previews: some View {
        CallView()
            .environmentObject(CallingViewModel(callingModel: AzureCallingModel()))
    }
}

extension CallView where VideoContent == EmptyView, SpeakerContent == EmptyView, HangupContent == EmptyView  {
    public init() {
        self.init(videoButtonLabel: { EmptyView() }, speakerButtonLabel: { EmptyView() }, hangupButtonLabel: { EmptyView() })
    }
}
