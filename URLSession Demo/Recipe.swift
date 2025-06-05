//
//  Recipe.swift
//  URLSession Demo
//
//  Created by Kaushik Manian on 4/6/25.
//

import Foundation

/// One recipe as stored by https://api.restful-api.dev

struct Recipe: Identifiable, Hashable, Codable {
    let id: String?                     // server-generated
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
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id   = try c.decodeIfPresent(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        let data = try c.decodeIfPresent([String:String].self, forKey: .data)
        description = data?["description"] ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(["description": description], forKey: .data)
    }
}
