//
//  FileStorageModel.swift
//  iStream
//
//  Created by Conrad Felgentreff on 04.05.22.
//
// MARK: Inspired by https://docs.amplify.aws/lib/storage/getting-started/q/platform/ios/#uploading-data-to-your-bucket

import Foundation
import Combine
import Amplify
import AmplifyPlugins

public class AmplifyFileStorage {
    
    private var resultSink: AnyCancellable?
    private var progressSink: AnyCancellable?
    
    public init() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            try Amplify.configure()
            print("Amplify configured with storage plugin")
        } catch {
            print("Failed to initialize Amplify with \(error)")
        }
    }
}

extension AmplifyFileStorage: FileStorage {
    
    /// Upload file to a S3 Bucket
    public func uploadFile(key: String, data: Data, completion: @escaping (String?, Error?) -> Void) {
        let storageOperation = Amplify.Storage.uploadData(key: key, data: data)
        self.progressSink = storageOperation
            .progressPublisher
            .sink { progress in print("Progress: \(progress)") }
        
        self.resultSink = storageOperation
            .resultPublisher
            .sink {
                if case let .failure(storageError) = $0 {
                    print("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                    completion(nil, storageError)
                }
            }
            receiveValue: { data in
                print("Completed: \(data)")
                completion(key, nil)
            }
    }
    
    /// Get  file to a S3 Bucket
    public func getFile(for id: String, completion: @escaping (Data?, Error?) -> Void) {
        let storageOperation = Amplify.Storage.downloadData(key: id)
        self.progressSink = storageOperation.progressPublisher.sink { progress in print("Progress: \(progress)") }
        self.resultSink = storageOperation.resultPublisher.sink(receiveCompletion: {
            if case let .failure(storageError) = $0 {
                print("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                completion(nil, storageError)
            }
        }, receiveValue: { data in
            print("Completed download: \(data)")
            completion(data, nil)
        })
    }
    
    /// Delete file to a S3 Bucket
    public func deleteFile(for id: String, completion: @escaping (String?, Error?) -> Void) {
        self.resultSink = Amplify.Storage.remove(key: id).resultPublisher.sink(receiveCompletion: {
            if case let .failure(storageError) = $0 {
                print("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                completion(nil, storageError)
            }
        }, receiveValue: { data in
            print("Completed: Deleted \(data)")
            completion(data, nil)
        })
    }
}
