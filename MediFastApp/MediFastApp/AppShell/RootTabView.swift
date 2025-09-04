import SwiftUI

struct RootTabView: View {
    var body: some View {
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
        }
    }
}

#Preview {
    RootTabView()
}
