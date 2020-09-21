//
//  WampSerializer.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

public protocol WampSerializer {
    func pack(_ data: [Any]) -> Data?
    func unpack(_ data: Data) -> [Any]?
}