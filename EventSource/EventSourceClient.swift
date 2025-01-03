//
//  EventSourceClient.swift
//  
//
//  Created by Kai Shao on 2024/6/12.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum EventSourceClientError: Error {
    case non200Status(Int), unauthorized
}

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
                    return
                }
                
                if let status {
                    if String(status).first == "2" {
                        continuation.finish()
                        return
                    }
                    
                    if status == 401 {
                        continuation.finish(throwing: EventSourceClientError.unauthorized)
                        return
                    }
                    
                    if status > 201 {
                        continuation.finish(throwing: EventSourceClientError.non200Status(status))
                        return
                    }
                }
                
                continuation.finish()
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
