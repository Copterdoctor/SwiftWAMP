//
//  UnsubscribedWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

/// [UNSUBSCRIBED, requestId|number]
class UnsubscribedWampMessage: WampMessage {
    
    let requestId: Int
    
    init(requestId: Int) {
        self.requestId = requestId
    }
    
    // MARK: WampMessage protocol
    
    required init(payload: [Any]) {
        self.requestId = payload[0] as! Int
    }
    
    func marshal() -> [Any] {
        return [WampMessages.unsubscribed.rawValue, self.requestId]
    }
}
