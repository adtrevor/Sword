//
//  Gateway.swift
//  Sword
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

import Foundation
import Dispatch
import AsyncWebSocketClient
import NIO

protocol Gateway: class {
    var eventLoop: EventLoopGroup { get }
    
    var gatewayUrl: String { get set }
    
    var heartbeatPayload: Payload { get }
    
    var heartbeatQueue: DispatchQueue! { get }
    
    var isConnected: Bool { get set }
    
    var session: WebSocketClient.Socket? { get set }
    
    var wasAcked: Bool { get set }
    
    func handleDisconnect(for code: Int)
    
    func handlePayload(_ payload: Payload)
    
    func heartbeat(at interval: Int)
    
    func reconnect() -> EventLoopFuture<Void>
    
    func send(_ text: String, presence: Bool)
    
    func start() -> EventLoopFuture<Void>
    
    func stop()
    
}

extension Gateway {
    
    /// Starts the gateway connection
    func start() -> EventLoopFuture<Void> {
        let websocketClient = WebSocketClient(eventLoopGroupProvider: .shared(self.eventLoop))
        
        guard let url = URL(string: self.gatewayUrl), let host = url.host else {
            fatalError()
        }
        
        let promise = self.eventLoop.next().makePromise(of: WebSocketClient.Socket.self)
        _ = try! websocketClient.connect(host: host, port: 443, uri: url.path) { socket in
            promise.succeed(socket)
        }.wait()
        
        return promise.futureResult.map { socket in
            self.session = socket
            self.isConnected = true
            socket.onText { [unowned self] _, text in
                self.handlePayload(Payload(with: text))
            }
            
            //FIXME: Handle errors like self.handleDisconnect() is expecting
            /*
             self.session?.onDisconnect = { [unowned self] error in
                 self.isConnected = false
                 
                 guard let error = error else { return }
                 
                 self.handleDisconnect(for: (error as NSError).code)
             }
             */
            
            socket.onClose.whenComplete { _ in
                self.isConnected = false
            }
        }
    }
    
}
