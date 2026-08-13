//
//  Item.swift
//  file picker
//
//  Created by Алексей Бойченко on 13.08.2026.
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
