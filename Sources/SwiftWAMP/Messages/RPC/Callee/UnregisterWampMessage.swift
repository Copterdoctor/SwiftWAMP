//
//  UnregisterWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

/// [UNREGISTER, requestId|number, registration|number]
class UnregisterWampMessage: WampMessage {
    
    let requestId: Int
    let registration: Int
    
    init(requestId: Int, registration: Int) {
        self.requestId = requestId
        self.registration = registration
    }
    
    // MARK: WampMessage protocol
    
    required init(payload: [Any]) {
        self.requestId = payload[0] as! Int
        self.registration = payload[1] as! Int
    }
    
    func marshal() -> [Any] {
        return [WampMessages.unregister.rawValue, self.requestId, self.registration]
    }
}
