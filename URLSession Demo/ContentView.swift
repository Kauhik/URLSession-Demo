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
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Header stats card (only show if there are recipes)
                    if !api.recipes.isEmpty {
                        headerStatsView
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                    }

                    // Recipe list
                    recipesList
                        .padding(.horizontal, 16)
                        .overlay {
                            if api.isLoading {
                                loadingOverlay
                            } else if api.recipes.isEmpty && !api.isLoading {
                                emptyStateView
                            }
                        }
                }
            }
            .navigationTitle("My Recipes")
            .navigationBarTitleDisplayMode(.large)
            // Search bar
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search recipes..."
            )
            // Toolbar
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            Task {
                                api.randomMeal = nil
                                await api.fetchRandomMeal()
                                showMeal = true
                            }
                        } label: {
                            Label("Random Meal", systemImage: "sparkles")
                        }

                        Button {
                            Task {
                                await api.importRandomSamples(count: 3)
                            }
                        } label: {
                            Label("Import Samples", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                sortAscending.toggle()
                            }
                        } label: {
                            Image(systemName: sortAscending ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                        .padding(8)

                        Button {
                            editTarget = nil
                            showingEditor = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                        }
                        .padding(8)
                    }
                }
            }
            // Sheets and navigation
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
                    showingEditor = false
                }
            }
            .sheet(isPresented: $showMeal) {
                MealDetailView(meal: api.randomMeal, api: api)
            }
            .navigationDestination(isPresented: $showDetail) {
                DetailView(recipe: selectedRecipe)
            }
            .task {
                await api.fetchAll()
            }
            .alert("Error", isPresented: showErrorAlert) {
                Button("OK", role: .cancel) {
                    api.errorMessage = nil
                }
            } message: {
                Text(api.errorMessage ?? "")
            }
            .refreshable {
                await api.fetchAll()
            }
        }
    }

    // MARK: – Subviews

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

    private var headerStatsView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(api.recipes.count)")
                    .font(.title.bold())
                    .foregroundStyle(.primary)
                Text("Total Recipes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("\(filteredAndSorted.count)")
                    .font(.title.bold())
                    .foregroundStyle(.blue)
                Text("Showing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }

    private var recipesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredAndSorted) { recipe in
                    RecipeCardView(recipe: recipe) {
                        selectedRecipe = recipe
                        showDetail = true
                    } onEdit: {
                        editTarget = recipe
                        showingEditor = true
                    } onDelete: {
                        Task {
                            if let index = api.recipes.firstIndex(where: { $0.id == recipe.id }) {
                                await api.delete(at: IndexSet(integer: index))
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }
    }

    private var loadingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading recipes...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Recipes Yet")
                    .font(.title2.bold())

                Text("Start by adding your first recipe or importing some samples")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            HStack(spacing: 20) {
                Button {
                    editTarget = nil
                    showingEditor = true
                } label: {
                    Label("Add Recipe", systemImage: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    Task {
                        await api.importRandomSamples(count: 3)
                    }
                } label: {
                    Label("Import Samples", systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RecipeCardView: View {
    let recipe: Recipe
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                // Recipe icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.orange.opacity(0.8), .red.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 56, height: 56)

                    Image(systemName: "fork.knife")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                .padding(.leading, 8)

                // Recipe content
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(recipe.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 12)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(4)

                    Button {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(4)
                }
                .padding(.trailing, 8)
            }
            .padding(.all, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Delete Recipe", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete '\(recipe.name)'? This action cannot be undone.")
        }
    }
}
