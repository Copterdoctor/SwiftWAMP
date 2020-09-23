import Foundation
import Quick
import Nimble
@testable import SwiftWAMP

//class TestSwampTransport: WampTransport {
//    var delegate: WampTransportDelegate?
//
//    var dataSent: [Data]
//
//    init() {
//        self.dataSent = []
//    }
//
//    func connect() {
//        self.delegate?.swampTransportDidConnectWithSerializer(JSONWampSerializer())
//    }
//
//    func disconnect(_ reason: String) {
//        self.delegate?.swampTransportDidDisconnect(nil, reason: reason)
//    }
//
//    func sendData(_ data: Data) {
//
//    }
//}

class CrossbarIntegrationTestsSpec: QuickSpec {
    override func spec() {
        var session: WampSession?
        
        beforeSuite {
            let url = URL(string: "ws://localhost:8080/ws")!
            let transport = WampSocket(wsEndpoint: url)
            session = WampSession(realm: "realm1", transport: transport, authmethods: ["anonymous"])
            session?.connect()
        }
        
        describe("Test Realm") {
            
            context("Creating session") {
                it("Should not be nil") {
                    expect(session).toNot( beNil() )
                }
            }
            
            context("Connecting to router") {
                it("Should connect successfully to crossbario/crossbar docker container") {
                    expect(session?.isConnected()).toEventually( beTrue() )
                }
            }
        }
        
        
    }
    
    static var allTests = [
        ("spec", spec),
    ]
}

//class CrossbarSubscriptionTestSpec: QuickSpec {
//    override func spec() {
//        var session: WampSession?
//        var eventResults: [Any]?
//
//        beforeSuite {
//            let url = URL(string: "ws://localhost:8080/ws")!
//            let transport = WampSocket(wsEndpoint: url)
//            session = WampSession(realm: "realm1", transport: transport, authmethods: ["anonymous"])
//            session?.connect()
//        }
//
//
//        context("Connecting to router") {
//            it("Should connect successfully to crossbario/crossbar docker container") {
//                expect(session?.isConnected()).toEventually( beTrue() )
//            }
//        }
//
//        describe("Subscribe to event") {
//            context("Event") {
//                waitUntil { (done) in
//                    session?.subscribe("com.myapp.hello", onSuccess: { (sub) in
//                        print("SUBSCRIPTION: \(sub)")
//                    }, onError: { (details, error) in
//                        print("SUB ERROR DETAILS: \(details) :: ERROR: \(error)")
//                    }, onEvent: { (details, results, kwResults) in
//                        print("ON EVENT DETAILS: \(details)\n :: Results: \(results?.debugDescription)\n :: kwResults: \(kwResults?.debugDescription)")
//                        eventResults = results
//                    });
//                    expect(eventResults).toNot(beNil());
//                    done();
//                }
//            }
//        }
//
//        describe("Should receive Hello World n") {
//            context("Event Received") {
//                expect(eventResults).toNot(beNil())
//                print("EVENT RESULTS: \(eventResults)")
//            }
//        }
//    }
//
//    static var allTests = [
//        ("spec", spec),
//    ]
//}
