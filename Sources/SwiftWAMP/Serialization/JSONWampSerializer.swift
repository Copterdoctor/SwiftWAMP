//
//  JSONWampSerializer.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation
import SwiftyJSON

class JSONWampSerializer: WampSerializer {
    
    public init() {}
    
    open func pack(_ data: [Any]) -> Data? {
        let json = JSON(data)
        do {
            return try json.rawData()
        }
        catch {
            return nil
        }
    }
    
    open func unpack(_ data: Data) -> [Any]? {
        let json = JSON(data: data)
        return json.arrayObject as [Any]?
    }
}