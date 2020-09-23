//
//  WampSocket.swift
//  
//
//  Created by Jordan Anders on 2020-09-21.
//

import Foundation
import Starscream

open class WampSocket: WampTransport, WebSocketDelegate {
    
    open var delegate: WampTransportDelegate?
    let socket: WebSocket
    let mode: WebsocketMode
    
    fileprivate var disconnectionReason: String?
    
    public init(wsEndpoint: URL){
        var request = URLRequest(url: wsEndpoint)
        request.setValue("wamp.2.json, wamp.2.msgpack", forHTTPHeaderField: "Sec-Websocket-Protocol")
        self.socket = WebSocket(request: request)
        //            WebSocket(url: wsEndpoint, protocols: ["wamp.2.json"])
        self.mode = .text
        self.socket.delegate = self
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
    
    // Starscream V2.0
    //    open func websocketDidConnect(socket: WebSocket) {
    //        // TODO: Check which serializer is supported by the server, and choose self.mode and serializer
    //        delegate?.wampTransportDidConnectWithSerializer(JSONWampSerializer())
    //    }
    //
    //    open func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
    //        delegate?.wampTransportDidDisconnect(error, reason: self.disconnectionReason)
    //    }
    //
    //    open func websocketDidReceiveMessage(socket: WebSocket, text: String) {
    //        if let data = text.data(using: String.Encoding.utf8) {
    //            self.websocketDidReceiveData(socket: socket, data: data)
    //        }
    //    }
    //
    //    open func websocketDidReceiveData(socket: WebSocket, data: Data) {
    //        print("WEB SOCKET DID RECEIVE DATA SOCKET \(socket)")
    //        delegate?.wampTransportReceivedData(data)
    //    }
    
    // TODO: Starscream V3.0.0
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            delegate?.wampTransportDidConnectWithSerializer(JSONWampSerializer())
        case .disconnected(let reason, let code):
            delegate?.wampTransportDidDisconnect(reason, code: code)
        case .text(let string):
            if let data = string.data(using: String.Encoding.utf8) {
                delegate?.wampTransportReceivedData(data)
            }
            print("Received text: \(string)")
        case .binary(let data):
            delegate?.wampTransportReceivedData(data)
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            //                isConnected = false
            print("IS CANCELLED")
        case .error(let error):
            //                isConnected = false
            //                handleError(error)
            print("ERROR: \(error.debugDescription)")
        }
    }
}
