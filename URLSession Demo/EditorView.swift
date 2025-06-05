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
    
    @FocusState private var isNameFocused: Bool
    @FocusState private var isDescFocused: Bool

    init(recipe: Recipe?, onComplete: @escaping (Action) -> Void) {
        _name = State(initialValue: recipe?.name ?? "")
        _desc  = State(initialValue: recipe?.description ?? "")
        id           = recipe?.id
        self.onComplete = onComplete
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header icon
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.blue.opacity(0.8), .purple.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: id == nil ? "plus.circle" : "pencil.circle")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 20) {
                            // Recipe Name Section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "textformat")
                                        .foregroundStyle(.blue)
                                        .font(.headline)
                                    Text("Recipe Name")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                }
                                
                                TextField("Enter recipe name", text: $name)
                                    .focused($isNameFocused)
                                    .font(.body)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.regularMaterial)
                                            .stroke(isNameFocused ? .blue : .clear, lineWidth: 2)
                                    )
                            }
                            
                            // Instructions Section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "list.bullet.clipboard")
                                        .foregroundStyle(.green)
                                        .font(.headline)
                                    Text("Instructions")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                }
                                
                                ZStack(alignment: .topLeading) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.regularMaterial)
                                        .stroke(isDescFocused ? .green : .clear, lineWidth: 2)
                                        .frame(minHeight: 200)
                                    
                                    TextEditor(text: $desc)
                                        .focused($isDescFocused)
                                        .font(.body)
                                        .padding(12)
                                        .background(.clear)
                                        .scrollContentBackground(.hidden)
                                    
                                    if desc.isEmpty {
                                        Text("Enter cooking instructions, ingredients, and any notes...")
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 20)
                                            .allowsHitTesting(false)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle(id == nil ? "New Recipe" : "Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        onComplete(.cancel)
                    }
                    .foregroundStyle(.red)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                        onComplete(.save(.init(id: id, name: name, description: desc)))
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
