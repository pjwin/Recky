import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct RecommendationsView: View {
    @State private var allRecommendations: [Recommendation] = []
    @State private var filteredRecommendations: [Recommendation] = []
    @State private var loading = true

    @State private var showReceived = true
    @State private var showSent = true
    @State private var selectedType: String? = nil
    @State private var selectedUser: String? = nil

    private var isFiltering: Bool {
        !showReceived || !showSent || selectedType != nil || selectedUser != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter controls pinned to the top
            filterControls
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .zIndex(1)  // optional, if overlays are added later

            // Main content below
            if loading {
                Spacer()
                ProgressView().padding()
                Spacer()
            } else if filteredRecommendations.isEmpty {
                Spacer()
                Text("No recommendations.")
                    .foregroundColor(.gray)
                    .padding()
                Spacer()
            } else {
                ScrollView {
                    RecommendationCardList(
                        recommendations: filteredRecommendations,
                        maxCount: nil
                    )
                    .padding(.horizontal)
                    .padding(.top)
                }
            }
        }
        .navigationTitle("All Recommendations")
        .onAppear(perform: fetchAllRecommendations)
    }

    @ViewBuilder
    private func recommendationNavigationLink(for rec: Recommendation)
        -> some View
    {
        let isSent = rec.fromUID == Auth.auth().currentUser?.uid
        let destination: some View =
            isSent
            ? AnyView(SentRecommendationDetailView(recommendation: rec))
            : AnyView(RecommendationDetailView(recommendation: rec))

        NavigationLink(destination: destination) {
            RecommendationRowView(
                recommendation: rec,
                isSent: isSent
            )
        }
    }

    private var filterControls: some View {
        VStack(spacing: 12) {
            // Direction chips
            HStack(spacing: 12) {
                filterChip(title: "Received", isSelected: showReceived) {
                    showReceived.toggle()
                    applyFilters()
                }

                filterChip(title: "Sent", isSelected: showSent) {
                    showSent.toggle()
                    applyFilters()
                }
            }

            // User + Type filters
            HStack {
                TextField(
                    "Filter by user...",
                    text: Binding(
                        get: { selectedUser ?? "" },
                        set: {
                            selectedUser = $0.isEmpty ? nil : $0
                            applyFilters()
                        }
                    )
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())

                Menu {
                    Button(
                        "All",
                        action: {
                            selectedType = nil
                            applyFilters()
                        }
                    )
                    ForEach(
                        ["movie", "tv", "book", "album", "game"],
                        id: \.self
                    ) { type in
                        Button(
                            type.capitalized,
                            action: {
                                selectedType = type
                                applyFilters()
                            }
                        )
                    }
                } label: {
                    Label(
                        selectedType?.capitalized ?? "Type",
                        systemImage: "line.3.horizontal.decrease.circle"
                    )
                }
            }

            // Conditionally visible Reset Filters
            if isFiltering {
                Button("Reset Filters") {
                    showReceived = true
                    showSent = true
                    selectedType = nil
                    selectedUser = nil
                    applyFilters()
                }
                .font(.footnote)
                .foregroundColor(.blue)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal)
    }

    private func filterChip(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected
                        ? Color.blue.opacity(0.15)
                        : Color(.secondarySystemBackground)
                )
                .foregroundColor(isSelected ? .blue : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }

    func applyFilters() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }

        filteredRecommendations = allRecommendations.filter { rec in
            let isSent = rec.fromUID == myUID
            let isReceived = rec.toUID == myUID

            let matchesDirection =
                (showSent && isSent) || (showReceived && isReceived)

            let matchesType =
                selectedType == nil
                || rec.type.lowercased() == selectedType?.lowercased()

            let matchesUser: Bool = {
                guard let user = selectedUser?.lowercased() else { return true }
                if isSent {
                    return rec.toUsername?.lowercased().contains(user) ?? false
                } else {
                    return rec.fromUsername?.lowercased().contains(user)
                        ?? false
                }
            }()

            return matchesDirection && matchesType && matchesUser
        }
    }

    func fetchAllRecommendations() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("recommendations")
            .whereFilter(
                Filter.orFilter([
                    Filter.whereField("toUID", isEqualTo: myUID),
                    Filter.whereField("fromUID", isEqualTo: myUID),
                ])
            )
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching: \(error)")
                    loading = false
                    return
                }

                let rawRecs: [Recommendation] =
                    snapshot?.documents.compactMap { doc in
                        var rec = try? doc.data(as: Recommendation.self)
                        rec?.id = doc.documentID
                        return rec
                    } ?? []

                let group = DispatchGroup()
                var results: [Recommendation] = []

                for var rec in rawRecs {
                    group.enter()
                    let uidToLookup =
                        rec.fromUID == myUID ? rec.toUID : rec.fromUID
                    Firestore.firestore().collection("users").document(
                        uidToLookup
                    ).getDocument { doc, _ in
                        let username =
                            doc?.get("username") as? String ?? "unknown"
                        if rec.fromUID == myUID {
                            rec.toUsername = username
                        } else {
                            rec.fromUsername = username
                        }
                        results.append(rec)
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    self.allRecommendations = results.sorted(by: {
                        $0.timestamp > $1.timestamp
                    })
                    self.applyFilters()
                    self.loading = false
                }
            }
    }

}
