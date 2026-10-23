//
//  Excuse.swift
//  CRUD app
//
//  Created by Chloe Tay on 19/10/26.
//
import Foundation

//CaseIterable lets us ask for ALL cases as a list later (Reason.allCases), which we'll need to fill the picker on the form screen
nonisolated enum Reason: String, CaseIterable, Codable  {
    case tired = "Slept at 4am"
    case busy = "No time lor"
    case lazy = "Lazy"
    case weather = "PSI too high"
    case other = "MRT break down"
}


nonisolated struct Excuse: Codable, Hashable {
    let id: UUID
    var activity: String //what activity did u skip
    var reason: Reason //why, picked from enum
    var validity: Int //how legit is that excuse
    var date: Date //when it happened
    
    init(id: UUID = UUID(), activity: String, reason: Reason, validity: Int, date: Date) {
        self.id = id
        self.activity = activity
        self.reason = reason
        self.validity = validity
        self.date = date
    }
    
    /*
     class Excuse {
     var activity: String //what activity did u skip
     var reason: Reason //why, picked from enum
     var validity: Int //how legit is that excuse
     var date: Date //when it happened
     
     //initialiser
     init(activity: String, reason: Reason, validity: Int, date: Date = Date()) {
     self.activity = activity
     self.reason = reason
     self.validity = validity
     self.date = date
     }
     
     }
     */
}
