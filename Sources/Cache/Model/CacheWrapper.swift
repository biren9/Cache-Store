//
//  File.swift
//  
//
//  Created by Gil Biren on 06/10/2020.
//

import Foundation

public struct CacheWrapper<T: Codable>: Cachable {
    public let name: String
    public let data: Data?
    
    public init(name: String, data: Data?) {
        self.name = name
        self.data = data
    }
    
    public init(name: String, value: T) {
        let encoder = JSONEncoder()
        self.name = name
        self.data = try? encoder.encode(value)
    }
 
    public func value() -> T? {
        guard let data = data else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(T.self, from: data)
    }
}
