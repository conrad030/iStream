//
//  FileRepresentable.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 05.05.22.
//

import SwiftUI

public protocol FileRepresentable {
    
    var view: AnyView { get }
    var data: Data { get }
    var name: String { get }
    var fileType: FileType { get }
}
