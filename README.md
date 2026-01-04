# FitGenie 🏋️‍♂️🥗

## AI-Powered Personal Fitness & Nutrition App

### Your pocket-sized personal trainer and nutritionist powered by Google Gemini AI

---

## 📋 Overview

**FitGenie** is a cross-platform mobile application (iOS/Android) that revolutionizes personal fitness by combining Generative AI with personalized health guidance. Unlike static fitness apps that offer pre-built workout templates, FitGenie acts as an **automated personal trainer and nutritionist**, creating fully customized 7-day workout plans and meal schedules tailored to each user's unique biometrics, available equipment, and dietary restrictions.

### The Problem

- 💰 **Cost barrier**: Personal trainers cost $50-100+ per session
- 📦 **One-size-fits-all**: Generic apps don't account for individual equipment or dietary needs
- 🔀 **Fragmented experience**: Switching between workout and nutrition apps creates inconsistent plans

### The Solution

FitGenie leverages **Google Gemini AI** to generate comprehensive, personalized fitness and nutrition plans in under 30 seconds:

- ✅ Custom workout routines adapted to your equipment (gym, home, or bodyweight)
- ✅ Personalized meal plans respecting dietary restrictions
- ✅ AI-powered chat for real-time plan modifications
- ✅ Streak-based motivation and progress tracking
- ✅ Full offline access to cached plans

---

## ✨ Features

### Core Features (MVP)

| Feature                    | Description                                                                 |
| -------------------------- | ----------------------------------------------------------------------------|
| **🔐 User Authentication** | Email/password authentication via Firebase Auth                             |
| **📝 Smart Onboarding**    | Multi-step wizard collecting biometrics, equipment, and dietary preferences |
| **🤖 AI Plan Generation**  | 7-day personalized workout + meal plans via Google Gemini                   |
| **📊 Today's Dashboard**   | Glanceable view of daily workouts, meals, and progress                      |
| **💬 Chat Modifications**  | Natural language requests to modify your plan                               |
| **📴 Offline Support**     | Full plan access without internet via Hive local storage                    |
| **🔥 Streak Tracking**     | Daily completion tracking with streak mechanics                             |

### Post-MVP Features

- 📊 Admin Dashboard (Flutter Web)
- 🔔 Push Notifications & Reminders
- 📸 Progress Photos
- ⏱️ Workout Timer
- 📤 Social Sharing
- 💾 Multiple Plan Storage

---

## 🛠️ Tech Stack

| Layer                | Technology            | Purpose                          |
| -------------------- | --------------------- | -------------------------------- |
| **Frontend**         | Flutter (Dart)        | Cross-platform mobile development|
| **State Management** | Riverpod              | Reactive state management        |
| **Backend**          | Firebase (Serverless) | Authentication, database, hosting|
| **Database**         | Cloud Firestore       | Real-time NoSQL database         |
| **AI Service**       | Google Gemini API     | Plan generation & modifications  |
| **Local Storage**    | Hive                  | Offline-first data persistence   |
| **Routing**          | go_router             | Declarative navigation           |
| **Data Classes**     | Freezed               | Immutable data models            |
| **Admin Panel**      | Flutter Web           | Analytics dashboard              |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** (Stable channel, 3.x+)
- **Dart SDK** (3.x+ with null safety)
- **Firebase CLI** (`npm install -g firebase-tools`)
- **FlutterFire CLI** (`dart pub global activate flutterfire_cli`)
- **Node.js** (for Firebase tools)
- **Android Studio** / **Xcode** (for platform-specific builds)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/fitgenie.git
   cd fitgenie
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   ```bash
   # Login to Firebase
   firebase login
   
   # Configure Firebase for this project
   flutterfire configure
   ```

4. **Set up environment variables**

   ```bash
   # Copy the example env file
   cp .env.example .env
   
   # Edit .env and add your API keys
   # GEMINI_API_KEY=your_gemini_api_key_here
   ```

5. **Run code generation**

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

6. **Run the app**

   ```bash
   # For development
   flutter run
   
   # For specific platform
   flutter run -d ios
   flutter run -d android
   ```

### Environment Variables

Create a `.env` file in the project root:

```bash
GEMINI_API_KEY=your_gemini_api_key_here
```

> ⚠️ **Important**: Never commit `.env` to version control. The `.gitignore` file should already exclude it.

---

## 🏗️ Architecture

### Project Structure

```bash
lib/
├── core/                    # Shared utilities & theming
│   ├── constants/           # App-wide constants
│   ├── exceptions/          # Custom exception classes
│   ├── extensions/          # Dart extensions
│   ├── theme/               # Material 3 theming
│   └── utils/               # Helper functions
├── features/                # Feature-first modules
│   ├── auth/                # Authentication
│   │   ├── data/            # Repositories & data sources
│   │   ├── domain/          # Entities & interfaces
│   │   └── presentation/    # Screens & widgets
│   ├── onboarding/          # User onboarding wizard
│   ├── plan_generation/     # AI plan generation
│   ├── dashboard/           # Main dashboard & today's view
│   ├── chat/                # AI chat modifications
│   └── profile/             # User profile management
├── shared/                  # Shared widgets & providers
│   ├── widgets/             # Reusable UI components
│   └── providers/           # Shared Riverpod providers
└── main.dart                # App entry point
```

### Data Flow

```text
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                               │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   UI Layer   │ ←→ │   Riverpod   │ ←→ │ Repository   │      │
│  │   Widgets    │    │   Providers  │    │   Layer      │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│                                                  ↓               │
│                              ┌───────────────────┴───────────┐  │
│                              ↓                               ↓  │
│                    ┌──────────────┐              ┌───────────┐  │
│                    │ Hive (Local) │              │ Firestore │  │
│                    │   Storage    │ ←─ sync ──→ │  (Remote) │  │
│                    └──────────────┘              └───────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Key Architectural Decisions

| Decision             | Choice                | Rationale                              |
| -------------------- | --------------------- | -------------------------------------- |
| **Offline-First**    | Hive + Firestore sync | 100% cached plan access offline        |
| **State Management** | Riverpod 2.x          | Testable, modern, provider-based       |
| **Data Models**      | Freezed               | Immutable, copyWith, JSON serialization|
| **Routing**          | go_router             | Declarative, deep linking support      |
| **AI Integration**   | Repository pattern    | Structured prompts, JSON validation    |

---

## 🎨 Design System

FitGenie uses **Material Design 3** with a custom theme focused on energy and approachability.

### Color Palette

| Role          | Color                      | Usage                       |
| ------------- | -------------------------- | --------------------------- |
| **Primary**   | `#F97316` (Energetic Coral)| Primary actions, streak fire|
| **Secondary** | `#06B6D4` (Cyan)           | Workout category accent     |
| **Tertiary**  | `#84CC16` (Lime)           | Success, completion states  |
| **Error**     | `#DC2626`                  | Validation errors           |

### Typography

- **Primary Font**: Inter (Google Fonts)
- **Type Scale**: Material 3 adapted with custom weights

---

## 📚 Documentation

| Document                                                        | Description                                                          |
| --------------------------------------------------------------  | -------------------------------------------------------------------- |
| [prd.md](./docs/prd.md)                                         | Product Requirements Document - Features, user journeys, requirements|
| [ux-design-specification.md](./docs/ux-design-specification.md) | UX Design Spec - User experience, visual design, patterns            |
| [architecture.md](./docs/architecture.md)                       | Architecture Decision Document - Technical decisions, data models    |

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

---

## 🔧 Development

### Code Generation

After modifying Freezed/Riverpod annotated classes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

For continuous generation during development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

### Linting

```bash
# Analyze code
flutter analyze

# Fix auto-fixable issues
dart fix --apply
```

### Building

```bash
# Build APK (Android)
flutter build apk --release

# Build App Bundle (Android)
flutter build appbundle --release

# Build iOS
flutter build ios --release
```

---

## 📱 Platform Support

| Platform    | Minimum Version    | Status          |
| ----------- | ------------------ | --------------- |
| **iOS**     | 12.0+              | ✅ Supported    |
| **Android** | API 21 (Lollipop+) | ✅ Supported    |
| **Web**     | Modern browsers    | 🔄 Admin only   |

---

## 🔒 Security

- **Authentication**: Firebase Auth with secure token management
- **Data Access**: Firestore rules restrict read/write to `request.auth.uid` only
- **API Keys**: Stored in `.env`, never committed to repository
- **Data in Transit**: All data encrypted via HTTPS/TLS

---

## 📈 Success Metrics

| Metric                     | Target      |
| -------------------------- | ----------- |
| Plan generation time       | < 5 seconds |
| App cold start             | < 3 seconds |
| Daily task completion rate | > 70%       |
| Average streak length      | > 5 days    |
| Offline plan availability  | 100%        |

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

### RusithHansana

- Portfolio project demonstrating full-stack mobile development capabilities
- Tech stack: Flutter + Firebase + Google Gemini AI

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) - UI framework
- [Firebase](https://firebase.google.com) - Backend services
- [Google Gemini](https://ai.google.dev) - AI capabilities
- [Material Design 3](https://m3.material.io) - Design system

---

Made with ❤️ and Flutter
