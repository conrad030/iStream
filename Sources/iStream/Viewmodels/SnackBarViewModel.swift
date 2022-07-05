//
//  SnackBarViewModel.swift
//  iStream
//
//  Created by Conrad Felgentreff on 06.06.22.
//

import SwiftUI

public class SnackBarViewModel: ObservableObject {
    
    @Published private(set) var show = false
    @Published private(set) var message = ""
    
    public func showMessage(message: String, duration: Double = 2) {
        self.message = message
        withAnimation {
            self.show = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.hide()
        }
    }
    
    public func hide() {
        withAnimation {
            self.show = false
        }
        self.message = ""
    }
}
