//
//  File.swift
//  
//
//  Created by Gil Biren on 29/01/2020.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension NSImage {
    func pngData() -> Data? {
        lockFocus()
        let bitmap = NSBitmapImageRep(focusedViewRect: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        unlockFocus()
        return bitmap?.representation(using: .png, properties: [:])
    }
}

#endif

