//
//  Result.swift
//  BearSync
//
//  Created by d4Rk on 29.10.23.
//

import Foundation

struct Response {
    var requestId: UUID
    var result: Result<any ResultType, BearComError>
    
    init?<T: ResultType>(_ type: T.Type, queryItems: [URLQueryItem]) {
        guard let requestIdString = queryItems["requestId"],
              let requestId = UUID(uuidString: requestIdString) else { return nil }
        
        self.requestId = requestId
        
        if let error = BearAPIError(queryItems: queryItems) {
            self.result = .failure(.apiError(error))
        } else if let result = T(queryItems: queryItems) {
            self.result = .success(result)
        } else {
            self.result = .failure(.unknown)
        }
    }
}
