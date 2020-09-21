//
//  PublishedWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

/// [PUBLISHED, requestId|number, options|dict, topic|String, args|list?, kwargs|dict?]
class PublishedWampMessage: WampMessage {
    
    let requestId: Int
    let publication: Int
    
    init(requestId: Int, publication: Int) {
        self.requestId = requestId
        self.publication = publication
    }
    
    // MARK: WampMessage protocol
    required init(payload: [Any]) {
        self.requestId = payload[0] as! Int
        self.publication = payload[1] as! Int
    }
    
    func marshal() -> [Any] {
        let marshalled: [Any] = [WampMessages.published.rawValue, self.requestId, self.publication]
        return marshalled
    }
}