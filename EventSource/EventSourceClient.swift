//
//  EventSourceClient.swift
//  
//
//  Created by Kai Shao on 2024/6/12.
//

import Foundation

public class EventSourceClient {
    let request: URLRequest
    let es: EventSource
    
    public init(request: URLRequest) {
        self.request = request
        self.es = .init(urlRequest: request)
    }
    
    public var stream: AsyncThrowingStream<String, any Error> {
        .init { continuation in
            es.onComplete { status, isTrue, error in
                if let error {
                    continuation.finish(throwing: error)
                } else {
                    continuation.finish()
                }
            }
            
            es.onOpen {}
            
            es.onMessage { id, event, data in
                guard let data, data != "[DONE]" else { return }
                
                continuation.yield(data)
            }
            
            es.connect()
            
            continuation.onTermination = { _ in
                self.es.disconnect()
            }
        }
    }
}
