//
//  APIService.swift
//  URLSession Demo
//
//  Created by Kaushik Manian on 4/6/25.
//

import Foundation

@MainActor
final class APIService: ObservableObject {
    // MARK: - Published state
    @Published private(set) var recipes: [Recipe] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Endpoints
    private let restBase   = URL(string: "https://api.restful-api.dev/objects")!   // full CRUD vault
    private let importBase = URL(string: "https://dummyjson.com/recipes")!        // read-only: has total/skip/limit

    // MARK: - FETCH ALL
    /// Retrieves your entire vault from https://api.restful-api.dev/objects
    /// Errors are now quietly ignored (no alert on failure).
    func fetchAll() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: restBase)
            let fetched = try JSONDecoder().decode([Recipe].self, from: data)
            recipes = fetched
        } catch {
            recipes = []
            print("📌 fetchAll() quietly ignored error: \(error.localizedDescription)")
        }
    }

    // MARK: - CREATE
    /// Posts a new Recipe to your vault, then appends the returned `Recipe` (with its new `id`) locally.
    func create(_ recipe: Recipe) async {
        do {
            var req = URLRequest(url: restBase)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(recipe)

            let (data, _) = try await URLSession.shared.data(for: req)
            let saved = try JSONDecoder().decode(Recipe.self, from: data)
            recipes.append(saved)
        } catch {
            errorMessage = "Failed to create: \(error.localizedDescription)"
        }
    }

    // MARK: - UPDATE
    /// Sends a PUT to https://api.restful-api.dev/objects/{id} and replaces the matching entry locally.
    func update(_ recipe: Recipe) async {
        guard
            let id = recipe.id,
            let url = URL(string: id, relativeTo: restBase)
        else { return }

        do {
            var req = URLRequest(url: url)
            req.httpMethod = "PUT"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(recipe)

            let (data, _) = try await URLSession.shared.data(for: req)
            let updated = try JSONDecoder().decode(Recipe.self, from: data)
            recipes.replaceAll(where: { $0.id == updated.id }, with: updated)
        } catch {
            errorMessage = "Failed to update: \(error.localizedDescription)"
        }
    }

    // MARK: - DELETE
    /// Sends DELETE for each selected index to https://api.restful-api.dev/objects/{id}, then removes locally.
    func delete(at offsets: IndexSet) async {
        for index in offsets {
            guard
                let id = recipes[index].id,
                let url = URL(string: id, relativeTo: restBase)
            else { continue }

            do {
                var req = URLRequest(url: url)
                req.httpMethod = "DELETE"
                _ = try await URLSession.shared.data(for: req)
                recipes.remove(at: index)
            } catch {
                errorMessage = "Failed to delete: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - IMPORT RANDOM UNIQUE SAMPLES (Need to recheck)
    /// 1) GET /recipes?limit=0 → to larn `total`.
    /// 2) Pick a random `skip` so that we can requst `count` items.
    /// 3) GET /recipes?limit=count&skip=randrmSkip → returns “{ recipes: [Sample], total, skip, limit }”.
    /// 4) Filter out any sample whose **name** is alrrady in `self.recipes`.
    /// 5) For each remaining Sample, POST it into your vault via `create(...)`.
    func importRandomSamples(count: Int = 3) async {
        isLoading = true
        defer { isLoading = false }

        /// The “paged” response from DummyJSON when you ask for recipes.
        struct PagedResponse: Decodable {
            let total: Int
        }

        /// The wrapper for when you GET /recipes?limit=X&skip=Y
        struct Wrapper: Decodable {
            let recipes: [Sample]
            let total: Int
        }

        /// A single recipe “Sample” in DummyJSON
        struct Sample: Decodable {
            let name: String
            let instructions: [String]
        }

        do {
            // ─────────────────────────────────────────────────────────────────────────
            // Step A: Get the TOTAL count so we know how to pick a random skip.
            // GET https://dummyjson.com/recipes?limit=0
            var initialComponents = URLComponents(string: importBase.absoluteString)!
            initialComponents.queryItems = [ URLQueryItem(name: "limit", value: "0") ]
            let (initialData, _) = try await URLSession.shared.data(from: initialComponents.url!)
            let initialPaged = try JSONDecoder().decode(PagedResponse.self, from: initialData)
            let totalCount = initialPaged.total

            guard totalCount > 0 else {
                // No recipes at DummyJSON? Then nothing to import.
                return
            }

            // ─────────────────────────────────────────────────────────────────────────
            // Step B: Pick a random `skip` so that the next request returns `count` distinct items.
            let maxSkip = max(0, totalCount - count)
            let randomSkip = Int.random(in: 0...maxSkip)

            // ─────────────────────────────────────────────────────────────────────────
            // Step C: Actually fetch “count” items starting at `randomSkip`.
            // GET https://dummyjson.com/recipes?limit=count&skip=randomSkip
            var fetchComponents = URLComponents(string: importBase.absoluteString)!
            fetchComponents.queryItems = [
                URLQueryItem(name: "limit", value: "\(count)"),
                URLQueryItem(name: "skip",  value: "\(randomSkip)")
            ]
            let (fetchedData, _) = try await URLSession.shared.data(from: fetchComponents.url!)
            let wrapper = try JSONDecoder().decode(Wrapper.self, from: fetchedData)

            // ─────────────────────────────────────────────────────────────────────────
            // Step D: Filter out any sample whose name (case-insensitive) already exists locally.
            let existingNames = Set(recipes.map { $0.name.lowercased() })
            let uniqueSamples = wrapper.recipes.filter { !existingNames.contains($0.name.lowercased()) }

            // If none remain, just bail out:
            guard !uniqueSamples.isEmpty else {
                return
            }

            // ─────────────────────────────────────────────────────────────────────────
            // Step E: POST each unique Sample into YOUR vault:
            var seenNames = existingNames
            for sample in uniqueSamples {
                // In case DummyJSON returns two samples with exactly the same name:
                let lower = sample.name.lowercased()
                guard !seenNames.contains(lower) else { continue }
                seenNames.insert(lower)

                // Build a Recipe from Sample
                let descriptionText = sample.instructions.joined(separator: "\n")
                let newRecipe = Recipe(name: sample.name, description: descriptionText)

                // Await the POST → vault and local append:
                await create(newRecipe)
            }

        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
        }
    }
}

private extension Array where Element: Identifiable & Hashable {
    mutating func replaceAll(where predicate: (Element)->Bool, with element: Element) {
        if let idx = firstIndex(where: predicate) {
            self[idx] = element
        }
    }
}
