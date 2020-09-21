//
//  UnregisteredWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

/// [UNREGISTERED, requestId|number]
class UnregisteredWampMessage: WampMessage {
    
    let requestId: Int
    
    init(requestId: Int) {
        self.requestId = requestId
    }
    
    // MARK: WampMessage protocol
    
    required init(payload: [Any]) {
        self.requestId = payload[0] as! Int
    }
    
    func marshal() -> [Any] {
        return [WampMessages.unregistered.rawValue, self.requestId]
    }
}
