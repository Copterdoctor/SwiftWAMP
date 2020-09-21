//
//  WelcomeWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation
import SwiftyJSON

/// [WELCOME, sessionId|number, details|Dict]
class WelcomeWampMessage: WampMessage {
    
    let sessionId: Int
    let details: [String: AnyObject]
    
    init(sessionId: Int, details: [String: AnyObject]) {
        self.sessionId = sessionId
        self.details = details
    }
    
    // MARK: WampMessage protocol
    
    required init(payload: [Any]) {
        self.sessionId = payload[0] as! Int
        self.details = payload[1] as! [String: AnyObject]
    }
    
    func marshal() -> [Any] {
        return [WampMessages.welcome.rawValue, self.sessionId, self.details]
    }
}
