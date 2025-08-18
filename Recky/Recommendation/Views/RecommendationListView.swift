import FirebaseAuth
import SwiftUI

struct RecommendationListView: View {
    @State private var showSearch = false
    @ObservedObject var viewModel: RecommendationListViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 12) {
                    searchChip("Received", isSelected: viewModel.showReceived) {
                        viewModel.showReceived.toggle()
                        viewModel.applySearch()
                    }

                    searchChip("Sent", isSelected: viewModel.showSent) {
                        viewModel.showSent.toggle()
                        viewModel.applySearch()
                    }
                }

                Spacer()

                Button(action: {
                    withAnimation {
                        showSearch.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(
                            systemName: showSearch
                                ? "chevron.down" : "chevron.right"
                        )
                        Text("Search")
                            .font(.subheadline)
                    }
                }
            }
            .padding(.horizontal)

            if showSearch {
                searchControls
            }

            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.loading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if viewModel.filteredRecommendations.isEmpty {
                        Text("No recommendations.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        RecommendationCardListView(
                            recommendations: viewModel.filteredRecommendations,
                            maxCount: nil,
                            onArchive: { rec in
                                viewModel.archive(rec: rec)
                            }
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .refreshable {
                viewModel.fetchAllRecommendations()
            }

            Spacer(minLength: 0)
        }
        .onAppear {
            viewModel.fetchAllRecommendations()
        }
    }

    private var searchControls: some View {
        VStack(spacing: 12) {
            HStack {
                TextField(
                    "Search by user...",
                    text: Binding(
                        get: { viewModel.selectedUser ?? "" },
                        set: {
                            viewModel.selectedUser = $0.isEmpty ? nil : $0
                            viewModel.applySearch()
                        }
                    )
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField(
                    "Filter by tag...",
                    text: Binding(
                        get: { viewModel.selectedTag ?? "" },
                        set: {
                            viewModel.selectedTag = $0.isEmpty ? nil : $0
                            viewModel.applySearch()
                        }
                    )
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            TextField("Search by title...", text: $viewModel.titleQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: viewModel.titleQuery) {
                    viewModel.applySearch()
                }

            if viewModel.showReceived == false || viewModel.showSent == false
                || viewModel.selectedTag != nil
                || viewModel.selectedUser != nil
                || !viewModel.titleQuery.isEmpty
            {
                Button("Reset Search") {
                    viewModel.resetSearch()
                }
                .font(.footnote)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }

    private func searchChip(
        _ title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Text(title)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1)
            )
            .foregroundColor(isSelected ? .blue : .gray)
            .cornerRadius(16)
            .onTapGesture(perform: action)
    }
}
