import SwiftUI

@main
struct NOIRServerApp: App {
    @StateObject private var store = ServerStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
