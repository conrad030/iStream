//
//  Encodable.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 05.05.22.
//

import Foundation

extension Encodable {
    var stringDict: [String: String]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else { return nil }
        return json
    }
}
