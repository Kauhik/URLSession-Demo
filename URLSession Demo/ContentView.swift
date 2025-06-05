//
//  ContentView.swift
//  URLSession Demo
//
//  Created by Kaushik Manian on 4/6/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var api = APIService()
    @State private var showingEditor = false
    @State private var editTarget: Recipe?
    @State private var showDetail: Bool = false
    @State private var selectedRecipe: Recipe?

    @State private var searchText: String = ""
    @State private var sortAscending: Bool = true

    /// Applies search & sorting to `api.recipes`
    private var filteredAndSorted: [Recipe] {
        let filtered = api.recipes.filter { recipe in
            searchText.isEmpty
                ? true
                : recipe.name.lowercased().contains(searchText.lowercased())
        }
        return filtered.sorted { lhs, rhs in
            sortAscending
                ? lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                : lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedDescending
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search recipes...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                }
                .padding([.horizontal, .top])

                // List of Recipes
                List {
                    ForEach(filteredAndSorted) { recipe in
                        Button {
                            selectedRecipe = recipe
                            showDetail = true
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.name)
                                    .font(.headline)
                                Text(recipe.description)
                                    .lineLimit(1)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .onDelete { idx in
                        Task { try? await api.delete(at: idx) }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await api.fetchAll()
                }
                .overlay {
                    if api.isLoading {
                        ProgressView("Loading…")
                    }
                }
            }
            .navigationTitle("Recipes (\(api.recipes.count))")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Import Samples (random unique ones)
                    Button {
                        Task { await api.importRandomSamples(count: 3) }
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down.on.square")
                            Text("Import Samples")
                        }
                    }

                    // “＋” to create a brand-new recipe
                    Button {
                        showingEditor = true
                        editTarget = nil
                    } label: {
                        Image(systemName: "plus")
                    }

                    // Sort toggle ↕︎
                    Button {
                        sortAscending.toggle()
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
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
                }
            }
            .background(
                // Hidden NavigationLink to push a DetailView
                NavigationLink(
                    destination: DetailView(recipe: selectedRecipe),
                    isActive: $showDetail,
                    label: { EmptyView() }
                )
                .hidden()
            )
            .task {
                // On first appear, load the vault
                await api.fetchAll()
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { api.errorMessage != nil },
                set: { if !$0 { api.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { api.errorMessage = nil }
            } message: {
                Text(api.errorMessage ?? "")
            }
        }
    }
}

// MARK: - Detail Screen
fileprivate struct DetailView: View {
    let recipe: Recipe?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let recipe = recipe {
                Text(recipe.name)
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 8)

                ScrollView {
                    Text(recipe.description)
                        .font(.body)
                        .padding(.horizontal)
                }
            } else {
                Text("No recipe selected.")
                    .italic()
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .navigationTitle("Detail")
    }
}

// MARK: - Editor Screen
fileprivate struct EditorView: View {
    enum Action { case save(Recipe), cancel }

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var desc: String
    let id: String?
    let onComplete: (Action) -> Void

    init(recipe: Recipe?, onComplete: @escaping (Action) -> Void) {
        _name = State(initialValue: recipe?.name ?? "")
        _desc = State(initialValue: recipe?.description ?? "")
        id = recipe?.id
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Recipe name", text: $name)
                }
                Section("Instructions") {
                    TextEditor(text: $desc)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle(id == nil ? "New Recipe" : "Edit Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        onComplete(.cancel)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                        onComplete(.save(.init(id: id, name: name, description: desc)))
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
