//
//  File.swift
//  
//
//  Created by Gil Biren on 28/01/2020.
//

import Foundation

public struct CacheData: Cachable {
    let name: String
    let data: Data?
    
    public  init(name: String, data: Data?) {
        self.name = name
        self.data = data
    }
}
