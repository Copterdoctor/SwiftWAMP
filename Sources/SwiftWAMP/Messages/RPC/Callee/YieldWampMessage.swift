//
//  YieldWampMessage.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

// [YIELD, requestId|number, options|dict, args|array?, kwargs|dict?]
class YieldWampMessage: WampMessage {
    
    let requestId: Int
    let options: [String: AnyObject]
    
    let args: [AnyObject]?
    let kwargs: [String: AnyObject]?
    
    init(requestId: Int, options: [String: AnyObject], args: [AnyObject]?=nil, kwargs: [String: AnyObject]?=nil) {
        self.requestId = requestId
        self.options = options
        
        self.args = args
        self.kwargs = kwargs
    }
    
    // MARK: WampMessage protocol
    
    required init(payload: [Any]) {
        self.requestId = payload[0] as! Int
        self.options = payload[1] as! [String: AnyObject]
        self.args = payload[safe: 2] as? [AnyObject]
        self.kwargs = payload[safe: 3] as? [String: AnyObject]
    }
    
    func marshal() -> [Any] {
        var marshalled: [Any] = [WampMessages.yield.rawValue, self.requestId, self.options]
        
        if let args = self.args {
            marshalled.append(args as AnyObject)
            if let kwargs = self.kwargs {
                marshalled.append(kwargs as AnyObject)
            }
        } else {
            if let kwargs = self.kwargs {
                marshalled.append([])
                marshalled.append(kwargs as AnyObject)
            }
        }
        
        return marshalled
    }
}
