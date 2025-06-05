//
//  EditorView.swift
//  URLSession Demo
//
//  Created by Kaushik Manian on 5/6/25.
//

import Foundation
import SwiftUI

struct EditorView: View {
    enum Action { case save(Recipe), cancel }

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var desc: String
    let id: String?
    let onComplete: (Action) -> Void

    init(recipe: Recipe?, onComplete: @escaping (Action) -> Void) {
        _name = State(initialValue: recipe?.name ?? "")
        _desc  = State(initialValue: recipe?.description ?? "")
        id           = recipe?.id
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
