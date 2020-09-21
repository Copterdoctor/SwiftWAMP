//
//  WampSocket.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation
import Starscream

class WampSocket: WampTransport, WebSocketDelegate {
    
    enum WebsocketMode {
        case binary, text
    }
    
    open var delegate: WampTransportDelegate?
    let socket: WebSocket
    let mode: WebsocketMode
    
    fileprivate var disconnectionReason: String?
    
    public init(wsEndpoint: URL){
        self.socket = WebSocket(url: wsEndpoint, protocols: ["wamp.2.json"])
        self.mode = .text
        socket.delegate = self
    }
    
    // MARK: Transport
    
    open func connect() {
        self.socket.connect()
    }
    
    open func disconnect(_ reason: String) {
        self.disconnectionReason = reason
        self.socket.disconnect()
    }
    
    open func sendData(_ data: Data) {
        if self.mode == .text {
            self.socket.write(string: String(data: data, encoding: String.Encoding.utf8)!)
        } else {
            self.socket.write(data: data)
        }
    }
    
    // MARK: WebSocketDelegate
    
    open func websocketDidConnect(socket: WebSocket) {
        // TODO: Check which serializer is supported by the server, and choose self.mode and serializer
        delegate?.wampTransportDidConnectWithSerializer(JSONwampSerializer())
    }
    
    open func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        delegate?.wampTransportDidDisconnect(error, reason: self.disconnectionReason)
    }
    
    open func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        if let data = text.data(using: String.Encoding.utf8) {
            self.websocketDidReceiveData(socket: socket, data: data)
        }
    }
    
    open func websocketDidReceiveData(socket: WebSocket, data: Data) {
        delegate?.wampTransportReceivedData(data)
    }
}
