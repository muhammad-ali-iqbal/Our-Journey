# 💛 Our Map — A Gift for My Iko

---

## 🚀 Setup (Supabase — free, no credit card)

### 1. Create a Supabase project
- Go to https://supabase.com and sign up (free)
- Click **New project**
- Name it `ourmap`, pick a region close to you, set a database password
- Wait ~2 minutes for it to provision

### 2. Create the database table + storage

- In your Supabase project → left sidebar → **SQL Editor** → **New query**
- Copy the entire contents of `supabase_setup.sql` and paste it in
- Click **Run**

That creates:
- `memories` table with all fields
- Row Level Security policy (open read/write for a personal app)
- `memories` storage bucket for photos (public)

### 3. Get your credentials

- Left sidebar → **Project Settings** → **API**
- Copy **Project URL** and **anon public** key

### 4. Add credentials to the app

Open `lib/main.dart` and replace:
```dart
const _supabaseUrl = 'YOUR_SUPABASE_URL';
const _supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```
With your actual values.

### 5. Run the app
```bash
flutter pub get
flutter run
```

---

## 📱 Installing on Iko's phone

Once you're happy with it:
```bash
flutter build apk --release
```
Send her the APK at:
`build/app/outputs/flutter-apk/app-release.apk`

She uses the same Supabase project → everything syncs in real time.

---

## 💛 Happy birthday, Iko.
