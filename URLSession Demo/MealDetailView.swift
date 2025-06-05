//
//  MealDetailView.swift
//  URLSession Demo
//
//  Created by Kaushik Manian on 5/6/25.
//

import Foundation
import SwiftUI

struct MealDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let meal: Meal?
    @ObservedObject var api: APIService

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
                
                if let meal = meal {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header with sparkles icon
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            colors: [.yellow.opacity(0.8), .orange.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "sparkles")
                                        .font(.title)
                                        .foregroundStyle(.white)
                                }
                                
                                Text("Random Meal Discovery")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 20)
                            
                            // Meal name
                            Text(meal.name)
                                .font(.largeTitle.bold())
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)

                            // Meal image
                            AsyncImage(url: meal.thumbnail) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 250)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.regularMaterial)
                                    .frame(height: 250)
                                    .overlay {
                                        VStack(spacing: 12) {
                                            ProgressView()
                                                .scaleEffect(1.2)
                                            Text("Loading image...")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                            }
                            .padding(.horizontal, 20)

                            // Instructions card
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "list.bullet.clipboard.fill")
                                        .foregroundStyle(.green)
                                        .font(.title2)
                                    Text("Instructions")
                                        .font(.title2.bold())
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                
                                Text(meal.instructions)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                    .lineSpacing(4)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.regularMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                            )
                            .padding(.horizontal, 20)
                            
                            Spacer(minLength: 100)
                        }
                    }
                } else {
                    // Loading state
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.yellow.opacity(0.8), .orange.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Discovering a random meal...")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("This might take a moment")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Random Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add to Recipes") {
                        if let m = meal {
                            let newRecipe = Recipe(name: m.name, description: m.instructions)
                            Task {
                                await api.create(newRecipe)
                            }
                        }
                        dismiss()
                    }
                    .disabled(meal == nil)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
