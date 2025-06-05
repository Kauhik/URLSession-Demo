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
    @ObservedObject var api: APIService   // so that we can call `create(...)`

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if let meal = meal {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(meal.name)
                                .font(.largeTitle)
                                .bold()
                                .padding(.bottom, 8)

                            AsyncImage(url: meal.thumbnail) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(12)
                                    .shadow(radius: 5)
                                    .padding(.bottom, 12)
                            } placeholder: {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                            }

                            Text("Instructions")
                                .font(.title2)
                                .bold()
                                .padding(.bottom, 4)

                            Text(meal.instructions)
                                .font(.body)
                        }
                        .padding()
                    }
                } else {
                    // While `randomMeal` is nil or still loading, show a spinner
                    VStack {
                        ProgressView("Fetching Meal…")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Random Meal")
            .toolbar {
                // “Close” button on the leading side
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                // “Add” button on the trailing side
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let m = meal {
                            let newRecipe = Recipe(name: m.name, description: m.instructions)
                            Task {
                                await api.create(newRecipe)
                            }
                        }
                        dismiss()
                    }
                    // Disabled until a fresh meal arrives
                    .disabled(meal == nil)
                }
            }
        }
    }
}
