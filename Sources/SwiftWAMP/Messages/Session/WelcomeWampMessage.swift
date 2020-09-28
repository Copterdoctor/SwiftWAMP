//
//  WelcomeWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

/// [WELCOME, sessionId|number, details|Dict]
class WelcomeWampMessage: WampMessage {
    
    let sessionId: Int
    let details: [String: Any]
    
    init(sessionId: Int, details: [String: Any]) {
        self.sessionId = sessionId
        self.details = details
    }
    
    // MARK: WampMessage protocol
    
    required init(payload: [Any]) {
        self.sessionId = payload[0] as! Int
        self.details = payload[1] as! [String: Any]
    }
    
    func marshal() -> [Any] {
        return [WampMessages.welcome.rawValue, self.sessionId, self.details]
    }
}
