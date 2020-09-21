//
//  WampTransport.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation

protocol WampTransportDelegate {
    func wampTransportDidConnectWithSerializer(_ serializer: WampSerializer)
    func wampTransportDidDisconnect(_ error: NSError?, reason: String?)
    func wampTransportReceivedData(_ data: Data)
}

protocol WampTransport {
    var delegate: WampTransportDelegate? { get set }
    func connect()
    func disconnect(_ reason: String)
    func sendData(_ data: Data)
}
