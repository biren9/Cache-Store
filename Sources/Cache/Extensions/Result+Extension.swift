//
//  File.swift
//  
//
//  Created by fluidmobile on 29/01/2020.
//

import Foundation

extension Result where Success == Void {
    static var success: Result {
        return .success(())
    }
}
