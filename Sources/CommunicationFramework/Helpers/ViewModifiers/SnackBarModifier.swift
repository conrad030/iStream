//
//  SnackBar.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 06.06.22.
//

import SwiftUI

struct SnackBarModifier: ViewModifier {
    
    @ObservedObject var snackBarViewModel: SnackBarViewModel
    
    func body(content: Content) -> some View {
        
        ZStack {
            
            content
            
            VStack {
                
                Spacer()
                
                if self.snackBarViewModel.show {
                    
                    SnackBarView(message: self.snackBarViewModel.message)
                        .onTapGesture {
                            self.snackBarViewModel.hide()
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
    }
    
    struct SnackBarView: View {
        
        var message: String
    
        var body: some View {
            
            VStack(alignment: .leading) {
                Text(self.message)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.black)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 5)
            .padding()
        }
    }
}
