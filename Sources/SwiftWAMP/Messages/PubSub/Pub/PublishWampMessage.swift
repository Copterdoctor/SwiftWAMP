//
//  PublishWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

/// [PUBLISH, requestId|number, options|dict, topic|String, args|list?, kwargs|dict?]
class PublishWampMessage: WampMessage {
    
    let requestId: Int
    let options: [String: Any]
    let topic: String
    
    let args: [Any]?
    let kwargs: [String: Any]?
    
    init(requestId: Int, options: [String: Any], topic: String, args: [Any]?=nil, kwargs: [String: Any]?=nil) {
        self.requestId = requestId
        self.options = options
        self.topic = topic
        
        self.args = args
        self.kwargs = kwargs
    }
    
    // MARK: WampMessage protocol
    
    required init(payload: [Any]) {
        self.requestId = payload[0] as! Int
        self.options = payload[1] as! [String: Any]
        self.topic = payload[2] as! String
        self.args = payload[safe: 3] as? [Any]
        self.kwargs = payload[safe: 4] as? [String: Any]
    }
    
    func marshal() -> [Any] {
        var marshalled: [Any] = [WampMessages.publish.rawValue, self.requestId, self.options, self.topic]
        
        if let args = self.args {
            marshalled.append(args)
            if let kwargs = self.kwargs {
                marshalled.append(kwargs)
            }
        } else {
            if let kwargs = self.kwargs {
                marshalled.append([])
                marshalled.append(kwargs)
            }
        }
        
        return marshalled
    }
}
