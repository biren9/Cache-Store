//
//  File.swift
//  
//
//  Created by Gil Biren on 29/01/2020.
//

import Foundation


#if canImport(UIKit)
import UIKit

public struct CacheImage: Cachable {
    public let name: String
    public let image: UIImage?
    public var data: Data? {
        return image?.pngData()
    }
    
    public init(name: String, image: UIImage) {
        self.name = name
        self.image = image
    }
    
    public init(name: String, data: Data?) {
        self.name = name
        if let data = data {
            image = UIImage(data: data)
        } else {
            image = nil
        }
    }
}

#endif

#if os(macOS)
import AppKit

public struct CacheImage: Cachable {
    public let name: String
    public let image: NSImage?
    public var data: Data? {
        image?.pngData()
    }
    
    public init(name: String, image: NSImage) {
        self.name = name
        self.image = image
    }
    
    public init(name: String, data: Data?) {
        self.name = name
        if let data = data {
            image = NSImage(data: data)
        } else {
            image = nil
        }
    }
}

#endif

