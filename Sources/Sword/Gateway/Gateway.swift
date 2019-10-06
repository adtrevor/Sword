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
    
    var gatewayUrl: String { get set }
    
    var heartbeatPayload: Payload { get }
    
    var heartbeatQueue: DispatchQueue! { get }
    
    var isConnected: Bool { get set }
    
    var session: WebSocketClient? { get set }
    
    var wasAcked: Bool { get set }
    
    func handleDisconnect(for code: Int)
    
    func handlePayload(_ payload: Payload)
    
    func heartbeat(at interval: Int)
    
    func reconnect()
    
    func send(_ text: String, presence: Bool)
    
    func start()
    
    func stop()
    
}

extension Gateway {
    
    /// Starts the gateway connection
    func start() {
        #if !os(Linux)
        if self.session == nil {
            let cl = WebSocketClient(eventLoopGroupProvider: .createNew)
            cl.connect(host: <#T##String#>, port: <#T##Int#>, uri: <#T##String#>, headers: <#T##HTTPHeaders#>, onUpgrade: <#T##(WebSocketClient.Socket) -> ()#>)
            
            
            self.session = WebSocket(url: URL(string: self.gatewayUrl)!)
            
            
            self.session?.onConnect = { [unowned self] in
                self.isConnected = true
            }
            
            self.session?.onText = { [unowned self] text in
                self.handlePayload(Payload(with: text))
            }
            
            self.session?.onDisconnect = { [unowned self] error in
                self.isConnected = false
                
                guard let error = error else { return }
                
                self.handleDisconnect(for: (error as NSError).code)
            }
        }
        
        self.session?.connect()
        #else
        do {
            let gatewayUri = try URI(self.gatewayUrl)
            let tcp = try TCPInternetSocket(
                scheme: "https",
                hostname: gatewayUri.hostname,
                port: gatewayUri.port ?? 443
            )
            let stream = try TLS.InternetSocket(tcp, TLS.Context(.client))
            try WebSocket.connect(to: gatewayUrl, using: stream) {
                [unowned self] ws in
                
                self.session = ws
                self.isConnected = true
                
                ws.onText = { _, text in
                    self.handlePayload(Payload(with: text))
                }
                
                ws.onClose = { _, code, _, _ in
                    self.isConnected = false
                    
                    guard let code = code else { return }
                    
                    self.handleDisconnect(for: Int(code))
                }
            }
        }catch {
            print("[Sword] \(error.localizedDescription)")
            self.start()
        }
        #endif
    }
    
}
