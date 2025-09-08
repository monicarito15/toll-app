import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Profile")
        }
        .padding()
    }
}

#Preview {
    ProfileView()
}


