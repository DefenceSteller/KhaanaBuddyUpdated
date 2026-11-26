# KhaanaBuddy

Your AI-powered cooking companion with Groq-generated recipes, personalized recipe library, and seamless Google Sign-In.

![Version 1.0.0](https://img.shields.io/badge/version-1.0.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.22%2B-lightgrey)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Web-lightgrey)

![Botanical Kitchen Theme](https://img.shields.io/badge/theme-Orange%20Botanical%20Kitchen-orange)

---

## 📖 Features

- **🤖 AI Recipe Generation** — Get creative, detailed recipes for any ingredient you have using Groq's latest LLM
- **📖 Recipe Library** — Save, organize, and manage your personal cookbook
- **❤️ Favorites** — Mark recipes you love for quick access
- **🎧 Voice Assistant** — Have recipes read aloud automatically (TTS integration)
- **📱 Cross-Platform** — Android APKs and web builds on any device
- **🔑 Google Sign-In** — Login with Google for seamless authentication
- **👤 Guest-First Experience** — No account required to browse recipes; create account only when saving

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** 3.22 or later
- **Dart** (comes with Flutter)
- **Android Studio** or **Xcode** (for native Android builds)
- **Supabase** account
- **Google Cloud Console** project with OAuth credentials
- **Groq** API key

### 1. Clone and Install Dependencies

```bash
git clone https://github.com/DefenceSteller/KhaanaBuddyUpdated.git
cd KhaanaBuddyUpdated
flutter pub get
```

### 2. Supabase Setup

#### Project Creation
1. Go to [Supabase.com](https://supabase.com/dashboard) → Create new project
2. Wait for project to be ready (~1 minute)
3. Note your **Project URL** and **Anon Public Key**:

   ```
   URL: https://<project-id>.supabase.co
   Anon Key: eyJ... (long string)
   ```

#### Authentication
1. Supabase Dashboard → **Authentication** → **URL Configuration**
2. Set **Site URL** to your development web URL (e.g., `http://192.168.100.2:8080`)
3. **Redirect URLs** (add both):
   ```
   http://192.168.100.2:8080        (web if testing locally)
   io.supabase.khaanabuddy://login-callback/  (Android APK)
   ```

#### Database (Profiles)
1. Open **SQL Editor** → New query → Run:

```sql
create table profiles (
  id uuid references auth.users not null primary key,
  email text,
  name text,
  photo_url text,
  created_at timestamp with time zone default timezone('utc'::text, now())
);
```

2. Enable Row Level Security (RLS):

```sql
alter table profiles enable row level security;

create policy "Public profiles are viewable by everyone."
  on profiles for select
  using (true);

create policy "Users can insert their own profile."
  on profiles for insert
  with check (auth.uid() = id);

create policy "Users can update own profile."
  on profiles for update
  using (auth.uid() = id);
```

#### Storage (Avatars)
1. Go to **Storage** → Create new bucket: `avatars`
2. Set **Public** to **ON**
3. Enable **File Size Limit** (optional) to prevent abuse

---

### 3. Google Sign-In Setup

#### Google Cloud Console
1. Go to [console.cloud.google.com](https://console.cloud.google.com/)
2. Create a new project → **APIs & Services** → **Credentials**
3. Click **+ CREATE CREDENTIALS** → **OAuth 2.0 Client ID**
4. Application type: **Web application**
5. **Authorized redirect URIs** (add):
   ```
   http://192.168.100.2:8080
   ```
   *(Register your local IP or use your own domain for production)*
6. Copy the **Client ID**

#### Firebase Integration
1. In Google Admin Console, go to **IAM & Admin** → **Firebase**
2. Select your OAuth 2.0 Client ID
3. Enable **Google + Firebase Authentication APIs**

Config file uses your own Google OAuth Client ID directly (no Firebase Auth SDK required for this setup).

---

### 4. Groq AI Setup

1. Go to [console.groq.com](https://console.groq.com/) → **API Key**
2. Generate an API key
3. The app automatically uses the key configured via:
   - `.gitignore`: `lib/config/ai_config_local.dart` (your private key, never committed)

---

### 5. Configuration Files

#### Supabase Config (`lib/config/supabase_config.dart`)

```dart
static const String url = 'https://<your-project-id>.supabase.co';
static const String anonKey = '<your-anon-public-key>';
static const String googleRedirectUri =
    'io.supabase.khaanabuddy://login-callback/'; // Android APK
```

#### AI Config (`lib/config/ai_config.dart`)

Exposed template (for internal use):
```dart
static String apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
static String apiKey = 'REQUIRED'; // Loaded from gitignored file
static String model = 'qwen/qwen3.8-27b';
```

**Your key**: Edit `lib/config/ai_config_local.dart`:
```dart
static String apiKey = 'your-groq-api-key-here';
```

---

## 🎮 Running the App

### Web (Development)
```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 --disable-service-auth-codes
```

Then open `http://your-computer-ip:8080` on your phone's browser.

### Android (Local Emulator)

```bash
flutter run -d <emulator-id>
```

### Build APK

```bash
flutter build apk --release
```

The APK is output to `build/app/outputs/flutter-apk/app-release.apk`.

**Release signing (required):**
- Keystore: `android/khaanabuddy-release.keystore` (committed to this repo — safe without passwords)
- Passwords: `android/key.properties` (gitignored — **back it up securely, it's needed for every future update** of the same app)
- Signing config: `android/app/build.gradle.kts` → `signingConfigs { create("release") ... }`

---

## 📤 Public Download Site (Vercel)

The app is distributed through a one-page site: **https://khaanabuddy.vercel.app**

- Page source: `site/index.html` (+ `site/assets/`) — committed to this repo
- APK binary: `site/downloads/khaanabuddy.apk` — **gitignored**, uploaded to Vercel only (never to GitHub)

> ⚠️ **Never reconnect this Vercel project to GitHub.**
> If the project is linked to the git repo, every push auto-deploys the
> **repo root** (a Flutter project, not the site) → an empty 404 deployment
> that steals the `khaanabuddy.vercel.app` production alias. The site only
> works with **CLI deploys from `site/`** (which upload local files,
> including the gitignored APK).

### Updating the public APK

```bash
# 1. Build
flutter build apk --release

# 2. Copy it into the site folder
copy build\app\outputs\flutter-apk\app-release.apk site\downloads\khaanabuddy.apk

# 3. Re-deploy (from inside site/)
cd site
npx vercel --yes --name khaanabuddy --prod
```

The same URLs stay valid after each re-deploy:
- Site: `https://khaanabuddy.vercel.app`
- Direct APK: `https://khaanabuddy.vercel.app/downloads/khaanabuddy.apk`

> Note: bump `versionCode` in `android/app/build.gradle.kts` before each new APK so Android treats it as an update.

---

## 📁 Project Structure

```
lib/
├── assets/
│   ├── khaanabuddy_logo_full.png      # App logo
│   ├── google_logo.png                 # Google Sign In logo
│   ├── CookMate_logo.png               # Legacy logo (unused)
│   └── fonts/                          # Custom fonts (Fraunces, Inter)
├── config/
│   ├── ai_config.dart                  # AI API template (non-sensitive)
│   ├── ai_config_local.dart            # Your real AI key (gitignored)
│   └── supabase_config.dart            # Supabase credentials
├── providers/
│   └── theme_provider.dart             # Dark/Light mode toggle
├── screens/
│   ├── splash_screen.dart              # Splash screen with logo
│   ├── login_screen.dart               # Login with Google
│   ├── home_screen.dart                # Main recipe browsing
│   ├── recipe_detail_screen.dart       # Recipe details & AI generation
│   ├── favorite_screen.dart            # Saved favorites
│   └── profile_screen.dart             # User profile, photo upload, settings
├── services/
│   ├── google_auth_service.dart        # Google Sign-In via Supabase OAuth
│   └── recipe_service.dart             # Recipe CRUD operations
├── themes/
│   └── theme.dart                      # Orange "Botanical Kitchen" theme
└── main.dart                           # App entry point

android/
└── app/
    └── src/main/
        └── AndroidManifest.xml         # Deep-link scheme for APK Google login
```

---

## 🎨 Orange Theme Variables

```dart
// Brand colors (Botanical Kitchen theme)
static const Color brand = Color(0xFF7A1A);      // Primary orange
static const Color deep = Color(0xFF5A00);        // Dark orange
static const Color soft = Color(0xFFA64D);        // Soft orange
static const Color tint = Color(0xFFF1E6);        // Warm white tint
static const Color gradient = LinearGradient(
  colors: [Color(0xFF6A00), Color(0xFFA13B)],   // Orange gradient
);
static const Color accent = Color(0xFFF2A93B);    // Saffron-gold accent
static const Color darkSurface = Color(0xFF2A241F);  // Warm dark
static const Color darkBorder = Color(0xFF3D3832);   // Dark border
static const Color muted = Color(0xFF8A817C);      // Muted text
```

---

## 🔐 Security Notes

- **Never commit API keys** — the `ai_config_local.dart` is in `.gitignore`
- **Supabase Anon Key** is publicly readable but restricted by RLS policies
- **Google OAuth** uses your own client ID (not Firebase Auth SDK for simplicity)
- **Storage buckets** expose public URLs but are restricted to `user_id/avatar_*` paths

---

## 📱 Screens Overview

| Screen | Description | Entry |
|--------|-------------|-------|
| Splash | Loading screen with animated logo | App launch |
| Login | Google Sign In | Not logged in |
| Home | Browse recipes, search, AI generate | After login |
| Recipe Detail | View recipe + AI regenerate on complete | Tap recipe |
| Favorites | Show saved/liked recipes | Profile → Favorites |
| Profile | Account management, photo upload | Bottom nav |

---

## 🛠️ Troubleshooting

### Google Sign-In fails on iPhone Safari
- Close the Safari tab completely, then reopen `http://192.168.100.2:8080`
- Verify redirect URL `http://192.168.100.2:8080` is in Supabase **Redirect URLs** list
- Ensure Supabase **Site URL** is set (can be the same as first redirect URL)

### Photo upload fails
- Close browser tab and restart the dev server to reload fresh compiled modules
- Check Supabase bucket `avatars` has public access enabled

### Storage bucket permissions
- Go to Supabase Storage → `avatars` → **Policies** → Enable public access
- Ensure profile table has correct RLS policies

---

## 🤝 Contributing

This is a personal project. Feel free to fork and experiment.

---

## 📄 License

Personal project — all rights reserved.

---

**Made with Flutter, Supabase, and Groq AI**