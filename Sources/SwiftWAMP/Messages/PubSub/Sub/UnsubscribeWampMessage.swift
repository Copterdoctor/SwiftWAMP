//
//  UnsubscribeWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

/// [UNSUBSCRIBE, requestId|number, subscription|number]
class UnsubscribeWampMessage: WampMessage {
    
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
        return [WampMessages.unsubscribe.rawValue, self.requestId, self.subscription]
    }
}
