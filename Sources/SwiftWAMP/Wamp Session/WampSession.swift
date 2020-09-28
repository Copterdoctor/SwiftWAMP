//
//  WampSession.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation


// MARK: RPC Caller Typealias Callbacks
public typealias CallCallback = ((_ details: [String: Any], _ results: [Any]?, _ kwResults: [String: Any]?) -> Void)?
public typealias ErrorCallCallback = ((_ details: [String: Any], _ error: String, _ args: [Any]?, _ kwargs: [String: Any]?) -> Void)?

// MARK: RPC Callee Typealias Callbacks
public typealias RegisterCallback = ((_ registration: Registration) -> Void)?
public typealias ErrorRegisterCallback = ((_ details: [String: Any],_ error: String) -> Void)?

public typealias WampProcedure = ((_ details: [String: Any],_ args: [Any]?,_ kwargs: [String: Any]?) -> (options: [String:Any], args: [Any], kwargs: [String: Any])?)?

public typealias UnregisterCallback = () -> Void
public typealias ErrorUnregsiterCallback = (_ details: [String: Any],_ error: String) -> Void

// MARK: Subscribe Typealias Callbacks
public typealias SubscribeCallback = ((_ subscription: Subscription) -> Void)?
public typealias ErrorSubscribeCallback = ((_ details: [String: Any], _ error: String) -> Void)?
public typealias UnsubscribeCallback = () -> Void
public typealias ErrorUnsubscribeCallback = (_ details: [String: Any], _ error: String) -> Void

// MARK: Publish Typealias Callbacks
public typealias PublishCallback = (() -> Void)?
public typealias ErrorPublishCallback = ((_ details: [String: Any], _ error: String) -> Void)?

// MARK: Event Typealias Callbacks
public typealias EventCallback = ((_ details: [String: Any], _ results: [Any]?, _ kwResults: [String: Any]?) -> Void)?


// Used for subscribing to wamp events
// TODO: Expose only an interface (like Cancellable) to user
/**
 Subscription class to manage WAMP subscription with router used by WampSession
 */
open class Subscription {
    fileprivate let session: WampSession
    internal let subscription: Int
    internal let eventCallback: EventCallback
    fileprivate var isActive: Bool = true
    
    internal init(session: WampSession, subscription: Int, onEvent: EventCallback) {
        self.session = session
        self.subscription = subscription
        self.eventCallback = onEvent
    }
    
    internal func invalidate() {
        self.isActive = false
    }
    
    /// Cancel subscription
    /// - Parameters:
    ///   - onSuccess: Callback when router sends unsubscribed event
    ///   - onError: Callback when router send ubsubscribe error event
    func cancel(_ onSuccess: @escaping UnsubscribeCallback, onError: @escaping ErrorUnsubscribeCallback) {
        if !self.isActive {
            onError([:], "Subscription already inactive.")
        }
        self.session.unsubscribe(self.subscription, onSuccess: onSuccess, onError: onError)
    }
}

// Used by registering callee
/// Registration class to manage WAMP registered procedures with router used by WampSession
public class Registration {
    fileprivate let session: WampSession
    internal let registration: Int
    internal let wampProc: WampProcedure
    fileprivate var isActive: Bool = true
    
    internal init(session: WampSession, registration: Int, wampProc: WampProcedure) {
        self.session = session
        self.registration = registration
        self.wampProc = wampProc
    }
    
    internal func invalidate() {
        self.isActive = false
    }
    
    /// Cancel registration
    /// - Parameters:
    ///   - onSuccess: Callback when router sends unregistered event
    ///   - onError: Callback when router sends unregister error event
    func cancel(_ onSuccess: @escaping UnregisterCallback, onError: @escaping ErrorUnregsiterCallback) {
        if !self.isActive {
            onError([:], "Registration already inactive.")
        }
        self.session.unregister(self.registration, onSuccess: onSuccess, onError: onError)
    }
}

/// SwiftWAMP Websocket session
/// Wamp Protocol documentation https://wamp-proto.org
/// Autobahn used by Crossbar documentation https://autobahn.readthedocs.io/en/latest/wamp/programming.html#
open class WampSession: WampTransportDelegate {
    
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
    fileprivate var sessionId: Int?
    fileprivate var routerSupportedRoles: [WampRole]?
    
    // MARK: Tracking Subs, Regs and Requests
    
    fileprivate var subscriptions: [Int: Subscription] = [:]
    fileprivate var registrations: [Int: Registration] = [:]
    
    // [requestId : Callbacks]
    
    fileprivate var registerRequests: [Int: (onSuccess: RegisterCallback, onError: ErrorRegisterCallback, onFire: WampProcedure)] = [:]
    fileprivate var unregisterRequests: [Int: (registration: Int, callback: UnregisterCallback, errorCallback: ErrorUnregsiterCallback)] = [:]
    fileprivate var callRequests: [Int: (callback: CallCallback, errorCallback: ErrorCallCallback)] = [:]
    fileprivate var subscribeRequests: [Int: (callback: SubscribeCallback, errorCallback: ErrorSubscribeCallback, eventCallback: EventCallback)] = [:]
    fileprivate var unsubscribeRequests: [Int: (subscription: Int, callback: UnsubscribeCallback, errorCallback: ErrorUnsubscribeCallback)] = [:]
    fileprivate var publishRequests: [Int: (callback: PublishCallback, errorCallback: ErrorPublishCallback)] = [:]
    
    // MARK: Init
    /// WampSession Init
    /// - Parameters:
    ///   - realm: Name of router realm e.g. "Realm1" default Crossbario/Crossbar docker image
    ///   - transport: Instance of WampTransport
    ///   - authmethods: is used by the client to announce the authentication methods it is prepared to perform. For WAMP-CRA, this MUST include "wampcra". Leave nil for anonymous.
    ///   - authid: Is the authentication ID (e.g. username) the client wishes to authenticate as. For WAMP-CRA, this MUST be provided. Leave nil for anonymous.
    ///   - authrole: The desired role inside the realm. Refer to routers documentation. Leave nil if auth not required by router like Crossbario/Crossbar docker image.
    ///   - authextra: Application-specific information. Refer to routers documentation. Leave nil if auth not required by router like Crossbario/Crossbar docker image.
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
    
    /// Is web socket connected to router
    /// - Returns: true if connected to wamp router
    final public func isConnected() -> Bool {
        return self.sessionId != nil
    }
    
    /// Create websocket connecting with wamp router
    final public func connect() {
        self.transport.connect()
    }
    
    
    /// Disconnect websocket connection with wamp router
    /// - Parameter reason: Use wamp URI format. Default reason = "wamp.close.close_realm" if custom reason is not provided.
    final public func disconnect(_ reason: String="wamp.close.close_realm") {
        self.sendMessage(GoodbyeWampMessage(details: [:], reason: reason))
    }
    
    // TODO: Add option for delegate instead of callbacks
    
    // MARK: Caller role
    // Using delegate
    /// Call a remote procedure
    ///
    /// Implement the following WampSessionDelegate methods
    /// - func wampCallSuccessful(details: [String: Any], results: [Any]?, kwResults: [String: Any]?)
    /// - func wampCallError(details: [String: Any], error: String, args: [Any]?, kwargs: [String: Any]?)
    /// - Parameters:
    ///   - proc: The URI of the procedure to be called. e.g. "com.myapp.someremoteprocedure"
    ///   - options: Dictionary that allows to provide additional call request details in an extensible way. The dictionary may be empty or nil.
    ///   - args: List of positional call arguments (each of arbitrary type). The list may be of zero length or nil.
    ///   - kwargs: Dictionary of keyword call arguments (each of arbitrary type). The dictionary may be empty or nil.
    open func call(_ proc: String, options: [String: Any]=[:], args: [Any]?=nil, kwargs: [String: Any]?=nil) {
        let callRequestId = self.generateRequestId()
        // Tell router to dispatch call
        self.sendMessage(CallWampMessage(requestId: callRequestId, options: options, proc: proc, args: args, kwargs: kwargs))
        // Store request ID to handle result
        self.callRequests[callRequestId] = (callback: nil, errorCallback: nil )
    }
    
    // Using Callbacks
    /// Call a remote procedure using callbacks
    /// - Parameters:
    ///   - proc: The URI of the procedure to be called. e.g. "com.someapp.myremoteprocedure"
    ///   - options: Dictionary that allows to provide additional call request details in an extensible way. The dictionary may be empty or nil.
    ///   - args: List of positional call arguments (each of arbitrary type). The list may be of zero length or nil.
    ///   - kwargs: Dictionary of keyword call arguments (each of arbitrary type). The dictionary may be empty or nil.
    ///   - onSuccess: Called when successful response from procedure containing response.
    ///   - onError: Called if an error occurs.
    open func call(_ proc: String, options: [String: Any]=[:], args: [Any]?=nil, kwargs: [String: Any]?=nil, onSuccess: CallCallback, onError: ErrorCallCallback) {
        let callRequestId = self.generateRequestId()
        // Tell router to dispatch call
        self.sendMessage(CallWampMessage(requestId: callRequestId, options: options, proc: proc, args: args, kwargs: kwargs))
        // Store request ID to handle result
        self.callRequests[callRequestId] = (callback: onSuccess, errorCallback: onError )
    }
    
    // MARK: Callee role
    
    // Delegate
    /// Register a remote procedure
    ///
    /// Implement the following WampSessionDelegate methods
    /// - func wampRegistrationSuccessful(_ registration: Registration)
    /// - func wampRegistrationError(details: [String: Any], error: String)
    /// - func wampProcedureCalled(details: [String: Any], args: [Any]?, kwargs: [String: Any]?) -> (options: [String:Any], args: [Any], kwargs: [String: Any])?
    /// - Parameters:
    ///   - proc: The URI of the procedure being served. e.g. "com.myapp.myprocedure"
    ///   - options: Dictionary that allows to provide additional call request details in an extensible way. The dictionary may be empty or nil.
    public func register(_ proc: String, options: [String: Any]=[:]) {
        // TODO: assert topic is a valid WAMP uri
        // https://crossbar.io/docs/URI-Format/

        // Generate requestID
        let registerRequestId = self.generateRequestId()

        self.sendMessage(RegisterWampMessage(requestId: registerRequestId, options: options, proc: proc))

        // Store request ID to handle result
        self.registerRequests[registerRequestId] = (onSuccess: nil, onError: nil, onFire: nil)
    }
    
    // Callbacks
    /// Register a remote procedure using callbacks
    /// - Parameters:
    ///   - proc: The URI of the procedure being served. e.g. "com.myapp.myprocedure"
    ///   - options: Dictionary that allows to provide additional call request details in an extensible way. The dictionary may be empty or nil.
    ///   - onSuccess: Called when registration is successful with wamp router.
    ///   - onError: Called if an error occurs.
    ///   - onFire: Called when responding to a call for named procedure.
    public func register(_ proc: String, options: [String: Any]=[:], onSuccess: RegisterCallback, onError: ErrorRegisterCallback, onFire: WampProcedure) {
        // TODO: assert topic is a valid WAMP uri
        // https://crossbar.io/docs/URI-Format/

        // Generate requestID
        let registerRequestId = self.generateRequestId()

        self.sendMessage(RegisterWampMessage(requestId: registerRequestId, options: options, proc: proc))

        // Store request ID to handle result
        self.registerRequests[registerRequestId] = (onSuccess: onSuccess, onError: onError, onFire: onFire)
    }
    
    internal func unregister(_ registration: Int, onSuccess: @escaping UnregisterCallback, onError: @escaping ErrorUnregsiterCallback) {
        let unregisterRequestId = self.generateRequestId()
        // Tell router to unregister procedure
        self.sendMessage(UnregisterWampMessage(requestId: unregisterRequestId, registration: registration))
        // Store request ID to handle result
        self.unregisterRequests[unregisterRequestId] = (registration, onSuccess, onError)
    }
    
    // MARK: Subscriber role
    // Using delegate
    /// Subscribe to a published topic
    ///
    /// Implement the following WampSessionDelegate methods.
    /// - func wampSubEventReceived(details: [String: Any], results: [Any]?, kwargs: [String: Any]?)
    /// - func wampSubSuccessful(_ subscription: Subscription)
    /// - func wampSubError(details: [String: Any], error: String)
    /// - Parameters:
    ///   - topic: The URI of the topic to subscribe to. e.g. "com.someapp.publishedprocedure"
    ///   - options: Dictionary that allows to provide additional call request details in an extensible way. The dictionary may be empty or nil.
    open func subscribe(_ topic: String, options: [String: Any]=[:]) {
        // TODO: assert topic is a valid WAMP uri
        // https://crossbar.io/docs/URI-Format/
        
        // Generate requestId
        let subscribeRequestId = self.generateRequestId()
        
        // Store request ID to handle result
        self.subscribeRequests[subscribeRequestId] = (callback: nil, errorCallback: nil, eventCallback: nil)
        
        // Tell router to subscribe client on a topic
        self.sendMessage(SubscribeWampMessage(requestId: subscribeRequestId, options: options, topic: topic))
        
    }
    
    
    // Using Callbacks
    /// Subscribe to a published procedure using callbacks
    /// - Parameters:
    ///   - topic: The URI of the topic to subscribe to. e.g. "com.someapp.publishedprocedure"
    ///   - options: Dictionary that allows to provide additional call request details in an extensible way. The dictionary may be empty or nil.
    ///   - onSuccess: Called when subscription is successful with wamp router.
    ///   - onError: Called if an error occurs.
    ///   - onEvent: Called when procedure event is received.
    open func subscribe(_ topic: String, options: [String: Any]=[:], onSuccess: SubscribeCallback, onError: ErrorSubscribeCallback, onEvent: EventCallback) {
        // TODO: assert topic is a valid WAMP uri
        // https://crossbar.io/docs/URI-Format/
        
        // Generate requestId
        let subscribeRequestId = self.generateRequestId()
        
        // Store request ID to handle result
        self.subscribeRequests[subscribeRequestId] = (callback: onSuccess, errorCallback: onError, eventCallback: onEvent)
        
        // Tell router to subscribe client on a topic
        self.sendMessage(SubscribeWampMessage(requestId: subscribeRequestId, options: options, topic: topic))
        
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
    // Using delegate
    /// Publish a topic
    ///
    /// Implement the following WampSessionDelegate methods.
    /// - func wampPubSuccessful()
    /// - func wampPubError(details: [String: Any], error: String)
    /// - Parameters:
    ///   - topic: The URI of the topic being published e.g. "com.myapp.mytopic
    ///   - options: Dictionary that allows to provide additional call request details in an extensible way. The dictionary may be empty or nil.
    ///   - args: List of positional call arguments (each of arbitrary type). The list may be of zero length or nil.
    ///   - kwargs: Dictionary of keyword call arguments (each of arbitrary type). The dictionary may be empty or nil.
    open func publish(_ topic: String, options: [String: Any]=[:], args: [Any]?=nil, kwargs: [String: Any]?=nil) {
        // add acknowledge to options, so we get callbacks
        var options = options
        options["acknowledge"] = true
        // TODO: assert topic is a valid WAMP uri
        let publishRequestId = self.generateRequestId()
        // Tell router to publish the event
        self.sendMessage(PublishWampMessage(requestId: publishRequestId, options: options, topic: topic, args: args, kwargs: kwargs))
        // Store request ID to handle result
        self.publishRequests[publishRequestId] = (callback: nil, errorCallback: nil)
    }
    
    // Using callbacks
    /// Publish a topic
    /// - Parameters:
    ///   - topic: The URI of the topic being published e.g. "com.myapp.mytopic
    ///   - options: Dictionary that allows to provide additional call request details in an extensible way. The dictionary may be empty or nil.
    ///   - args: List of positional call arguments (each of arbitrary type). The list may be of zero length or nil.
    ///   - kwargs: Dictionary of keyword call arguments (each of arbitrary type). The dictionary may be empty or nil.
    ///   - onSuccess: Called when router confirms successful publish.
    ///   - onError: Called if an error occurs.
    open func publish(_ topic: String, options: [String: Any]=[:], args: [Any]?=nil, kwargs: [String: Any]?=nil, onSuccess: PublishCallback, onError: ErrorPublishCallback) {
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
    
    
    
    // MARK: Wamp Transport Delegate
    
    public func wampTransportDidDisconnect(_ reason: String, code: UInt16) {
        self.delegate?.wampSessionEnded(reason)
    }
    
    public func wampTransportDidConnect() {
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
    
    public func wampTransportReceivedData(_ data: Data) {
        //TODO: Get rid of swifty json
        if let payload = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any], let message = WampMessages.createMessage(payload) {
            self.handleMessage(message)
        }
    }
    
    // MARK: Handle Messages
    
    fileprivate func handleMessage(_ message: WampMessage) {
        switch message {
        // MARK: Auth responses
        case let message as ChallengeWampMessage:
            if let authResponse = self.delegate?.wampSessionHandleChallenge(authMethod: message.authMethod, challenge: message.extra) {
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
            if message.reason != "wamp.error.disconnectSwiftWAMP" {
                // Means it's not our initiated goodbye, and we should reply with goodbye
                self.sendMessage(GoodbyeWampMessage(details: [:], reason: "wamp.close.close_realm"))
            }
            self.transport.disconnect(message.reason)
            
            
        case let message as AbortWampMessage:
            delegate?.wampSessionEnded(message.reason)
            self.transport.disconnect(message.reason)
            
            
            
        // MARK: Call role
        
        case let message as ResultWampMessage:
            let requestId = message.requestId
            if let (callback, _) = self.callRequests.removeValue(forKey: requestId) {
                callback?(message.details, message.results, message.kwResults)
                delegate?.wampCallSuccessful(details: message.details, results: message.results, kwResults: message.kwResults)
            } else {
                // TODO: log this erroneous situation
            }
            
        
        // MARK: Callee role
        
        case let message as RegisteredWampMessage:
            let requestId = message.requestId
            if let (callback, _, wampProc) = self.registerRequests.removeValue(forKey: requestId) {
                let registration = Registration(session: self, registration: message.registration, wampProc: wampProc)
                callback?(registration)
                delegate?.wampRegistrationSuccessful(registration)
                // Registration succeeded, we should store event callback for when it's fired
                self.registrations[message.registration] = registration
            }
            
        // Invocation is received when a call has been made to a registered procedure
        case let message as InvocationWampMessage:
            if let registration = registrations[message.registration] {
                // if wampProc nil then delegate must be in use
                if let (options, args, kwargs) = registration.wampProc?(message.details, message.args, message.kwargs) {
                    self.sendYieldMessage(requestId: message.requestId, options: options, args: args, kwargs: kwargs)
                } else if let (options, args, kwargs) = delegate?.wampProcedureCalled(details: message.details, args: message.args, kwargs: message.kwargs) {
                    self.sendYieldMessage(requestId: message.requestId, options: options, args: args, kwargs: kwargs)
                }
            } else {
                // TODO: log this erroneous situation
            }
            
            
        case let message as UnregisteredWampMessage:
            let requestId = message.requestId
            if let (registrationNum, success, _) = self.unregisterRequests.removeValue(forKey: requestId),
               let registration = self.registrations.removeValue(forKey: registrationNum){
                registration.invalidate()
                success()
                delegate?.wampUnregisterSuccessful(registration)
            } else {
                // TODO: log this erroneous situation
            }
            
            
        // MARK: Subscriber role
        case let message as SubscribedWampMessage:
            let requestId = message.requestId
            if let (callback, _, eventCallback) = self.subscribeRequests.removeValue(forKey: requestId) {
                // Notify user and delegate him to unsubscribe this subscription
                let subscription = Subscription(session: self, subscription: message.subscription, onEvent: eventCallback)
                callback?(subscription)
                delegate?.wampSubSuccessful(subscription)
                // Subscription succeeded, we should store event callback for when it's fired
                self.subscriptions[message.subscription] = subscription
            } else {
                // TODO: log this erroneous situation
            }
            
            
        case let message as EventWampMessage:
            if let subscription = self.subscriptions[message.subscription] {
                subscription.eventCallback?(message.details, message.args, message.kwargs)
                delegate?.wampSubEventReceived(details: message.details, results: message.args, kwargs: message.kwargs)
            } else {
                // TODO: log this erroneous situation
            }
            
            
        case let message as UnsubscribedWampMessage:
            let requestId = message.requestId
            if let (subscription, callback, _) = self.unsubscribeRequests.removeValue(forKey: requestId) {
                if let subscription = self.subscriptions.removeValue(forKey: subscription) {
                    subscription.invalidate()
                    callback()
                    delegate?.wampUnsubscribeSuccessful(subscription)
                } else {
                    // TODO: log this erroneous situation
                }
            } else {
                // TODO: log this erroneous situation
            }
            
            
        case let message as PublishedWampMessage:
            let requestId = message.requestId
            if let (callback, _) = self.publishRequests.removeValue(forKey: requestId) {
                callback?()
                delegate?.wampPubSuccessful()
            } else {
                // TODO: log this erroneous situation
            }
            
            
        ////////////////////////////////////////////
        // MARK: Handle error responses
        ////////////////////////////////////////////
        case let message as ErrorWampMessage:
            print("MESSAGE: \(message)")
            switch message.requestType {
            case .call:
                if let (_, errorCallback) = self.callRequests.removeValue(forKey: message.requestId) {
                    errorCallback?(message.details, message.error, message.args, message.kwargs)
                    delegate?.wampCallError(details: message.details, error: message.error, args: message.args, kwargs: message.kwargs)
                } else {
                    // TODO: log this erroneous situation
                }
            case .subscribe:
                if let (_, errorCallback, _) = self.subscribeRequests.removeValue(forKey: message.requestId) {
                    errorCallback?(message.details, message.error)
                    delegate?.wampSubError(details: message.details, error: message.error)
                } else {
                    // TODO: log this erroneous situation
                }
            case .unsubscribe:
                if let (_, _, errorCallback) = self.unsubscribeRequests.removeValue(forKey: message.requestId) {
                    errorCallback(message.details, message.error)
                } else {
                    // TODO: log this erroneous situation
                }
            case .publish:
                if let(_, errorCallback) = self.publishRequests.removeValue(forKey: message.requestId) {
                    errorCallback?(message.details, message.error)
                    delegate?.wampPubError(details: message.details, error: message.error)
                } else {
                    // TODO: log this erroneous situation
                }
            case .register:
                if let(_, errorCallback, _) = self.registerRequests.removeValue(forKey: message.requestId) {
                    errorCallback?(message.details, message.error)
                    delegate?.wampRegistrationError(details: message.details, error: message.error)
                } else {
                    // TODO: log this erroneous situation
                }
            case .unregister:
                if let(_, _, errorCallback) = self.unregisterRequests.removeValue(forKey: message.requestId) {
                    errorCallback(message.details, message.error)
                    delegate?.wampUnregisterError(details: message.details, error: message.error)
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
    
    fileprivate func sendMessage(_ message: WampMessage) {
        let marshalledMessage = message.marshal()
        if let data = try? JSONSerialization.data(withJSONObject: marshalledMessage, options: []) {
            self.transport.sendData(data)
        }
    }
    
    fileprivate func sendYieldMessage(requestId: Int, options: [String: Any], args: [Any]?, kwargs: [String: Any]?) {
        let message = YieldWampMessage(requestId: requestId, options: options, args: args, kwargs: kwargs)
        let marshalledMessage = message.marshal()
        if let data = try? JSONSerialization.data(withJSONObject: marshalledMessage, options: []) {
            self.transport.sendData(data)
        }
    }
    
    fileprivate func generateRequestId() -> Int {
        self.currRequestId += 1
        return self.currRequestId
    }
}

extension WampSession: Equatable {
    // Websocket session id
    public static func == (lhs: WampSession, rhs: WampSession) -> Bool {
        lhs.sessionId == rhs.sessionId
    }
}
