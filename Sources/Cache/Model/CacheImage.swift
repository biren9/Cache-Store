//
//  File.swift
//  
//
//  Created by fluidmobile on 29/01/2020.
//

import Foundation


#if canImport(UIKit)
import UIKit

public struct CacheImage: Cachable {
    public let name: String
    public let image: UIImage?
    var data: Data? {
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

#if canImport(AppKit)
import AppKit

struct CacheImage: Cachable {
    public let name: String
    public let image: NSImage?
    var data: Data? {
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

