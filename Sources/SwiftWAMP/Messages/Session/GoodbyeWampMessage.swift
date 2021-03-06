//
//  GoodbyeWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

/// [GOODBYE, details|dict, reason|uri]
class GoodbyeWampMessage: WampMessage {
    
    let details: [String: Any]
    let reason: String
    
    init(details: [String: Any], reason: String) {
        self.details = details
        self.reason = reason
    }
    
    // MARK: WampMessage protocol
    
    required init(payload: [Any]) {
        self.details = payload[0] as! [String: Any]
        self.reason = payload[1] as! String
    }
    
    func marshal() -> [Any] {
        return [WampMessages.goodbye.rawValue, self.details, self.reason]
    }
}
