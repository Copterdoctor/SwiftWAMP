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
}

// MARK: Default implementations

extension WampSessionDelegate {
    // Example use of of Authentication
    func wampSessionHandleChallenge(_ authMethod: String, extra: [String: Any]) -> String {
        return WampCraAuthHelper.sign("my_secret", challenge: extra["challenge"] as! String)
    }
    
    // Only required if you need to handle the ended session in your app
    func wampSessionEnded(_ reason: String) {
        return
    }
}
