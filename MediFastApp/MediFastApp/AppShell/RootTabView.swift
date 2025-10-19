import SwiftUI

struct RootTabView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            TabView {
                NavigationStack {
                    MeditationView()
                }
                .tabItem {
                    Image(systemName: "leaf")
                    Text("Meditate")
                }

                NavigationStack {
                    BreathingSetupView()
                }
                .tabItem {
                    Image(systemName: "wind")
                    Text("Breathe")
                }

                NavigationStack {
                    FastingView()
                }
                .tabItem {
                    Image(systemName: "hourglass")
                    Text("Fast")
                }

                NavigationStack {
                    ProfileView()
                }
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
            }
        }
    }
}

#Preview {
    RootTabView()
}
