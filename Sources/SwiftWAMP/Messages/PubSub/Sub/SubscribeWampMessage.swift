//
//  SubscribeWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

/// [SUBSCRIBE, requestId|number, options|dict, topic|string] 
class SubscribeWampMessage: WampMessage {
    
    let requestId: Int
    let options: [String: Any]
    let topic: String
    
    init(requestId: Int, options: [String: Any], topic: String) {
        self.requestId = requestId
        self.options = options
        self.topic = topic
    }
    
    // MARK: WampMessage protocol
    required init(payload: [Any]) {
        self.requestId = payload[0] as! Int
        self.options = payload[1] as! [String: Any]
        self.topic = payload[2] as! String
    }
    
    func marshal() -> [Any] {
        return [WampMessages.subscribe.rawValue, self.requestId, self.options, self.topic]
    }
}
