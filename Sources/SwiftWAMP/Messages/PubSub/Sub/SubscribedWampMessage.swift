//
//  SubscribedWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

/// [SUBSCRIBED, requestId|number, subscription|number]
class SubscribedWampMessage: WampMessage {
    
    let requestId: Int
    let subscription: Int
    
    init(requestId: Int, subscription: Int) {
        self.requestId = requestId
        self.subscription = subscription
    }
    
    // MARK: WampMessage protocol
    
    required init(payload: [Any]) {
        self.requestId = payload[0] as! Int
        self.subscription = payload[1] as! Int
    }
    
    func marshal() -> [Any] {
        return [WampMessages.subscribed.rawValue, self.requestId, self.subscription]
    }
}
