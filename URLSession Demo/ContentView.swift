//
//  ContentView.swift
//  URLSession Demo
//
//  Created by Kaushik Manian on 4/6/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var api = APIService()

    // MARK: – State for sheets & navigation
    @State private var showingEditor = false
    @State private var editTarget: Recipe? = nil

    @State private var showDetail = false
    @State private var selectedRecipe: Recipe? = nil

    @State private var showMeal = false

    // MARK: – Search & Sort
    @State private var searchText = ""
    @State private var sortAscending = true

    /// 1) Filter by searchText
    /// 2) Sort ascending/descending
    private var filteredAndSorted: [Recipe] {
        let filtered = api.recipes.filter { recipe in
            searchText.isEmpty
                ? true
                : recipe.name.localizedCaseInsensitiveContains(searchText)
        }
        return filtered.sorted { lhs, rhs in
            if sortAscending {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            } else {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedDescending
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ── RECIPE LIST ──────────────────────────────────────────────
                recipesList
                    .listStyle(.plain)
                    .refreshable {
                        await api.fetchAll()
                    }
                    .overlay {
                        if api.isLoading {
                            ProgressView("Loading recipes…")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(.systemBackground).opacity(0.8))
                        }
                    }
            }
            .navigationTitle("Recipes (\(api.recipes.count))")
            // ── SEARCH BAR ────────────────────────────────────────────────
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search recipes..."
            )
            // ── TOOLBAR ───────────────────────────────────────────────────
            .toolbar {
                // Leading side: Random + Import
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        randomMealButton
                        importSamplesButton
                    }
                }

                // Trailing side: Add (+) and Sort (↕︎)
                ToolbarItem(placement: .navigationBarTrailing) {
                    addRecipeButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    sortToggleButton
                }
            }
            // ── SHEET #1: Edit / Create Recipe ────────────────────────────
            .sheet(isPresented: $showingEditor) {
                EditorView(recipe: editTarget) { result in
                    switch result {
                        case .save(let newRecipe):
                            Task {
                                if let _ = newRecipe.id {
                                    await api.update(newRecipe)
                                } else {
                                    await api.create(newRecipe)
                                }
                            }
                        case .cancel:
                            break
                    }
                    // Reset after dismiss
                    showingEditor = false
                }
            }
            // ── SHEET #2: Random Meal Detail ──────────────────────────────
            .sheet(isPresented: $showMeal) {
                MealDetailView(meal: api.randomMeal, api: api)
            }
            // ── NAVIGATION TO DETAIL ─────────────────────────────────────
            .navigationDestination(isPresented: $showDetail) {
                DetailView(recipe: selectedRecipe)
            }
            // ── ON APPEAR: fetch all recipes (loads from local persistence) ─
            .task {
                await api.fetchAll()
            }
            // ── ERROR ALERT ───────────────────────────────────────────────
            .alert("Error", isPresented: showErrorAlert) {
                Button("OK", role: .cancel) {
                    api.errorMessage = nil
                }
            } message: {
                Text(api.errorMessage ?? "")
            }
        }
    }

    // MARK: ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
    // MARK: – Helpers & Subviews for “body”

    /// Binding that becomes true when `api.errorMessage` is non‐nil
    private var showErrorAlert: Binding<Bool> {
        Binding<Bool>(
            get: { api.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    api.errorMessage = nil
                }
            }
        )
    }

    /// The List of recipes, with Delete + Edit (swipeActions) + navigation
    private var recipesList: some View {
        let recipesToShow = filteredAndSorted

        return List {
            ForEach(recipesToShow) { recipe in
                // Tapping on a row → go to DetailView
                Button {
                    selectedRecipe = recipe
                    showDetail = true
                } label: {
                    recipeRow(recipe)
                }
                // Swipe actions: Delete is already handled below; we now add Edit
                .swipeActions(edge: .leading) {
                    Button {
                        // Prepare to edit this recipe
                        editTarget = recipe
                        showingEditor = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
            .onDelete { indexSet in
                Task {
                    await api.delete(at: indexSet)
                }
            }
        }
    }

    /// A single row: icon + name + one‐line description
    private func recipeRow(_ recipe: Recipe) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "book.fill")
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)

                Text(recipe.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
    }

    /// “Sparkles” button → fetch a random meal
    private var randomMealButton: some View {
        Button {
            Task {
                // ─── CLEAR OUT OLD MEAL ───────────────────────────────────
                api.randomMeal = nil

                // Fetch a new random meal…
                await api.fetchRandomMeal()

                // Then show the sheet.
                showMeal = true
            }
        } label: {
            Image(systemName: "sparkles")
            Text("Random Meal")
        }
    }

    /// “Import Samples” button → import 3 random DummyJSON recipes
    private var importSamplesButton: some View {
        Button {
            Task {
                await api.importRandomSamples(count: 3)
            }
        } label: {
            Image(systemName: "square.and.arrow.down.on.square")
            Text("Import Samples")
        }
    }

    /// “＋” button to add a new recipe manually
    private var addRecipeButton: some View {
        Button {
            // Clearing editTarget = nil means “Create New”
            editTarget = nil
            showingEditor = true
        } label: {
            Image(systemName: "plus")
        }
    }

    /// ↕︎ button to toggle ascending/descending sort
    private var sortToggleButton: some View {
        Button {
            sortAscending.toggle()
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
}
