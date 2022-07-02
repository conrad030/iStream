//
//  PushRegistryDelegate.swift
//  CommunicationFramework
//
//  Created by Conrad Felgentreff on 22.04.22.
//

// MARK: To handle incoming push notifications

import PushKit

public class PushRegistryDelegate: NSObject {
    public static let shared: PushRegistryDelegate = PushRegistryDelegate()
    private let pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
    
    var setVoipToken: ((Data) -> Void)?
    
    var handlePushNotification: ((PKPushPayload) -> Void)?

    private override init() {
        super.init()
        ProviderDelegate.shared.configureProvider()
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
    }
}

extension PushRegistryDelegate: PKPushRegistryDelegate {
    
    /// Set the voip token when receiving it via push notification
    public func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        self.setVoipToken?(pushCredentials.token)
    }

    public func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("pushRegistry invalidated: \(type)\n")
    }

    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        if type == .voIP {
            let outterDictionary = payload.dictionaryPayload as? [String: Any]
            let dictionary = outterDictionary?["data"] as? [String: Any]
            guard let callId = dictionary?["callId"] as? String else { print("String \"callId\" in dictionaryPayload not found or type is wrong."); return }
            guard let handle = dictionary?["displayName"] as? String else { print("String \"displayName\" in dictionaryPayload not found or type is wrong."); return }
            guard let hasVideoString = dictionary?["videoCall"] as? String else { print("String \"videoCall\" in dictionaryPayload not found or type is wrong."); return }
            let hasVideo = hasVideoString == "true"
            
            ProviderDelegate.shared.reportNewIncomingCall(callId: UUID(uuidString: callId)!, handle: handle, hasVideo: hasVideo) { error in
                if let error = error {
                    print("reportNewIncomingCall failed: \(error.localizedDescription)\n")
                } else {
                    print("reportNewIncomingCall was successful.\n")
                }
                completion()
                
                self.handlePushNotification?(payload)
            }
        }
    }
}
