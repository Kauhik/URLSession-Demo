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

    var body: some View {
        NavigationStack {
            List {
                ForEach(api.recipes) { recipe in
                    Button {
                        editTarget = recipe
                        showingEditor = true
                    } label: {
                        VStack(alignment: .leading) {
                            Text(recipe.name).font(.headline)
                            Text(recipe.description).lineLimit(1)
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { idx in
                    Task { try? await api.delete(at: idx) }
                }
            }
            .navigationTitle("Recipe Vault")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Import Sample Recipes") {
                        Task { try? await api.importSamples() }
                    }
                    Button("plus") {
                        editTarget = nil       // create mode
                        showingEditor = true
                    }
                }
            }
            .task {                // initial load
                try? await api.fetchAll()
            }
            .sheet(isPresented: $showingEditor) {
                Editor(recipe: editTarget) { result in
                    switch result {
                    case .save(let new):
                        Task {
                            if let _ = new.id {
                                try? await api.update(new)
                            } else {
                                try? await api.create(new)
                            }
                        }
                    case .cancel: break
                    }
                }
            }
        }
    }
}

// MARK: - Simple editor sheet
private struct Editor: View {
    enum Action { case save(Recipe), cancel }

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var desc: String
    let id: String?
    let onComplete: (Action) -> Void

    init(recipe: Recipe?, onComplete: @escaping (Action)->Void) {
        _name = State(initialValue: recipe?.name ?? "")
        _desc = State(initialValue: recipe?.description ?? "")
        id = recipe?.id
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $name)
                TextEditor(text: $desc).frame(minHeight: 120)
            }
            .navigationTitle(id == nil ? "New Recipe" : "Edit Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss(); onComplete(.cancel) }
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
