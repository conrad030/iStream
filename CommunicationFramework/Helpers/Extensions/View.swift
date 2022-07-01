//
//  View.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 06.06.22.
//

import SwiftUI

extension View {
    
    func snackBar(snackBarViewModel: SnackBarViewModel) -> some View {
        self.modifier(SnackBarModifier(snackBarViewModel: snackBarViewModel))
    }
}
