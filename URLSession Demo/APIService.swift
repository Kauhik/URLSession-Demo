//
//  APIService.swift
//  URLSession Demo
//
//  Created by Kaushik Manian on 4/6/25.
//

import Foundation

@MainActor
final class APIService: ObservableObject {
    // MARK: - Public state
    @Published private(set) var recipes: [Recipe] = []

    // MARK: - End-points
    private let restBase = URL(string: "https://api.restful-api.dev/objects")!   // full CRUD
    private let importURL = URL(string: "https://dummyjson.com/recipes")!       // read-only

    // MARK: - CRUD
    func fetchAll() async throws {
        let (data, _) = try await URLSession.shared.data(from: restBase)
        recipes = try JSONDecoder().decode([Recipe].self, from: data)
    }

    func create(_ recipe: Recipe) async throws {
        var req = URLRequest(url: restBase)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(recipe)

        let (data, _) = try await URLSession.shared.data(for: req)
        let saved = try JSONDecoder().decode(Recipe.self, from: data)
        recipes.append(saved)
    }

    func update(_ recipe: Recipe) async throws {
        guard let id = recipe.id,
              let url = URL(string: id, relativeTo: restBase) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(recipe)

        let (data, _) = try await URLSession.shared.data(for: req)
        let updated = try JSONDecoder().decode(Recipe.self, from: data)
        recipes.replaceAll(where: { $0.id == updated.id }, with: updated)
    }

    func delete(at offsets: IndexSet) async throws {
        for index in offsets {
            guard let id = recipes[index].id,
                  let url = URL(string: id, relativeTo: restBase) else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = "DELETE"
            _ = try await URLSession.shared.data(for: req)      // ignore body
        }
        recipes.remove(atOffsets: offsets)
    }

    // MARK: - Import demo data from DummyJSON (read only, then POST to our API)
    func importSamples() async throws {
        let (data, _) = try await URLSession.shared.data(from: importURL)
        struct Wrapper: Decodable { let recipes: [Sample] }
        struct Sample: Decodable { let name: String; let instructions: [String] }
        let raw = try JSONDecoder().decode(Wrapper.self, from: data)

        for sample in raw.recipes.prefix(3) {          // grab first 3 only
            try await create(Recipe(name: sample.name,
                                    description: sample.instructions.joined(separator: "\n")))
        }
    }
}

private extension Array where Element: Identifiable & Hashable {
    mutating func replaceAll(where predicate: (Element)->Bool, with element: Element) {
        if let idx = firstIndex(where: predicate) { self[idx] = element }
    }
}
