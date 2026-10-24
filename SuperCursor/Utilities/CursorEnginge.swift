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
    private var detector = WiggleDetector()
    
    //Monitor tokens
    private var globalToken : Any?;
    private var inAppToken: Any?;
    
    var isEnabled: Bool = false {
        didSet{
            isEnabled ? enable() : disable()
        }
    }
    
    func enable(){
        globalToken = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] mouseEvent in
            guard let self else{ return }
            handle(mouseEvent)
        }
        
        inAppToken = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved, handler: { [weak self] mouseEvent in
            guard let self else { return mouseEvent }
            handle(mouseEvent)
            return mouseEvent
        })
        
        
    }
    
    func disable(){
        if let globalToken {
            NSEvent.removeMonitor(globalToken)
            self.globalToken = nil
        }
        
        if let inAppToken {
            NSEvent.removeMonitor(inAppToken)
            self.inAppToken = nil
        }
        
        self.detector = WiggleDetector()
        
        print("Disabled and freed monitors")
    }
    
    private func handle (_ event: NSEvent) {
        
        print("Event", event)
        
        let sample = MouseSample(position: NSEvent.mouseLocation, timestamp: event.timestamp);
        
        let runProcess = detector.process(sample);
        
        if(runProcess){
            NSSound.beep()
        }
    }
}
