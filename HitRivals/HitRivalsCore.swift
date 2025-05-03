import Foundation
import Supabase

// This file ensures that Supabase is properly imported throughout the app
// By using @_exported, any file that imports this file will also import Supabase

@_exported import Supabase

// MARK: - Initialization Helper

/// Initialize Supabase at app launch
/// Call this function in your App's init() method
public func setupSupabase() {
    print("Setting up Supabase connection...")
    
    // Initialize the shared client
    let client = SupabaseService.shared
    
    // Log configuration
    print("Supabase URL: \(SupabaseConfig.supabaseUrl)")
    
    // Setup app URL handling for deep links
    setupDeepLinkHandling()
    
    print("Supabase initialization complete")
}

/// Setup proper URL scheme handling for deep links
private func setupDeepLinkHandling() {
    print("Setting up URL scheme handling for authentication callbacks")
    print("Expected callback URL: com.hitrivals.app://login-callback")
    
    // Note: The URL scheme must be added to the app's Info.plist
    // <key>CFBundleURLTypes</key>
    // <array>
    //   <dict>
    //     <key>CFBundleTypeRole</key>
    //     <string>Editor</string>
    //     <key>CFBundleURLName</key>
    //     <string>com.hitrivals.app</string>
    //     <key>CFBundleURLSchemes</key>
    //     <array>
    //       <string>com.hitrivals.app</string>
    //     </array>
    //   </dict>
    // </array>
}

// MARK: - Troubleshooting Helpers

/// Check if Supabase modules are properly loaded
/// Use this for debugging module import issues
public func checkSupabaseModules() -> [String: Bool] {
    var results = [String: Bool]()
    
    // Check if core module is available
    results["Supabase"] = true
    
    // Try to create a client as a test
    do {
        let _ = SupabaseClient(
            supabaseURL: URL(string: "https://example.com")!,
            supabaseKey: "test_key"
        )
        results["SupabaseClient"] = true
    } catch {
        results["SupabaseClient"] = false
    }
    
    // Additional checks for session - don't use async here
    results["SessionAvailable"] = false // We can't check this synchronously
    
    return results
} 