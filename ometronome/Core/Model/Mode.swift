//
//  Mode.swift
//  ometronome
//

import Foundation

public enum Mode: String, CaseIterable, Identifiable {
    case sound = "SOUND"
    case flash = "FLASH"
    case pulse = "PULSE"
    
    public var id: String { rawValue }
    
    public var displayNameKey: String {
        switch self {
        case .sound: return "Sound"
        case .flash: return "Flash"
        case .pulse: return "Pulse"
        }
    }
}
