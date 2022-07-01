//
//  PDFFile.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 09.05.22.
//

import SwiftUI
import UniformTypeIdentifiers

struct PDFFile: FileDocument, FileRepresentable {
    
    var data: Data {
        if let data = self.innerData {
            return data
        } else {
            guard url.startAccessingSecurityScopedResource() else { return Data() }
            defer { url.stopAccessingSecurityScopedResource() }
            return try! Data(contentsOf: self.url)
        }
    }
    var view: AnyView {
        AnyView(
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
    
    var storedName: String?
    
    var name: String {
        self.storedName ?? self.url.lastPathComponent
    }
    
    var fileType: FileType {
        .pdf
    }
    
    static var readableContentTypes: [UTType]{[.pdf]}
    
    private var innerData: Data?
    private var storedUrl: URL?
    private var id = UUID()
    
    private var url: URL {
        get {
            if let storedUrl = self.storedUrl {
                return storedUrl
            } else {
                let fileManager = FileManager.default
                let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
                let cachesDirectoryUrl = urls[0]
                return cachesDirectoryUrl.appendingPathComponent("File-\(self.id.uuidString).pdf")
            }
        }
        set {
            self.storedUrl = newValue
        }
    }
    
    init(data: Data) {
        self.innerData = data
        //Store file in cache and return url
        let fileManager = FileManager.default
        fileManager.createFile(atPath: self.url.path, contents: data)
    }
    
    init(url: URL) {
        self.url = url
    }
    
    init(configuration: ReadConfiguration) throws {
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try FileWrapper(url: self.url, options: .immediate)
    }
}
