import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AllRecommendationsView: View {
    @State private var recommendations: [Recommendation] = []
    @State private var loading = true

    var body: some View {
        VStack {
            if loading {
                ProgressView()
                    .padding()
            } else if recommendations.isEmpty {
                Text("No recommendations yet.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(recommendations) { rec in
                    NavigationLink(destination: RecommendationDetailView(recommendation: rec)) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(EmojiUtils.forType(rec.type)) \(rec.title)")
                                    .font(.headline)
                                Spacer()
                                if rec.vote == nil {
                                    Text("NEW")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }

                            if let sender = rec.fromUsername {
                                Text("from @\(sender)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("All Recommendations")
        .onAppear(perform: fetchAllRecommendations)
    }

    func fetchAllRecommendations() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("recommendations")
            .whereField("toUID", isEqualTo: myUID)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching recommendations: \(error)")
                    loading = false
                    return
                }

                self.recommendations = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Recommendation.self)
                } ?? []

                loading = false
            }
    }
}
