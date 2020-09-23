//
//  File.swift
//  
//
//  Created by Gil Biren on 29/01/2020.
//

import Foundation

extension Result where Success == Void {
    static var success: Result {
        return .success(())
    }
}
