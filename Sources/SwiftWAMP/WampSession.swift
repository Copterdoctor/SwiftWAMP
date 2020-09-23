//
//  WampSession.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation


// MARK: Call callbacks
public typealias CallCallback = (_ details: [String: Any], _ results: [Any]?, _ kwResults: [String: Any]?) -> Void
public typealias ErrorCallCallback = (_ details: [String: Any], _ error: String, _ args: [Any]?, _ kwargs: [String: Any]?) -> Void

//TODO: Review callbacks
// MARK: Callee callbacks
// For now callee is irrelevant
//public typealias RegisterCallback = (registration: Registration) -> Void
//public typealias ErrorRegisterCallback = (details: [String: AnyObject], error: String) -> Void
//public typealias WampProc = (args: [AnyObject]?, kwargs: [String: AnyObject]?) -> AnyObject
//public typealias UnregisterCallback = () -> Void
//public typealias ErrorUnregsiterCallback = (details: [String: AnyObject], error: String) -> Void

// MARK: Subscribe callbacks
public typealias SubscribeCallback = (_ subscription: Subscription) -> Void
public typealias ErrorSubscribeCallback = (_ details: [String: Any], _ error: String) -> Void
public typealias EventCallback = (_ details: [String: Any], _ results: [Any]?, _ kwResults: [String: Any]?) -> Void
public typealias UnsubscribeCallback = () -> Void
public typealias ErrorUnsubscribeCallback = (_ details: [String: Any], _ error: String) -> Void

// MARK: Publish callbacks
public typealias PublishCallback = () -> Void
public typealias ErrorPublishCallback = (_ details: [String: Any], _ error: String) -> Void

// TODO: Expose only an interface (like Cancellable) to user
open class Subscription {
    fileprivate let session: WampSession
    internal let subscription: Int
    internal let eventCallback: EventCallback
    fileprivate var isActive: Bool = true

    internal init(session: WampSession, subscription: Int, onEvent: @escaping EventCallback) {
        self.session = session
        self.subscription = subscription
        self.eventCallback = onEvent
    }

    //TODO: This doesn't appear to be in use
    internal func invalidate() {
        self.isActive = false
    }

    func cancel(_ onSuccess: @escaping UnsubscribeCallback, onError: @escaping ErrorUnsubscribeCallback) {
        if !self.isActive {
            onError([:], "Subscription already inactive.")
        }
        self.session.unsubscribe(self.subscription, onSuccess: onSuccess, onError: onError)
    }
}

// For now callee is irrelevant
//public class Registration {
//    private let session: WampSession
//}

public protocol WampSessionDelegate {
    func wampSessionHandleChallenge(_ authMethod: String, extra: [String: Any]) -> String
    func wampSessionConnected(_ session: WampSession, sessionId: Int)
    func wampSessionEnded(_ reason: String)
}

open class WampSession: WampTransportDelegate {
    // MARK: Public typealiases

    // MARK: delegate
    open var delegate: WampSessionDelegate?

    // MARK: Constants
    // No callee role for now
    fileprivate let supportedRoles: [WampRole] = [WampRole.Caller, WampRole.Subscriber, WampRole.Publisher]
    fileprivate let clientName = "SwiftWAMP-1.0.0"

    // MARK: Members
    fileprivate let realm: String
    fileprivate var transport: WampTransport
    fileprivate let authmethods: [String]?
    fileprivate let authid: String?
    fileprivate let authrole: String?
    fileprivate let authextra: [String: Any]?

    // MARK: State members
    fileprivate var currRequestId: Int = 1

    // MARK: Session state
    fileprivate var serializer: WampSerializer?
    fileprivate var sessionId: Int?
    fileprivate var routerSupportedRoles: [WampRole]?

    // MARK: Call role
    //                         requestId
    fileprivate var callRequests: [Int: (callback: CallCallback, errorCallback: ErrorCallCallback)] = [:]

    // MARK: Subscriber role
    //                              requestId
    fileprivate var subscribeRequests: [Int: (callback: SubscribeCallback, errorCallback: ErrorSubscribeCallback, eventCallback: EventCallback)] = [:]
    //                          subscription
    fileprivate var subscriptions: [Int: Subscription] = [:]
    //                                requestId
    fileprivate var unsubscribeRequests: [Int: (subscription: Int, callback: UnsubscribeCallback, errorCallback: ErrorUnsubscribeCallback)] = [:]

    // MARK: Publisher role
    //                            requestId
    fileprivate var publishRequests: [Int: (callback: PublishCallback, errorCallback: ErrorPublishCallback)] = [:]

    // MARK: C'tor
    required public init(realm: String, transport: WampTransport, authmethods: [String]?=nil, authid: String?=nil, authrole: String?=nil, authextra: [String: Any]?=nil){
        self.realm = realm
        self.transport = transport
        self.authmethods = authmethods
        self.authid = authid
        self.authrole = authrole
        self.authextra = authextra
        self.transport.delegate = self
    }

    // MARK: Public API

    final public func isConnected() -> Bool {
        return self.sessionId != nil
    }

    final public func connect() {
        self.transport.connect()
    }

    final public func disconnect(_ reason: String="wamp.error.close_realm") {
        self.sendMessage(GoodbyeWampMessage(details: [:], reason: reason))
    }

    // MARK: Caller role
    open func call(_ proc: String, options: [String: Any]=[:], args: [Any]?=nil, kwargs: [String: Any]?=nil, onSuccess: @escaping CallCallback, onError: @escaping ErrorCallCallback) {
        let callRequestId = self.generateRequestId()
        // Tell router to dispatch call
        self.sendMessage(CallWampMessage(requestId: callRequestId, options: options, proc: proc, args: args, kwargs: kwargs))
        // Store request ID to handle result
        self.callRequests[callRequestId] = (callback: onSuccess, errorCallback: onError )
    }

    // MARK: Callee role
    // For now callee is irrelevant
    // public func register(proc: String, options: [String: AnyObject]=[:], onSuccess: RegisterCallback, onError: ErrorRegisterCallback, onFire: WampProc) {
    // }

    // MARK: Subscriber role

    open func subscribe(_ topic: String, options: [String: Any]=[:], onSuccess: @escaping SubscribeCallback, onError: @escaping ErrorSubscribeCallback, onEvent: @escaping EventCallback) {
        // TODO: assert topic is a valid WAMP uri
        let subscribeRequestId = self.generateRequestId()
        // Tell router to subscribe client on a topic
        self.sendMessage(SubscribeWampMessage(requestId: subscribeRequestId, options: options, topic: topic))
        // Store request ID to handle result
        self.subscribeRequests[subscribeRequestId] = (callback: onSuccess, errorCallback: onError, eventCallback: onEvent)
    }

    // Internal because only a Subscription object can call this
    internal func unsubscribe(_ subscription: Int, onSuccess: @escaping UnsubscribeCallback, onError: @escaping ErrorUnsubscribeCallback) {
        let unsubscribeRequestId = self.generateRequestId()
        // Tell router to unsubscribe me from some subscription
        self.sendMessage(UnsubscribeWampMessage(requestId: unsubscribeRequestId, subscription: subscription))
        // Store request ID to handle result
        self.unsubscribeRequests[unsubscribeRequestId] = (subscription, onSuccess, onError)
    }

    // MARK: Publisher role
    // without acknowledging
    open func publish(_ topic: String, options: [String: Any]=[:], args: [Any]?=nil, kwargs: [String: Any]?=nil) {
        // TODO: assert topic is a valid WAMP uri
        let publishRequestId = self.generateRequestId()
        // Tell router to publish the event
        self.sendMessage(PublishWampMessage(requestId: publishRequestId, options: options, topic: topic, args: args, kwargs: kwargs))
        // We don't need to store the request, because it's unacknowledged anyway
    }

    // with acknowledging
    open func publish(_ topic: String, options: [String: Any]=[:], args: [Any]?=nil, kwargs: [String: Any]?=nil, onSuccess: @escaping PublishCallback, onError: @escaping ErrorPublishCallback) {
        // add acknowledge to options, so we get callbacks
        var options = options
        options["acknowledge"] = true
        // TODO: assert topic is a valid WAMP uri
        let publishRequestId = self.generateRequestId()
        // Tell router to publish the event
        self.sendMessage(PublishWampMessage(requestId: publishRequestId, options: options, topic: topic, args: args, kwargs: kwargs))
        // Store request ID to handle result
        self.publishRequests[publishRequestId] = (callback: onSuccess, errorCallback: onError)
    }

    // MARK: WampTransportDelegate

    open func wampTransportDidDisconnect(_ reason: String, code: UInt16) {
            self.delegate?.wampSessionEnded(reason)
    }

    open func wampTransportDidConnectWithSerializer(_ serializer: WampSerializer) {
        self.serializer = serializer
        // Start session by sending a Hello message!

        var roles = [String: Any]()
        for role in self.supportedRoles {
            // For now basic profile, (demands empty dicts)
            roles[role.rawValue] = [:]
        }

        var details: [String: Any] = [:]

        if let authmethods = self.authmethods {
            details["authmethods"] = authmethods
        }
        if let authid = self.authid {
            details["authid"] = authid
        }
        if let authrole = self.authrole {
            details["authrole"] = authrole
        }
        if let authextra = self.authextra {
            details["authextra"] = authextra
        }

        details["agent"] = self.clientName
        details["roles"] = roles
        self.sendMessage(HelloWampMessage(realm: self.realm, details: details))
    }

    open func wampTransportReceivedData(_ data: Data) {
        if let payload = self.serializer?.unpack(data), let message = WampMessages.createMessage(payload) {
            self.handleMessage(message)
        }
    }

    fileprivate func handleMessage(_ message: WampMessage) {
        switch message {
        // MARK: Auth responses
        case let message as ChallengeWampMessage:
            if let authResponse = self.delegate?.wampSessionHandleChallenge(message.authMethod, extra: message.extra) {
                self.sendMessage(AuthenticateWampMessage(signature: authResponse, extra: [:]))
            } else {
                print("There was no delegate, aborting.")
                self.abort()
            }
        // MARK: Session responses
        case let message as WelcomeWampMessage:
            self.sessionId = message.sessionId
            let routerRoles = message.details["roles"]! as! [String : [String : Any]]
            self.routerSupportedRoles = routerRoles.keys.map { WampRole(rawValue: $0)! }
            self.delegate?.wampSessionConnected(self, sessionId: message.sessionId)
        case let message as GoodbyeWampMessage:
            if message.reason != "wamp.error.goodbye_and_out" {
                // Means it's not our initiated goodbye, and we should reply with goodbye
                self.sendMessage(GoodbyeWampMessage(details: [:], reason: "wamp.error.goodbye_and_out"))
            }
            self.transport.disconnect(message.reason)
        case let message as AbortWampMessage:
            self.transport.disconnect(message.reason)
        // MARK: Call role
        case let message as ResultWampMessage:
            let requestId = message.requestId
            if let (callback, _) = self.callRequests.removeValue(forKey: requestId) {
                callback(message.details, message.results, message.kwResults)
            } else {
                // TODO: log this erroneous situation
            }
        // MARK: Subscribe role
        case let message as SubscribedWampMessage:
            let requestId = message.requestId
            if let (callback, _, eventCallback) = self.subscribeRequests.removeValue(forKey: requestId) {
                // Notify user and delegate him to unsubscribe this subscription
                let subscription = Subscription(session: self, subscription: message.subscription, onEvent: eventCallback)
                callback(subscription)
                // Subscription succeeded, we should store event callback for when it's fired
                self.subscriptions[message.subscription] = subscription
            } else {
                // TODO: log this erroneous situation
            }
        case let message as EventWampMessage:
            if let subscription = self.subscriptions[message.subscription] {
                subscription.eventCallback(message.details, message.args, message.kwargs)
            } else {
                // TODO: log this erroneous situation
            }
        case let message as UnsubscribedWampMessage:
            let requestId = message.requestId
            if let (subscription, callback, _) = self.unsubscribeRequests.removeValue(forKey: requestId) {
                if let subscription = self.subscriptions.removeValue(forKey: subscription) {
                    subscription.invalidate()
                    callback()
                } else {
                    // TODO: log this erroneous situation
                }
            } else {
                // TODO: log this erroneous situation
            }
        case let message as PublishedWampMessage:
            let requestId = message.requestId
            if let (callback, _) = self.publishRequests.removeValue(forKey: requestId) {
                callback()
            } else {
                // TODO: log this erroneous situation
            }

        ////////////////////////////////////////////
        // MARK: Handle error responses
        ////////////////////////////////////////////
        case let message as ErrorWampMessage:
            switch message.requestType {
            case WampMessages.call:
                if let (_, errorCallback) = self.callRequests.removeValue(forKey: message.requestId) {
                    errorCallback(message.details, message.error, message.args, message.kwargs)
                } else {
                    // TODO: log this erroneous situation
                }
            case WampMessages.subscribe:
                if let (_, errorCallback, _) = self.subscribeRequests.removeValue(forKey: message.requestId) {
                    errorCallback(message.details, message.error)
                } else {
                    // TODO: log this erroneous situation
                }
            case WampMessages.unsubscribe:
                if let (_, _, errorCallback) = self.unsubscribeRequests.removeValue(forKey: message.requestId) {
                    errorCallback(message.details, message.error)
                } else {
                    // TODO: log this erroneous situation
                }
            case WampMessages.publish:
                if let(_, errorCallback) = self.publishRequests.removeValue(forKey: message.requestId) {
                    errorCallback(message.details, message.error)
                } else {
                    // TODO: log this erroneous situation
                }
            default:
                return
            }
        default:
            return
        }
    }

    // MARK: Private methods

    fileprivate func abort() {
        if self.sessionId != nil {
            return
        }
        self.sendMessage(AbortWampMessage(details: [:], reason: "wamp.error.system_shutdown"))
        self.transport.disconnect("No challenge delegate found.")
    }

    fileprivate func sendMessage(_ message: WampMessage){
        let marshalledMessage = message.marshal()
        let data = self.serializer!.pack(marshalledMessage as [Any])!
        self.transport.sendData(data)
    }

    fileprivate func generateRequestId() -> Int {
        self.currRequestId += 1
        return self.currRequestId
    }
}
