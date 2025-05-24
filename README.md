
# AI Companion - macOS Application

## Phase 2: Authentication and User Management

This phase implements user authentication and profile management using Supabase as the backend service.

### Features Implemented

1. **Authentication**
   - Email/password registration and login
   - Magic link authentication (passwordless)
   - OAuth authentication (Apple, Google)
   - Password reset functionality
   - Session management and token refresh

2. **User Profile Management**
   - Profile data storage and retrieval
   - Profile picture upload and management
   - User preferences synchronization

3. **Secure Storage**
   - Keychain integration for storing sensitive information
   - Secure handling of API keys and tokens

### Project Structure

- **Services/**
  - `AuthService.swift` - Handles authentication with Supabase

- **ViewModels/**
  - `AuthViewModel.swift` - Manages authentication state and UI logic
  - `ProfileViewModel.swift` - Handles user profile management
  - `SettingsViewModel.swift` - Manages application settings

- **Views/Auth/**
  - `LoginView.swift` - User login interface
  - `RegisterView.swift` - User registration interface

- **Views/Profile/**
  - `ProfileView.swift` - User profile management interface

- **Models/**
  - `UserProfile.swift` - User profile data model

### Setup Instructions

1. **Configure Supabase**
   - Create a Supabase project at https://supabase.com
   - Set up authentication providers in the Supabase dashboard
   - Create a `profiles` table with the following schema:
     ```sql
     create table profiles (
       id uuid references auth.users on delete cascade primary key,
       display_name text,
       bio text,
       avatar_url text,
       created_at timestamp with time zone default now(),
       updated_at timestamp with time zone default now()
     );
     
     -- Enable Row Level Security
     alter table profiles enable row level security;
     
     -- Create policies
     create policy "Users can view their own profile" 
       on profiles for select 
       using (auth.uid() = id);
     
     create policy "Users can update their own profile" 
       on profiles for update 
       using (auth.uid() = id);
     
     create policy "Users can insert their own profile" 
       on profiles for insert 
       with check (auth.uid() = id);
     ```

2. **Configure OAuth Providers**
   - For Apple Sign In:
     - Register your app in the Apple Developer portal
     - Configure Sign in with Apple capability
     - Add the redirect URL in your Supabase dashboard

   - For Google Sign In:
     - Create OAuth credentials in the Google Cloud Console
     - Add the authorized redirect URI in your Google project
     - Configure the Google provider in your Supabase dashboard

3. **Configure Deep Linking**
   - Ensure the URL scheme `aicompanion://` is registered in your Info.plist
   - Add the URL scheme to your Supabase site URL configuration

### Usage

1. **Authentication**
   - Users can register with email/password
   - Users can sign in with email/password, magic link, or OAuth
   - Users can reset their password if forgotten

2. **Profile Management**
   - Users can view and edit their profile information
   - Users can upload a profile picture
   - User preferences are synchronized with Supabase

3. **Settings**
   - API keys and other sensitive information are stored securely in the Keychain
   - Users can configure application settings

### Dependencies

- Supabase Swift SDK: https://github.com/supabase/supabase-swift
- KeychainAccess: https://github.com/kishikawakatsumi/KeychainAccess

### License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
