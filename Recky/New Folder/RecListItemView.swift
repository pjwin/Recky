import SwiftUI

struct RecListItemView: View {
    var body: some View {
        HStack {
            Image(systemName: "hand.thumbsup")
                .font(.title)
            .padding()
            VStack(alignment: .leading) {
                Text("Recommendation Title")
                    .font(.title)
                HStack {
                    Text("From ") +
                    Text("@" + "Brian")
                        .foregroundColor(.blue)
                        .underline()
                    Spacer()
                    Text("1h ago")
                }
                Text("movie, comedy")
                    .italic()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    RecListItemView()
}

