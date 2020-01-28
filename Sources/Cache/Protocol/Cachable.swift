//
//  File.swift
//  
//
//  Created by Gil Biren on 28/01/2020.
//

import Foundation

protocol Cachable {
    var name: String { get }
    var content: Data? { get }
}
