//
//  Recipe.swift
//  URLSession Demo
//
//  Created by Kaushik Manian on 4/6/25.
//

import Foundation

struct Recipe: Identifiable, Hashable, Codable {
    let id: String?                     // server‐generated (or nil if local‐only)
    var name: String
    var description: String

    // Map the nested `data` object to a flat Swift property
    enum CodingKeys: String, CodingKey { case id, name, data }
    enum DataKeys: String, CodingKey   { case description }

    init(id: String? = nil, name: String, description: String) {
        self.id = id
        self.name = name
        self.description = description
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id   = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let data = try container.decodeIfPresent([String:String].self, forKey: .data)
        description = data?["description"] ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(["description": description], forKey: .data)
    }
}
