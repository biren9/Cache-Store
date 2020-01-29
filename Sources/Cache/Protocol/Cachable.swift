//
//  File.swift
//  
//
//  Created by Gil Biren on 28/01/2020.
//

import Foundation

public protocol Cachable {
    var name: String { get }
    var data: Data? { get }
    
    init(name: String, data: Data?)
}
