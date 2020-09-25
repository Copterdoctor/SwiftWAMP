//
//  WampSessionDelegate.swift
//  
//
//  Created by Jordan Anders on 2020-09-24.
//

import Foundation

public protocol WampSessionDelegate {
    func wampSessionHandleChallenge(_ authMethod: String, extra: [String: Any]) -> String
    func wampSessionConnected(_ session: WampSession, sessionId: Int)
    func wampSessionEnded(_ reason: String)
    
    func wampSubEventReceived(details: [String: AnyObject], results: [AnyObject]?, kwargs: [String: AnyObject]?)
    func wampSubSuccessful(_ subscription: Subscription)
    func wampSubError(details: [String: Any], error: String)
    
    func wampPubSuccessful()
    func wampPubError(details: [String: Any], error: String)
    
    func wampCallSuccessful(details: [String: Any], results: [Any]?, kwResults: [String: Any]?)
    func wampCallError(details: [String: Any], error: String, args: [Any]?, kwargs: [String: Any]?)
    
}

// MARK: Default implementations

extension WampSessionDelegate {
    
    // Example use of of Authentication
    func wampSessionHandleChallenge(_ authMethod: String, extra: [String: Any]) -> String {
        return WampCraAuthHelper.sign("my_secret", challenge: extra["challenge"] as! String)
    }
    
    // MARK: Delegate Alternatives to callbacks
    // MARK: Subscriptions
    func wampSubEventReceived(details: [String: AnyObject], results: [AnyObject]?, kwargs: [String: AnyObject]?) {}
    func wampSubSuccessful(_ subscription: Subscription) {}
    func wampSubError(details: [String: Any], error: String) {}
    
    
    // MARK: Publish
    func wampPubSuccessful() {}
    func wampPubError(details: [String: Any], error: String) {}
    
    // MARK: Caller
    func wampCallSuccessful(details: [String: Any], results: [Any]?, kwResults: [String: Any]?) {}
    func wampCallError(details: [String: Any], error: String, args: [Any]?, kwargs: [String: Any]?) {}
}
