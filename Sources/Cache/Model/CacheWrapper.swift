//
//  File.swift
//  
//
//  Created by Gil Biren on 06/10/2020.
//

import Foundation

public struct CacheWrapper<T: Codable>: Cachable {
    public let name: String
    public let value: T?
    public var data: Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(value)
    }
    
    public init(name: String, value: T) {
        self.name = name
        self.value = value
    }
    
    public init(name: String, data: Data?) {
        self.name = name
        if let data = data {
            let decoder = JSONDecoder()
            value = try? decoder.decode(T.self, from: data)
        } else {
            value = nil
        }
    }
}
