//
//  Item.swift
//  URLSession Demo
//
//  Created by Kaushik Manian on 4/6/25.
//

import Foundation

final class Item: Identifiable {
    let id = UUID()
    var timestamp: Date

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
