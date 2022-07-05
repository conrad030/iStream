//
//  UIImage.swift
//  iStream
//
//  Created by Conrad Felgentreff on 05.05.22.
//

import SwiftUI

extension UIImage: FileRepresentable {
    
    public var view: AnyView {
        AnyView(
            Image(uiImage: self)
                .resizable()
                .aspectRatio(contentMode: .fit)
        )
    }
    public var data: Data {
        for i in 0..<10 {
            guard let data = self.jpegData(compressionQuality: CGFloat(1) - CGFloat(i) / 10) else { break }
            //Has to be smaller than 16 MB
            if Double(data.count) / 1024 / 1024 < 16 {
                return data
            }
        }
        return Data()
    }
    public var name: String {
        "ChatImage.jpeg"
    }
    public var fileType: FileType {
        .jpg
    }
}
