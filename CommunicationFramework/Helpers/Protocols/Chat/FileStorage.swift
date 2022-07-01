//
//  FileStorage.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 30.05.22.
//

import Foundation

public protocol FileStorage {
    func uploadFile(key: String, data: Data, completion: @escaping (String?, Error?) -> Void)
    func getFile(for id: String, completion: @escaping (Data?, Error?) -> Void)
    func deleteFile(for id: String, completion: @escaping (String?, Error?) -> Void)
}
