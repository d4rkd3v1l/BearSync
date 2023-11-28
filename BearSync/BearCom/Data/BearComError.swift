//
//  BearComError.swift
//  BearSync
//
//  Created by d4Rk on 29.10.23.
//

import Foundation

enum BearComError: Error {
    case unknown
    case bearAPITokenNotSet
    case apiError(BearAPIError)
}

struct BearAPIError: ResultType {
    let errorCode: Int
    let errorMessage: String
    let errorDomain: String
    
    init?(queryItems: [URLQueryItem]) {
        guard let rawErrorCode = queryItems["error-Code"],
              let errorCode = Int(rawErrorCode),
              let errorMessage = queryItems["errorMessage"],
              let errorDomain = queryItems["errorDomain"] else { return nil }
        
        self.errorCode = errorCode
        self.errorMessage = errorMessage
        self.errorDomain = errorDomain
    }
}
