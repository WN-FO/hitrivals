import SwiftUI

// Direct import of Supabase
import Supabase

struct AppView: View {
    @StateObject private var appModel = AppModel.shared
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            } else if appModel.isLoggedIn {
                ContentView()
            } else {
                AuthView()
            }
        }
        .task {
            // Initial loading
            isLoading = true
            
            // Initialize authentication
            await checkAuthentication()
            
            isLoading = false
        }
    }
    
    private func checkAuthentication() async {
        // See if user is already logged in
        do {
            if let session = try await SupabaseService.shared.getSession() {
                print("Found existing session: \(session.accessToken)")
                DispatchQueue.main.async {
                    self.appModel.isLoggedIn = true
                }
            } else {
                print("No active session found")
                DispatchQueue.main.async {
                    self.appModel.isLoggedIn = false
                }
            }
        } catch {
            print("Error checking session: \(error)")
            DispatchQueue.main.async {
                self.appModel.isLoggedIn = false
            }
        }
    }
} 