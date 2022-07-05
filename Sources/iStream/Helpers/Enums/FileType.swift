//
//  FileType.swift
//  iStream
//
//  Created by Conrad Felgentreff on 09.05.22.
//

import Foundation

public enum FileType: String {
    case jpg = "jpg"
    case pdf = "pdf"
    
    public static func getTypeForString(string: String) -> FileType? {
        switch string {
        case "jpg": return .jpg
        case "pdf": return .pdf
        default: return nil
        }
    }
}
