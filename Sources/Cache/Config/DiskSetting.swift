//
//  File.swift
//  
//
//  Created by Gil Biren on 28/01/2020.
//

import Foundation

public struct DiskSetting {
    let location: Location
    let identifier: String
    let storeDuration: Duration
    let maxSize: Size
    
    public init (location: Location, identifier: String, storeDuration: Duration, maxSize: Size) {
        self.location = location
        self.identifier = identifier
        self.storeDuration = storeDuration
        self.maxSize = maxSize
    }
}

extension DiskSetting {
    public enum Location {
        case cache
        case secureContainer(String)
        case custom(URL)
    }
    
    public enum Duration {
        case seconds(Int)
        case minutes(Int)
        case hours(Int)
        case days(Int)
        
        func timeInterval() -> TimeInterval {
            switch self {
            case .seconds(let seconds):
                return TimeInterval(exactly: seconds)!
            case .minutes(let minutes):
                return TimeInterval(exactly: minutes*60)!
            case .hours(let hours):
                return TimeInterval(exactly: hours*60*60)!
            case .days(let days):
                return TimeInterval(exactly: days*60*60*24)!
            }
        }
    }

    public enum Size {
        case B(Int)
        case KB(Int)
        case MB(Int)
        case GB(Int)
        
        func byte() -> Int {
            switch self {
            case .B(let b):
                return b
            case .KB(let kb):
                return kb * 1024
            case .MB(let mb):
                return mb * 1024 * 1024
            case .GB(let gb):
                return gb * 1024 * 1024 * 1024
            }
        }
    }
}
