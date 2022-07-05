//
//  CallController.swift
//  iStream
//
//  Created by Conrad Felgentreff on 22.04.22.
//

import CallKit

public class CallController: NSObject {
    
    public static let shared: CallController = CallController()
    private let callController = CXCallController()
    
    override private init() {
        super.init()
    }

    // MARK: - Actions

    /// Starts a new call with the specified handle and indication if the call includes video.
    /// - Parameters:
    ///   - callId: The CallId to start a call.
    ///   - handle: The caller's phone number.
    ///   - isVideo: Indicates if the call includes video.
    ///   - completionHandler: completionHandler callback.
    public func startCall(callId: UUID, handle: String, isVideo: Bool = false, completionHandler: @escaping (Error?) -> Void) {
        let handle = CXHandle(type: .generic, value: handle)
        let startCallAction = CXStartCallAction(call: callId, handle: handle)
        startCallAction.isVideo = isVideo
        requestTransaction(startCallAction, completionHandler: completionHandler)
    }

    /// Ends the specified call.
    /// - Parameters:
    ///   - callId: The callId to end.
    ///   - completionHandler: completionHandler callback.
    public func endCall(callId: UUID, completionHandler: @escaping (Error?) -> Void) {
        let endCallAction = CXEndCallAction(call: callId)
        requestTransaction(endCallAction, completionHandler: completionHandler)
    }

    /// Sets the specified call muted.
    /// - Parameters:
    ///   - callId:The callId to set muted..
    ///   - muted: Specifies whether the call should be muted.
    ///   - completionHandler: completionHandler callback.
    public func setMutedCall(callId: UUID, muted: Bool, completionHandler: @escaping (Error?) -> Void) {
        let muteCallAction = CXSetMutedCallAction(call: callId, muted: muted)
        self.requestTransaction(muteCallAction, completionHandler: completionHandler)
    }

    // TODO: Manchmal error beim Hangup... (The operation couldn’t be completed. (com.apple.CallKit.error.requesttransaction error 4.))
    /// Requests that the actions in the specified transaction be asynchronously performed by the telephony provider.
    /// - Parameters:
    ///   - action: CXAction
    ///   - completionHandler: completionHandler callback.
    private func requestTransaction(_ action: CXAction, completionHandler: @escaping (Error?) -> Void) {
        callController.requestTransaction(with: action) { error in
            if let error = error {
                print("Error requesting transaction: \(error.localizedDescription)\n")
                completionHandler(error)
            } else {
                print("Requested transaction successfully.\n")
                completionHandler(nil)
            }
        }
    }
}
