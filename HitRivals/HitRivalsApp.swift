//
//  HitRivalsApp.swift
//  HitRivals
//
//  Created by Will Nichols on 4/26/25.
//

import SwiftUI

// Import Supabase conditionally
#if canImport(Supabase)
import Supabase
#endif

// Import our app components
import Foundation  // Ensures access to HitRivalsCore functions

@main
struct HitRivalsApp: App {
    init() {
        print("Initializing HitRivals app...")
        
        // Set up diagnostic tools and check if Supabase is available
        #if DEBUG
        print("Running in DEBUG mode")
        #endif
        
        // Set up Supabase connection if available
        #if canImport(Supabase)
        setupSupabase()
        #else
        print("⚠️ Supabase not available - skipping setup")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            AppView()
                .onOpenURL { url in
                    print("App received URL: \(url)")
                    #if canImport(Supabase)
                    // Handle the URL in a global context
                    Task {
                        do {
                            try await SupabaseService.shared.client.auth.session(from: url)
                            print("Successfully processed auth URL")
                        } catch {
                            print("Error processing URL: \(error)")
                        }
                    }
                    #else
                    print("⚠️ Cannot process URL: Supabase not available")
                    #endif
                }
        }
    }
}
