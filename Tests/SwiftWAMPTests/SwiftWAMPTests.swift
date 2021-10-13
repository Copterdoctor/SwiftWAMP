import XCTest
@testable import SwiftWAMP

func createTestSession(_ delegate: WampSessionDelegate?) -> WampSession {
    let url = URL(string: "ws://localhost:8080/ws")!
    let transport = WampSocket(wsEndpoint: url)

    let s = WampSession(realm: "realm1", transport: transport, authmethods: ["anonymous"])
    s.delegate = delegate
    s.connect()
    return s
}

// MARK: Subscriptions

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
        let _ = createTestSession(self)
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
    var exp: XCTestExpectation!
    
    func testConnectAndPublish() {
        let _ = createTestSession(self)
        self.exp = expectation(description: "Should publish using callbacks")
        wait(for: [self.exp], timeout: 20.0)
    }
    
    func wampSessionConnected(_ session: WampSession, sessionId: Int) {
        session.publish("com.myapp.CrossbarPublishCallbacksTest", options: [:], args: ["Hello World"], kwargs: nil, onSuccess: {
            XCTAssert(true)
            session.disconnect()
            self.exp.fulfill()
        }, onError: { (details, error) in
            XCTFail("PUBLISH FAIL \(details) : \(error)")
        })
    }
    
    func wampSessionEnded(_ reason: String) {
        XCTFail("CrossbarPublishCallbacksTest \(reason)")
    }
}

class CrossbarPublishDelegateTest: XCTestCase, WampSessionDelegate {
    var pubDelExp: XCTestExpectation!
    
    func testConnectAndPublish() {
        let _ = createTestSession(self)
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
        XCTFail("CrossbarPublishDelegateTest \(reason)")
    }
}

class CrossbarSubscribeCallbacksTest: XCTestCase, WampSessionDelegate {
    var publisher: WampSession!
    var subscriber: WampSession!
    var exp: XCTestExpectation!
    
    func testConnectAndSubscribe() {
        subscriber = createTestSession(self)
        publisher = createTestSession(nil)
        
        self.exp = expectation(description: "Should publish using callbacks")
        wait(for: [self.exp], timeout: 20.0)
    }
    
    func wampSessionConnected(_ session: WampSession, sessionId: Int) {
        self.subscriber.subscribe("com.myapp.CrossbarSubscribeCallbacksTest") { (sub) in
            self.publishEvent(self.publisher)
        } onError: { (details, error) in
            XCTFail("PUBLISH FAIL \(details) : \(error)")
        } onEvent: { (details, results, kwargs) in
            let eventResults = results?.first as? String
            XCTAssert(eventResults == "Hello World")
            self.exp.fulfill()
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
        XCTFail("CrossbarSubscribeCallbacksTest \(reason)")
    }
    
}

class CrossbarSubscribeDelegateTest: XCTestCase, WampSessionDelegate {
    var publisher: WampSession!
    var subscriber: WampSession!
    var exp: XCTestExpectation!
    
    func testConnectAndSubscribe() {
        subscriber = createTestSession(self)
        publisher = createTestSession(nil)
        
        self.exp = expectation(description: "Should publish using delegate method")
        wait(for: [self.exp], timeout: 20.0)
    }
    
    func wampSessionConnected(_ session: WampSession, sessionId: Int) {
        self.subscriber.subscribe("com.myapp.CrossbarSubscribeDelegateTest")
    }
    
    func wampSubSuccessful(_ subscription: Subscription) {
        self.publisher.publish("com.myapp.CrossbarSubscribeDelegateTest", options: [:], args: ["Hello World"], kwargs: nil)
    }
    
    func wampSubError(details: [String : Any], error: String) {
        XCTFail("Wamp Sub Errorn\nDetails: \(details)\nError: \(error)")
    }
    
    func wampSubEventReceived(details: [String : Any], results: [Any]?, kwargs: [String : Any]?) {
        let eventResults = results?.first as? String
        XCTAssert(eventResults == "Hello World")
        self.exp.fulfill()
    }
    
    func wampSessionEnded(_ reason: String) {
        XCTFail("CrossbarSubscribeDelegateTest \(reason)")
    }
    
}

// TODO: UNSUBSCRIBE TEST

// MARK: Registrations

class CrossbarRegisterCalleeCallbacksTest: XCTestCase, WampSessionDelegate {
    var exp: XCTestExpectation!
    let proc = "com.SwiftWAMP.CrossbarRegisterCalleeCallbacksTest"
    
    func testConnectAndRegister() {
        let _ = createTestSession(self)
        self.exp = expectation(description: "Should register using callbacks")
        wait(for: [self.exp], timeout: 20.0)
        
    }
    
    func wampSessionConnected(_ session: WampSession, sessionId: Int) {
        session.register(self.proc) { (reg) in
            XCTAssert(true)
            self.exp.fulfill()
        } onError: { (details, error) in
            XCTFail("CrossbarRegisterCalleeCallbacksTest \(details) \(error)")
        } onFire: { (details, args, kwargs) -> (options: [String : Any], args: [Any], kwargs: [String : Any]) in
            return ([:], ["Test"], ["Test":"Test"])
        }
    }
    
    func wampSessionEnded(_ reason: String) {
        XCTFail("CrossbarRegisterCalleeCallbacksTest \(reason)")
    }
}

class CrossbarRegisterCalleeDelegateTest: XCTestCase, WampSessionDelegate {
    var exp: XCTestExpectation!
    let proc = "com.SwiftWAMP.CrossbarRegisterCalleeDelegateTest"
    
    func testConnectAndRegister() {
        let _ = createTestSession(self)
        self.exp = expectation(description: "Should register using callbacks")
        wait(for: [self.exp], timeout: 20.0)
        
    }
    
    func wampSessionConnected(_ session: WampSession, sessionId: Int) {
        session.register(self.proc)
    }
    
    func wampRegistrationSuccessful(_ registration: Registration) {
        XCTAssert(true)
        self.exp.fulfill()
    }
    
    func wampRegistrationError(details: [String : Any], error: String) {
        XCTFail("CrossbarRegisterCalleeDelegateTest \(details) \(error)")
    }
    
    func wampSessionEnded(_ reason: String) {
        XCTFail("CrossbarPublishCallbacksTest \(reason)")
    }
}

class CrossbarRegisterSameTwiceDelegateTest: XCTestCase, WampSessionDelegate {
    var exp: XCTestExpectation!
    let proc = "CrossbarRegisterSameTwiceDelegateTest"
    
    func testConnectAndRegisterTwice() {
        let _ = createTestSession(self)
        let _ = createTestSession(self)
        self.exp = expectation(description: "Should fail to register same method twice")
        wait(for: [self.exp], timeout: 20.0)
        
    }
    
    func wampSessionConnected(_ session: WampSession, sessionId: Int) {
        session.register(self.proc)
    }
    
    func wampRegistrationSuccessful(_ registration: Registration) {
        return
    }
    
    func wampRegistrationError(details: [String : Any], error: String) {
        XCTAssert(error == "wamp.error.procedure_already_exists")
        self.exp.fulfill()
    }
    
    func wampSessionEnded(_ reason: String) {
        XCTFail("CrossbarPublishCallbacksTest \(reason)")
    }
}

class CrossbarRegisterSameTwiceCallbackTest: XCTestCase, WampSessionDelegate {
    var exp: XCTestExpectation!
    let proc = "com.SwiftWAMP.CrossbarRegisterSameTwiceCallbackTest"
    
    func testConnectAndRegisterTwice() {
        let _ = createTestSession(self)
        let _ = createTestSession(self)
        self.exp = expectation(description: "Should fail to register same method twice")
        wait(for: [self.exp], timeout: 20.0)
        
    }
    
    func wampSessionConnected(_ session: WampSession, sessionId: Int) {
        session.register(self.proc) { (reg) in
            return
        } onError: { (details, error) in
            XCTAssert(error == "wamp.error.procedure_already_exists")
            self.exp.fulfill()
        } onFire: { (details, args, kwargs) -> (options: [String : Any], args: [Any], kwargs: [String : Any]) in
            return ([:], ["Test"], ["Test":"Test"])
        }
    }
    
    func wampSessionEnded(_ reason: String) {
        XCTFail("CrossbarRegisterCalleeCallbacksTest \(reason)")
    }
}

class CrossbarRemoteProcedureCallCallbackTest: XCTestCase, WampSessionDelegate {
    var callee: WampSession!
    var caller: WampSession!
    var exp: XCTestExpectation!
    let proc = "com.SwiftWAMP.CrossbarRemoteProcedureCallCallbackTest"
    let jsonObj = [
        "result": "success"
    ]
    
    func testConnectAndRegister() {
        callee = createTestSession(self)
        caller = createTestSession(self)
        self.exp = expectation(description: "Should call registered method using callbacks")
        wait(for: [self.exp], timeout: 20.0)
    }
    
    func wampSessionConnected(_ session: WampSession, sessionId: Int) {
        if session == callee {
            callee.register(self.proc) { (reg) in
                self.caller.call(self.proc) { (details, results, kwargs) in
                    if let results = results as? [String] {
                        let test = results[0]
                        XCTAssert(test == "CrossbarRemoteProcedureCallCallbackTest")
                    }
                    self.exp.fulfill()
                } onError: { (details, error, args, kwargs) in
                    XCTFail(error)
                }
            } onError: { (details, error) in
                XCTFail(error)
            } onFire: { (details, args, kwargs) -> (options: [String:Any], args: [Any], kwargs: [String: Any]) in
                return ([:], ["CrossbarRemoteProcedureCallCallbackTest"], [:])
            }
        }
    }
    
    func wampSessionEnded(_ reason: String) {
        XCTFail("CrossbarRegisterCalleeCallbacksTest \(reason)")
    }
}

class CrossbarRemoteProcedureCallDelegateTest: XCTestCase, WampSessionDelegate {
    var callee: WampSession!
    var caller: WampSession!
    var exp: XCTestExpectation!
    let proc = "com.SwiftWAMP.CrossbarRemoteProcedureCallDelegateTest"
    
    func testConnectAndRegister() {
        callee = createTestSession(self)
        caller = createTestSession(self)
        self.exp = expectation(description: "Should call registered method using delegate")
        wait(for: [self.exp], timeout: 20.0)
    }
    
    func wampSessionConnected(_ session: WampSession, sessionId: Int) {
        if session == callee {
            callee.register(self.proc)
        }
        
    }
    
    func wampRegistrationSuccessful(_ registration: Registration) {
        caller.call(self.proc)
    }
    
    func wampCallSuccessful(details: [String : Any], results: [Any]?, kwResults: [String : Any]?) {
        let result = results as! [String]
        XCTAssert(result[0] == self.proc)
        self.exp.fulfill()
    }
    
    func wampProcedureCalled(details: [String : Any], args: [Any]?, kwargs: [String : Any]?) -> (options: [String : Any], args: [Any], kwargs: [String : Any])? {
        return ([:], [self.proc], [:])
    }
    
    func wampRegistrationError(details: [String : Any], error: String) {
        XCTFail(error)
    }
    
    func wampSessionEnded(_ reason: String) {
        XCTFail("CrossbarRegisterCalleeCallbacksTest \(reason)")
    }
}
// TODO: UNREGISTER TEST


// MARK: Regression Tests


class CustomHTTPHeadersTest: XCTestCase {

    func testCustomHeaders() {
        let url = URL(string: "ws://localhost:8080/ws")!
        
        var headerDict: [httpHeader:httpHeaderValue] = ["Sec-WebSocket-Protocol": "wamp.2.json, wamp.2.msgpack"]
        
        for i in 0...10 {
            headerDict["header\(i)"] = "value\(i)"
        }
        
        var request = URLRequest(url: url)
    
        headerDict.forEach { (header: httpHeader, value: httpHeaderValue) in
            request.setValue(value, forHTTPHeaderField: header)
        }
        
        let setHeaders = request.allHTTPHeaderFields
        
        XCTAssert(headerDict == setHeaders)
        
        
    }
}
