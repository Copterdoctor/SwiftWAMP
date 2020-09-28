//
//  WampSessionDelegate.swift
//  
//
//  Created by Jordan Anders on 2020-09-24.
//

import Foundation

public protocol WampSessionDelegate {
    
    
    ///  Called to respond to CHALLANGE phase of establishing session If router requires authentication
    ///
    /// This is not required if authentication is not required for router.
    ///
    /// The client needs to compute the signature as follows:
    
    ///    signature = HMAC[SHA256]_{secret} (challenge)
    ///
    /// That is, compute the HMAC-SHA256 using the shared secret over the challenge.
    ///
    /// After computing the signature, the client will send an AUTHENTICATE message containing the signature, as a base64-encoded string:
    ///
    /// Use WampCraAuthHelper to respond to challenge and authenticate.
    ///
    ///  return WampCraAuthHelper.sign("my_secret", challenge: challenge["challenge"] as! String)
    /// 
    /// - Parameters:
    ///   - authMethod: Used by the client to announce the authentication methods it is prepared to perform. e.g.  "wampcra".
    ///   - challenge: Is a string the client needs to create a signature for
    func wampSessionHandleChallenge(authMethod: String, challenge: [String: Any]) -> String
    
    
    /// Called when session is created and websocket connection established
    /// - Parameters:
    ///   - session: Intance of WampSession created
    ///   - sessionId: Session id created by wamp router
    func wampSessionConnected(_ session: WampSession, sessionId: Int)
    
    
    /// Called when session has ended
    /// - Parameter reason: wamp URI formatted reason for session end. e.g. wamp.close.goodbye_and_out
    func wampSessionEnded(_ reason: String)
    
    
    /// Called when a subscribed topic event is received
    /// - Parameters:
    ///   - details: Dictionary that allows the Broker to provide additional event details in a extensible way.
    ///   - results: Array of positional event arguments (each of arbitrary type). e.g. ["Hello world", 1, 2, 3]
    ///   - kwargs: Dictionary of keyword event arguments (each of arbitrary type). Keys must be of type String. e.g. ["UserName": "SwiftWAMP", "UserId": 1]
    func wampSubEventReceived(details: [String: Any], results: [Any]?, kwargs: [String: Any]?)
    
    
    /// Called when subscription to a topic is successfully created
    /// - Parameter subscription: Instance of subscription created
    func wampSubSuccessful(_ subscription: Subscription)
    
    
    /// Called when an error occurs trying to subscribe to a topic
    /// - Parameters:
    ///   - details: Dictionary that allows the Broker to provide additional event details in a extensible way.
    ///   - error: wamp URI error. e.g. "wamp.error.not_authorized"
    func wampSubError(details: [String: Any], error: String)
    
    
    /// Called when unsubscription of topic request is successful
    /// - Parameter subscription: Instance of subscription that was unsubscribed. subscription.isActive = false.
    func wampUnsubscribeSuccessful(_ subscription: Subscription)
    
    
    /// Called when there is an error requesting unsubscription from topic
    /// - Parameters:
    ///   - details: Dictionary that allows the Broker to provide additional event details in a extensible way.
    ///   - error: wamp URI error. e.g. "wamp.error.no_such_subscription"
    func wampUnsubscribeError(details: [String: Any], error: String)
    
    
    /// Called when publication of topic is successful
    func wampPubSuccessful()
    
    
    /// Called when an error occurs trying to publish a topic
    /// - Parameters:
    ///   - details: Dictionary that allows the Broker to provide additional event details in a extensible way.
    ///   - error: wamp URI error. e.g. "wamp.error.not_authorized"
    func wampPubError(details: [String: Any], error: String)
    
    
    /// Called when call for remote procedure is successful
    /// - Parameters:
    ///   - details: Dictionary that allows the Broker to provide additional event details in a extensible way.
    ///   - results: Array of positional topic arguments (each of arbitrary type). e.g. ["Hello world", 1, 2, 3]
    ///   - kwresults: Dictionary of keyword topic arguments (each of arbitrary type). Keys must be of type String. e.g. ["UserName": "SwiftWAMP", "UserId": 1]
    func wampCallSuccessful(details: [String: Any], results: [Any]?, kwResults: [String: Any]?)
    
    
    /// Called when an error occurs when trying to call a remote procedure
    /// - Parameters:
    ///   - details: Dictionary that allows the Broker to provide additional event details in a extensible way.
    ///   - error: wamp URI error. e.g. "wamp.error.not_authorized"
    ///   - args: Array of positional topic arguments (each of arbitrary type). e.g. ["Hello world", 1, 2, 3]
    ///   - kwargs: Dictionary of keyword topic arguments (each of arbitrary type). Keys must be of type String. e.g. ["UserName": "SwiftWAMP", "UserId": 1]
    func wampCallError(details: [String: Any], error: String, args: [Any]?, kwargs: [String: Any]?)
    
    
    /// Called when registration of remote procedure is successful
    /// - Parameter registration: Instance of registration for procedure
    func wampRegistrationSuccessful(_ registration: Registration)
    
    
    /// Called when an error occurs trying to register a remote procedure
    /// - Parameters:
    ///   - details: Dictionary that allows the Broker to provide additional event details in a extensible way.
    ///   - error: wamp URI error. e.g. "wamp.error.procedure_already_exists"
    func wampRegistrationError(details: [String: Any], error: String)
    
    
    /// Called when your registered remote procedure is called
    /// - Parameters:
    ///   - details: Dictionary that allows the Broker to provide additional event details in a extensible way.
    ///   - args: Array of positional topic arguments (each of arbitrary type). e.g. ["Hello world", 1, 2, 3]
    ///   - kwargs: Dictionary of keyword topic arguments (each of arbitrary type). Keys must be of type String. e.g. ["UserName": "SwiftWAMP", "UserId": 1]
    /// - Returns:
    ///     Method returns a tuple of options, args and kwargs to be sent to the caller.
    ///   - options: dictionary that allows to provide additional options. Similiar to details.
    ///   - args: Array of positional topic arguments (each of arbitrary type). e.g. ["Hello world", 1, 2, 3]
    ///   - kargs: Dictionary of keyword topic arguments (each of arbitrary type). Keys must be of type String. e.g. ["UserName": "SwiftWAMP", "UserId": 1]
    func wampProcedureCalled(details: [String: Any], args: [Any]?, kwargs: [String: Any]?) -> (options: [String:Any], args: [Any], kwargs: [String: Any])?
    
    
    /// Called when unregistering a procedure is successful
    /// - Parameter registration: Instance or unregistered registration.
    func wampUnregisterSuccessful(_ registration: Registration)
    
    
    /// Called when an error occurs unregistering a procedure
    /// - Parameters:
    ///   - details: Dictionary that allows the Broker to provide additional event details in a extensible way.
    ///   - error: wamp URI error. e.g. "wamp.error.no_such_registration"
    func wampUnregisterError(details: [String: Any], error: String)
    
}

// MARK: Default implementations

extension WampSessionDelegate {
    
    // Example use of of Authentication
    func wampSessionHandleChallenge(authMethod: String, challenge: [String: Any]) -> String {
        return WampCraAuthHelper.sign("my_secret", challenge: challenge["challenge"] as! String)
    }
    
    // MARK: Delegate Alternatives to callbacks
    
    // MARK: Subscriptions
    func wampSubEventReceived(details: [String: Any], results: [Any]?, kwargs: [String: Any]?) {}
    func wampSubSuccessful(_ subscription: Subscription) {}
    func wampSubError(details: [String: Any], error: String) {}
    
    // MARK: Unsubscribe
    func wampUnsubscribeSuccessful(_ subscription: Subscription) {}
    func wampUnsubscribeError(details: [String: Any], error: String) {}
    
    // MARK: Publish
    func wampPubSuccessful() {}
    func wampPubError(details: [String: Any], error: String) {}
    
    // MARK: Caller
    func wampCallSuccessful(details: [String: Any], results: [Any]?, kwResults: [String: Any]?) {}
    func wampCallError(details: [String: Any], error: String, args: [Any]?, kwargs: [String: Any]?) {}
    
    // MARK: Register
    func wampRegistrationSuccessful(_ registration: Registration) {}
    func wampRegistrationError(details: [String: Any], error: String) {}
    func wampProcedureCalled( details: [String: Any], args: [Any]?, kwargs: [String: Any]?) -> (options: [String:Any], args: [Any], kwargs: [String: Any])? { return nil }
    
    // MARK: Unregister
    func wampUnregisterSuccessful(_ registration: Registration) {}
    func wampUnregisterError(details: [String: Any], error: String) {}
}
