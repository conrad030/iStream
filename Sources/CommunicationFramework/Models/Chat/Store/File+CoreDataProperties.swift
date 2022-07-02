//
//  File+CoreDataProperties.swift
//
//
//  Created by Conrad Felgentreff on 16.05.22.
//
//

import Foundation
import CoreData
import SwiftUI

extension File {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<File> {
        return NSFetchRequest<File>(entityName: "File")
    }

    @NSManaged private var id_: UUID?
    @NSManaged private var type_: String?
    @NSManaged private var name_: String?
    @NSManaged public var data: Data?
    @NSManaged private var message_: ChatMessage?
    
    public var id: UUID {
        get {
            if self.id_ == nil {
                self.id_ = UUID()
            }
            return self.id_!
        }
        set {
            self.id_ = newValue
        }
    }
    
    public var type: FileType {
        get {
            FileType.getTypeForString(string: self.type_ ?? "") ?? .pdf
        }
        set {
            self.type_ = newValue.rawValue
        }
    }
    
    public var name: String {
        get {
            self.name_ ?? ""
        }
        set {
            self.name_ = newValue
        }
    }
    
    public var view: AnyView {
        if let data = self.data {
            switch self.type {
            case .jpg:
                return AnyView(
                    Image(uiImage: UIImage(data: data) ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                )
            case .pdf:
                return AnyView(
                    Text(self.name)
                        .bold()
                        .font(.system(size: 16))
                        .lineLimit(2)
                        .foregroundColor(.blue)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .foregroundColor(.white)
                        )
                        .clipped()
                )
            }
        } else {
            return AnyView(
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            )
        }
    }
    
    public var message: ChatMessage {
        self.message_ ?? ChatMessage()
    }
}
