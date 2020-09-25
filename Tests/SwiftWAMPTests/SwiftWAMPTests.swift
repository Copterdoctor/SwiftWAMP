import XCTest
@testable import SwiftWAMP

func createTestSession(_ delegate: WampSessionDelegate) {
    let url = URL(string: "ws://localhost:8080/ws")!
    let transport = WampSocket(wsEndpoint: url)
    let s = WampSession(realm: "realm1", transport: transport, authmethods: ["anonymous"])
    s.delegate = delegate
    s.connect()
}

class CrossbarRouterTest: XCTestCase, WampSessionDelegate {
    var exp: XCTestExpectation!
    var failexp: XCTestExpectation!
    var didConnect: Bool!
    
    func wampSessionConnected(_ session: WampSession, sessionId: Int) {
        XCTAssertTrue(session.isConnected())
        self.exp.fulfill()
        session.disconnect()
    }
    
    func testConnectToCrossbar() {
        createTestSession(self)
        self.exp = expectation(description: "Should connect successfully")
        wait(for: [self.exp], timeout: 20.0)
    }
    
    func testConnectWrongRealmToCrossbar() {
        let url = URL(string: "ws://localhost:8080/ws")!
        let transport = WampSocket(wsEndpoint: url)
        let s = WampSession(realm: "realm2", transport: transport, authmethods: ["anonymous"])
        s.delegate = self
        s.connect()
        self.failexp = expectation(description: "Should fail to connect")
        wait(for: [self.failexp], timeout: 20.0)
    }
    
    func wampSessionEnded(_ reason: String) {
        XCTAssert(reason == "wamp.error.no_such_realm")
        self.failexp.fulfill()
    }
    
    
}

class CrossbarPublishCallbacksTest: XCTestCase, WampSessionDelegate {
    var pubCBExp: XCTestExpectation!

    func testConnectAndPublish() {
        createTestSession(self)
        self.pubCBExp = expectation(description: "Should publish using callbacks")
        wait(for: [self.pubCBExp], timeout: 20.0)

    }

    func wampSessionConnected(_ session: WampSession, sessionId: Int) {
        session.publish("com.myapp.CrossbarPublishCallbacksTest", options: [:], args: ["Hello World"], kwargs: nil, onSuccess: {
            XCTAssert(true)
            session.disconnect()
            self.pubCBExp.fulfill()
        }, onError: { (details, error) in
            XCTFail("PUBLISH FAIL \(details) : \(error)")
        })
    }
    
    func wampSessionEnded(_ reason: String) {
        print("CrossbarPublishCallbacksTest \(reason)")
    }
}

class CrossbarPublishDelegateTest: XCTestCase, WampSessionDelegate {
    var pubDelExp: XCTestExpectation!

    func testConnectAndPublish() {
        createTestSession(self)
        self.pubDelExp = expectation(description: "Should publish using delegate")
        wait(for: [self.pubDelExp], timeout: 20.0)

    }

    func wampSessionConnected(_ session: WampSession, sessionId: Int) {
        session.publish("com.myapp.CrossbarPublishDelegateTest", options: [:], args: ["Hello World"], kwargs: nil)
    }
    
    func wampPubSuccessful() {
        XCTAssert(true)
        self.pubDelExp.fulfill()
    }
    
    func wampPubError(details: [String : Any], error: String) {
        XCTFail("PUBLISH FAIL \(details) : \(error)")
        self.pubDelExp.fulfill()
    }
    
    func wampSessionEnded(_ reason: String) {
        print("CrossbarPublishDelegateTest \(reason)")
    }
}

class CrossbarSubscribeCallbacksTest: XCTestCase, WampSessionDelegate {
    var publisher: WampSession!
    var subscriber: WampSession!
    var subCBExp: XCTestExpectation!

    func testConnectAndPublish() {
        let url = URL(string: "ws://localhost:8080/ws")!
        let transport1 = WampSocket(wsEndpoint: url)
        let transport2 = WampSocket(wsEndpoint: url)
        
        subscriber = WampSession(realm: "realm1", transport: transport1, authmethods: ["anonymous"])
        subscriber.delegate = self
        subscriber.connect()
        
        publisher = WampSession(realm: "realm1", transport: transport2, authmethods: ["anonymous"])
        publisher.connect()
        
        self.subCBExp = expectation(description: "Should publish using callbacks")
        wait(for: [self.subCBExp], timeout: 20.0)
    }

    func wampSessionConnected(_ session: WampSession, sessionId: Int) {
        self.subscriber.subscribe("com.myapp.CrossbarSubscribeCallbacksTest") { (sub) in
            self.publishEvent(self.publisher)
        } onError: { (details, error) in
            XCTFail("PUBLISH FAIL \(details) : \(error)")
        } onEvent: { (details, results, kwargs) in
            let eventResults = results?.first as? String
            XCTAssert(eventResults == "Hello World")
            self.subCBExp.fulfill()
        }
    }
    
    func publishEvent(_ session: WampSession) {
        session.publish("com.myapp.CrossbarSubscribeCallbacksTest", options: [:], args: ["Hello World"], kwargs: nil, onSuccess: {
            return
        }, onError: { (details, error) in
            XCTFail("PUBLISH FAIL \(details) : \(error)")
        })
    }
    
    func wampSessionEnded(_ reason: String) {
        print("CrossbarSubscribeCallbacksTest \(reason)")
    }
    
}

class CrossbarSubscribeDelegateTest: XCTestCase, WampSessionDelegate {
    var publisher: WampSession!
    var subscriber: WampSession!
    var subDelExp: XCTestExpectation!

    func testConnectAndPublish() {
        let url = URL(string: "ws://localhost:8080/ws")!
        let transport1 = WampSocket(wsEndpoint: url)
        let transport2 = WampSocket(wsEndpoint: url)
        
        subscriber = WampSession(realm: "realm1", transport: transport1, authmethods: ["anonymous"])
        subscriber.delegate = self
        subscriber.connect()
        
        publisher = WampSession(realm: "realm1", transport: transport2, authmethods: ["anonymous"])
        publisher.connect()
        
        self.subDelExp = expectation(description: "Should publish using delegate method")
        wait(for: [self.subDelExp], timeout: 20.0)
    }

    func wampSessionConnected(_ session: WampSession, sessionId: Int) {
        self.subscriber.subscribe("com.myapp.CrossbarSubscribeDelegateTest")
    }
    
    func wampSubSuccessful(_ subscription: Subscription) {
        self.publisher.publish("com.myapp.CrossbarSubscribeDelegateTest", options: [:], args: ["Hello World"], kwargs: nil)
    }
    
    func wampSubError(details: [String : Any], error: String) {
        print("Wamp Sub Errorn\nDetails: \(details)\nError: \(error)")
        XCTFail()
    }
    
    func wampSubEventReceived(details: [String : AnyObject], results: [AnyObject]?, kwargs: [String : AnyObject]?) {
        let eventResults = results?.first as? String
        XCTAssert(eventResults == "Hello World")
        self.subDelExp.fulfill()
    }
    
    func wampSessionEnded(_ reason: String) {
        print("CrossbarSubscribeDelegateTest \(reason)")
    }
    
}

