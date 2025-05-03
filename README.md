# HitRivals - Supabase Authentication Setup

This project demonstrates how to implement user authentication and profile management using Supabase in a SwiftUI iOS application.

## Setup Instructions

### 1. Supabase Configuration

#### Existing Supabase Project
This project is configured to work with your existing Supabase project. Your configuration is stored in `SupabaseConfig.swift`:
- URL: https://qrehyvzvxuqrcjbmdzmm.supabase.co
- Project ID: qrehyvzvxuqrcjbmdzmm

#### Supabase Schema Setup
Run the migration script to create the necessary tables and security policies:

```bash
# First link to your Supabase project
supabase link --project-ref qrehyvzvxuqrcjbmdzmm

# Then push the database schema
supabase db push
```

#### Configure Auth Redirect URLs
In your Supabase Dashboard:
1. Go to Authentication → URL Configuration
2. Add `io.supabase.hitrivals://login-callback` to the redirect URLs
3. Save changes

### 2. Xcode Project Setup

#### URL Scheme Configuration
1. Open HitRivals.xcodeproj in Xcode
2. Select the HitRivals target
3. Go to the 'Info' tab
4. Expand 'URL Types'
5. Click '+' to add a new URL Type
6. Set 'Identifier' to 'io.supabase.hitrivals'
7. Set 'URL Schemes' to 'io.supabase.hitrivals'
8. Save the project

### 3. Building the Project

#### Fix "No such module 'Supabase'" Errors
If you're seeing "No such module 'Supabase'" errors, follow these steps:

1. First Method: Add the Package Directly
   - In Xcode: File → Add Packages...
   - Enter: https://github.com/supabase/supabase-swift.git
   - Select the package and add it to the HitRivals target

2. Second Method: Update Build Settings (if first method doesn't work)
   - Select your project in Xcode
   - Go to Build Settings tab
   - Search for "Framework Search Paths"
   - Add the path to the Supabase SDK (typically in `.build/checkouts/supabase-swift`)
   - Search for "Import Paths" 
   - Add the path to the Supabase module

3. Third Method: Use Xcode's Package Dependencies
   - Select your project in Xcode
   - Go to Package Dependencies tab
   - Click + button
   - Enter: https://github.com/supabase/supabase-swift.git
   - Click Add Package

4. Clean and Rebuild
   - Product → Clean Build Folder
   - Quit and restart Xcode
   - Build again

#### Important Update on Async Properties
The Supabase SDK properties for session and user are now asynchronous and can throw errors. We've updated all code to handle this correctly:

```swift
// Before (old way - will cause errors)
func getUser() -> User? {
    return client.auth.currentUser
}

// After (correct way)
func getUser() async throws -> User? {
    return try await client.auth.currentUser
}
```

When calling these methods, remember to use:

```swift
do {
    if let user = try await SupabaseService.shared.getUser() {
        // Use user...
    }
} catch {
    // Handle error
}
```

## Project Structure

### Authentication Flow
- `SupabaseService.swift`: Manages all interactions with Supabase
- `AuthView.swift`: Handles user login, signup, and magic link authentication
- `AppView.swift`: Controls app state based on authentication status
- `ContentView.swift`: Main app interface after successful login

### Database Schema
The project includes a table for user profiles with Row Level Security for proper data access control:
- `profiles`: Stores user profile information with direct link to auth.users

## Troubleshooting

### Module Not Found Errors
If you encounter "No such module 'Supabase'" errors even after following the steps above:
1. Try running `swift package resolve` in the project directory
2. Delete the derived data folder: ~/Library/Developer/Xcode/DerivedData
3. Try adding explicit import paths in Build Settings

### URL Scheme Issues
If deep linking isn't working:
1. Verify URL scheme is correctly set in Xcode
2. Check that the redirect URL matches in both the app and Supabase dashboard
3. Ensure the `.onOpenURL` handler is present in the app 