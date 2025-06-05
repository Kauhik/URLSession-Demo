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

    @Published var randomMeal: Meal?

    // MARK: - Persistence Key
    private let persistKey = "persistedRecipes"

    // MARK: - Endpoints
    private let restBase   = URL(string: "https://api.restful-api.dev/objects")!   // full CRUD vault
    private let importBase = URL(string: "https://dummyjson.com/recipes")!        // read-only: has total/skip/limit
    private let randomMealURL = URL(string: "https://www.themealdb.com/api/json/v1/1/random.php")!

    // MARK: - Init
    init() {
        loadLocalRecipes()
    }

    // MARK: - Local Persistence (UserDefaults)
    private func loadLocalRecipes() {
        if let data = UserDefaults.standard.data(forKey: persistKey),
           let decoded = try? JSONDecoder().decode([Recipe].self, from: data) {
            recipes = decoded
        } else {
            recipes = []
        }
    }

    private func saveLocalRecipes() {
        if let data = try? JSONEncoder().encode(recipes) {
            UserDefaults.standard.set(data, forKey: persistKey)
        }
    }

    // MARK: - FETCH ALL
    /// Retrieves all locally stored recipes.
    func fetchAll() async {
        isLoading = true
        defer { isLoading = false }

        // Simply reload from local persistence; ignore remote so imports stay
        loadLocalRecipes()
    }

    // MARK: - CREATE
    /// POST a new Recipe to the remote vault (if available), then append locally.
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
            // Even if remote POST fails, still append locally
            recipes.append(recipe)
        }
        saveLocalRecipes()
    }

    // MARK: - UPDATE
    /// PUT to the remote, then replace locally. Then persist locally.
    func update(_ recipe: Recipe) async {
        guard
            let id = recipe.id,
            let url = URL(string: id, relativeTo: restBase)
        else {
            // If there's no remote ID, just replace locally
            if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
                recipes[index] = recipe
                saveLocalRecipes()
            }
            return
        }

        do {
            var req = URLRequest(url: url)
            req.httpMethod = "PUT"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(recipe)

            let (data, _) = try await URLSession.shared.data(for: req)
            let updated = try JSONDecoder().decode(Recipe.self, from: data)
            recipes.replaceAll(where: { $0.id == updated.id }, with: updated)
        } catch {
            // If remote update fails, still update locally
            if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
                recipes[index] = recipe
            }
        }
        saveLocalRecipes()
    }

    // MARK: - DELETE
    /// DELETE from remote (if possible), then remove locally and persist.
    func delete(at offsets: IndexSet) async {
        for index in offsets {
            if let id = recipes[index].id,
               let url = URL(string: id, relativeTo: restBase) {
                do {
                    var req = URLRequest(url: url)
                    req.httpMethod = "DELETE"
                    _ = try await URLSession.shared.data(for: req)
                } catch {
                    // If remote delete fails, still remove locally
                }
            }
            recipes.remove(at: index)
            saveLocalRecipes()
        }
    }

    // MARK: - IMPORT RANDOM UNIQUE SAMPLES
    /// 1) GET /recipes?limit=0 → to learn `total`.
    /// 2) Pick a random `skip` so that we can request `count` items.
    /// 3) GET /recipes?limit=count&skip=randomSkip → returns “{ recipes: [Sample], total, skip, limit }”.
    /// 4) Filter out any sample whose **name** is already in `self.recipes`.
    /// 5) For each remaining Sample, POST it into local (and remote if possible).
    func importRandomSamples(count: Int = 3) async {
        isLoading = true
        defer { isLoading = false }

        struct PagedResponse: Decodable {
            let total: Int
        }

        struct Wrapper: Decodable {
            let recipes: [Sample]
            let total: Int
        }

        struct Sample: Decodable {
            let name: String
            let instructions: [String]
        }

        do {
            // Step A: GET total count
            var initialComponents = URLComponents(string: importBase.absoluteString)!
            initialComponents.queryItems = [ URLQueryItem(name: "limit", value: "0") ]
            let (initialData, _) = try await URLSession.shared.data(from: initialComponents.url!)
            let initialPaged = try JSONDecoder().decode(PagedResponse.self, from: initialData)
            let totalCount = initialPaged.total

            guard totalCount > 0 else { return }

            // Step B: Pick a random skip
            let maxSkip = max(0, totalCount - count)
            let randomSkip = Int.random(in: 0...maxSkip)

            // Step C: Fetch `count` items starting at `randomSkip`
            var fetchComponents = URLComponents(string: importBase.absoluteString)!
            fetchComponents.queryItems = [
                URLQueryItem(name: "limit", value: "\(count)"),
                URLQueryItem(name: "skip",  value: "\(randomSkip)")
            ]
            let (fetchedData, _) = try await URLSession.shared.data(from: fetchComponents.url!)
            let wrapper = try JSONDecoder().decode(Wrapper.self, from: fetchedData)

            // Step D: Filter out samples whose name already exists locally
            let existingNames = Set(recipes.map { $0.name.lowercased() })
            let uniqueSamples = wrapper.recipes.filter { !existingNames.contains($0.name.lowercased()) }

            guard !uniqueSamples.isEmpty else { return }

            // Step E: POST (or append) each unique Sample into local (and remote if possible).
            var seenNames = existingNames
            for sample in uniqueSamples {
                let lower = sample.name.lowercased()
                guard !seenNames.contains(lower) else { continue }
                seenNames.insert(lower)

                let descriptionText = sample.instructions.joined(separator: "\n")
                let newRecipe = Recipe(name: sample.name, description: descriptionText)

                await create(newRecipe)   // `create(_:)` handles both remote+local and persistence
            }
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
        }
    }

    // MARK: - FETCH RANDOM MEAL
    /// Retrieves a random meal from TheMealDB API and publishes it to `randomMeal`.
    func fetchRandomMeal() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: randomMealURL)
            let decoded = try JSONDecoder().decode(MealsResponse.self, from: data)
            if let meal = decoded.meals.first {
                randomMeal = meal
            } else {
                errorMessage = "No meal found."
            }
        } catch {
            errorMessage = "Failed to fetch random meal: \(error.localizedDescription)"
        }
    }
}

// MARK: - Models for Random Meal
struct MealsResponse: Decodable {
    let meals: [Meal]
}

struct Meal: Identifiable, Decodable {
    let id: String
    let name: String
    let instructions: String
    let thumbnail: URL

    enum CodingKeys: String, CodingKey {
        case id = "idMeal"
        case name = "strMeal"
        case instructions = "strInstructions"
        case thumbnail = "strMealThumb"
    }
}

// MARK: - Array Helper
private extension Array where Element: Identifiable & Hashable {
    mutating func replaceAll(where predicate: (Element) -> Bool, with element: Element) {
        if let idx = firstIndex(where: predicate) {
            self[idx] = element
        }
    }
}
