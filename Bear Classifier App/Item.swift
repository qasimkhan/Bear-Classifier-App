//
//  Item.swift
//  Bear Classifier App
//
//  Created by Qasim Khan on 12/01/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
