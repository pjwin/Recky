//
//  RecommendationListView.swift
//  Recky
//
//  Created by Paul Winters on 6/28/25.
//


import SwiftUI
import FirebaseAuth

struct RecommendationListView: View {
    @StateObject var viewModel = RecommendationListViewModel()

    var body: some View {
        VStack {
            if viewModel.loading {
                ProgressView().padding()
            } else {
                filterControls

                if viewModel.filteredRecommendations.isEmpty {
                    Text("No recommendations.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        RecommendationCardList(
                            recommendations: viewModel.filteredRecommendations,
                            maxCount: nil
                        )
                        .padding(.horizontal)
                        .padding(.top)
                    }
                    .refreshable {
                        viewModel.fetchAllRecommendations()
                    }
                }
            }
        }
        .onAppear {
            viewModel.fetchAllRecommendations()
        }
    }

    private var filterControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                filterChip("Received", isSelected: viewModel.showReceived) {
                    viewModel.showReceived.toggle()
                    viewModel.applyFilters()
                }

                filterChip("Sent", isSelected: viewModel.showSent) {
                    viewModel.showSent.toggle()
                    viewModel.applyFilters()
                }
            }

            HStack {
                TextField("Filter by user...", text: Binding(
                    get: { viewModel.selectedUser ?? "" },
                    set: {
                        viewModel.selectedUser = $0.isEmpty ? nil : $0
                        viewModel.applyFilters()
                    }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())

                Menu {
                    Button("All", action: {
                        viewModel.selectedType = nil
                        viewModel.applyFilters()
                    })
                    ForEach(["movie", "tv", "book", "album", "game"], id: \.self) { type in
                        Button(type.capitalized) {
                            viewModel.selectedType = type
                            viewModel.applyFilters()
                        }
                    }
                } label: {
                    Label(viewModel.selectedType?.capitalized ?? "Type", systemImage: "line.3.horizontal.decrease.circle")
                }
            }

            if viewModel.showReceived == false || viewModel.showSent == false || viewModel.selectedType != nil || viewModel.selectedUser != nil {
                Button("Reset Filters") {
                    viewModel.resetFilters()
                }
                .font(.footnote)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }

    private func filterChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Text(title)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .blue : .gray)
            .cornerRadius(16)
            .onTapGesture(perform: action)
    }
}
