import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @State private var showSendView = false
    @State private var showProfile = false
    @State private var pendingRequestCount = 0
    @StateObject private var viewModel = RecommendationListViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                headerBar
                Divider()
                RecommendationListView(viewModel: viewModel)
                recommendButton
            }
            .padding()
            .sheet(isPresented: $showSendView) {
                SendRecommendationView()
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
        }
    }

    private var headerBar: some View {
        ZStack {
            HStack {
                Image("AppLogo")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Spacer()

                ZStack(alignment: .topTrailing) {
                    Button(action: { showProfile = true }) {
                        Image(systemName: "person.circle")
                            .resizable()
                            .frame(width: 28, height: 28)
                    }

                    if pendingRequestCount > 0 {
                        Text("\(pendingRequestCount)")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 10, y: -10)
                    }
                }
            }

            VStack(spacing: 2) {
                Text("Welcome back,")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                if let email = Auth.auth().currentUser?.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.bottom, 8)
    }


    private var recommendButton: some View {
        Button(action: { showSendView = true }) {
            HStack {
                Spacer()
                Label("Recommend Something", systemImage: "plus")
                Spacer()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}
