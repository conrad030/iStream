//
//  CallingViewModelTests.swift
//  iStreamTests
//
//  Created by Conrad Felgentreff on 10.06.22.
//

import XCTest
import PushKit
@testable import iStream

class CallingViewModelTests: XCTestCase {
    var sut: CallingViewModel!
    var mock = MockCallingModel()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        self.sut = CallingViewModel(callingModel: self.mock)
    }
    
    override func tearDownWithError() throws {
        self.sut = nil
        try super.tearDownWithError()
    }
    
    private func initSutForCall() {
        self.sut.initCallingViewModel(identifier: UUID().uuidString, displayName: "Test User", token: UUID().uuidString)
    }
    
    private func startCall() {
        self.sut.startCall(identifier: UUID().uuidString)
    }
    
    func testStartCall() {
        self.initSutForCall()
        self.sut.startCall(identifier: UUID().uuidString)
        XCTAssertTrue(self.mock.startCallCalled, "startCall function from CallingModel not called")
        XCTAssertNotNil(self.mock.callId, "call ID in mock is nil")
        XCTAssertTrue(self.sut.localeVideoIsOn, "Video in sut is not on")
        XCTAssertTrue(self.sut.presentCallView, "CallView should be visible")
    }
    
    func testEndCall() {
        self.initSutForCall()
        self.startCall()
        self.sut.endCall()
        XCTAssertTrue(self.mock.endCallCalled, "endCall function from CallingModel not called")
        XCTAssertFalse(self.sut.presentCallView, "Call should have ended")
    }
    
    func testEndNotExistingCall() {
        self.initSutForCall()
        //Is set to true to check if mock calls the delegate functions from sut
        self.sut.presentCallView = true
        self.sut.endCall()
        XCTAssertTrue(self.mock.endCallCalled, "endCall function from CallingModel not called")
        XCTAssertTrue(self.sut.presentCallView, "Delegate functions got called")
    }
    
    func testSetVoipToken() {
        self.initSutForCall()
        let token = UUID().uuidString.data(using: .utf8)
        self.sut.setVoipToken(token: token)
        XCTAssertEqual(token, self.mock.voipToken, "Token not set in model")
    }
    
    func testToggleVideo() {
        self.initSutForCall()
        self.startCall()
        XCTAssertTrue(self.sut.localeVideoIsOn, "Video in sut is not on")
        self.sut.toggleVideo()
        XCTAssertTrue(self.mock.stopVideoCalled, "stopVideo function from CallingModel not called")
        XCTAssertFalse(self.sut.localeVideoIsOn, "Video in sut is on")
        self.sut.toggleVideo()
        XCTAssertTrue(self.mock.startVideoCalled, "startVideo function from CallingModel not called")
        XCTAssertTrue(self.sut.localeVideoIsOn, "Video in sut is not on")
    }
    
    func testToggleMute() {
        self.initSutForCall()
        self.startCall()
        XCTAssertFalse(self.sut.isMuted, "sut is muted")
        self.sut.toggleMute()
        XCTAssertTrue(self.mock.muteCalled, "mute function in mock not called")
        XCTAssertTrue(self.sut.isMuted, "sut is not muted")
        self.sut.toggleMute()
        XCTAssertTrue(self.mock.unmuteCalled, "unmute function in mock not called")
        XCTAssertFalse(self.sut.isMuted, "sut is still muted")
    }
}
