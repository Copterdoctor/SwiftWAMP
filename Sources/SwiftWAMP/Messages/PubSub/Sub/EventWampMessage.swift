//
//  EventWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

/// [EVENT, subscription|number, publication|number, details|dict, args|list?, kwargs|dict?]
class EventWampMessage: WampMessage {
    
    let subscription: Int
    let publication: Int
    let details: [String: Any]
    
    let args: [Any]?
    let kwargs: [String: Any]?
    
    init(subscription: Int, publication: Int, details: [String: Any], args: [Any]?=nil, kwargs: [String: Any]?=nil) {
        self.subscription = subscription
        self.publication = publication
        self.details = details
        
        self.args = args
        self.kwargs = kwargs
    }
    
    // MARK: WampMessage protocol
    
    required init(payload: [Any]) {
        self.subscription = payload[0] as! Int
        self.publication = payload[1] as! Int
        self.details = payload[2] as! [String: Any]
        self.args = payload[safe: 3] as? [Any]
        self.kwargs = payload[safe: 4] as? [String: Any]
    }
    
    func marshal() -> [Any] {
        var marshalled: [Any] = [WampMessages.event.rawValue, self.subscription, self.publication, self.details]
        
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
