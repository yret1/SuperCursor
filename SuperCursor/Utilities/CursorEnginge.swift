//
//  CursorEnginge.swift
//  SuperCursor
//
//  Created by Simon Gustavsson on 2026-10-23.
//
import SwiftUI
import Foundation
@MainActor
@Observable
final class CursorEngine{
    var isEnabled: Bool = false {
        didSet{
            isEnabled ? enable() : disable()
        }
    }
    
    func enable(){
        print("Activated")
    }
    
    func disable(){
        print("De-activated")
    }
}
