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
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if let recipe = recipe {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with recipe icon
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.orange.opacity(0.8), .red.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white)
                            }
                            
                            Text(recipe.name)
                                .font(.largeTitle.bold())
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Instructions card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "list.bullet.clipboard.fill")
                                    .foregroundStyle(.blue)
                                    .font(.title2)
                                Text("Instructions")
                                    .font(.title2.bold())
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            
                            Text(recipe.description)
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
                        
                        Spacer(minLength: 50)
                    }
                }
            } else {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    
                    Text("No Recipe Selected")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text("Select a recipe from the list to view its details")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
            }
        }
        .navigationTitle("Recipe Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
