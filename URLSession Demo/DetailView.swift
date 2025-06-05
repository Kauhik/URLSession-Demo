//
//  DetailView.swift
//  URLSession Demo
//
//  Created by Kaushik Manian on 5/6/25.
//

import Foundation
import SwiftUI

struct DetailView: View {
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
