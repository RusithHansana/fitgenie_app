# Architecture Decision Document - FitGenie

**Author:** RusithHansana  
**Date:** 2025-12-21  
**Version:** 1.0  
**Status:** Complete

---

## Project Context Analysis

### Requirements Overview

**Functional Requirements Summary:**

FitGenie comprises **49 functional requirements** organized into 8 domains:

| Domain                   | FR Range  | Description                                                  |
| ------------------------ | --------- | ------------------------------------------------------------ |
| User Management          | FR1-FR6   | Authentication, session management, account operations       |
| Onboarding & Profile     | FR7-FR15  | Biometric data collection, equipment/dietary preferences     |
| AI Plan Generation       | FR16-FR21 | Gemini API integration, structured response parsing, caching |
| Dashboard & Plan Display | FR22-FR30 | Today's plan view, exercise/meal details, task completion    |
| Chat & Modifications     | FR31-FR36 | Natural language plan modifications via AI                   |
| Progress Tracking        | FR37-FR40 | Streak mechanics, completion statistics                      |
| Offline Functionality    | FR41-FR44 | Local caching, sync queue, offline indicators                |
| Admin Dashboard          | FR45-FR49 | Flutter Web analytics panel (aggregate metrics only)         |

**Non-Functional Requirements Summary:**

**22 NFRs** define quality attributes:

| Category            | Key Requirements                                                                  |
| ------------------- | --------------------------------------------------------------------------------- |
| **Performance**     | App cold start <3s, AI response <5s, transitions <300ms, cached load <500ms       |
| **Security**        | Firebase Auth tokens, Firestore rules (uid-scoped), API keys in .env, HTTPS/TLS   |
| **Reliability**     | 100% offline plan access, exponential backoff (3 retries), Firestore transactions |
| **Usability**       | WCAG 2.1 AA, responsive 375-1024pt, skeleton loaders, friendly errors             |
| **Maintainability** | Clean architecture, unit tests, README documentation, CI/CD automation            |

### Scale & Complexity Assessment

**Project Classification:**
- **Complexity Level:** Medium
- **Primary Domain:** Full-Stack Mobile Application
- **Architecture Style:** Offline-First, Serverless Backend, AI-Integrated

**Complexity Indicators:**

| Factor                 | Rating | Justification                                                                  |
| ---------------------- | ------ | ------------------------------------------------------------------------------ |
| AI Integration         | High   | Core product differentiator; Gemini prompt engineering, JSON schema validation |
| Real-time Features     | Medium | Streak sync, task completion; no live collaboration                            |
| Data Complexity        | Medium | Structured plans, user profiles; no complex relationships                      |
| Platform Coverage      | Medium | iOS + Android (Flutter), Web (Admin only)                                      |
| Offline Requirements   | High   | Full plan access without connectivity                                          |
| Multi-tenancy          | Low    | Single user per account; no org/team features                                  |
| Regulatory Compliance  | Low    | Health guidance disclaimer; not medical device                                 |
| Integration Complexity | Low    | Firebase + Gemini only; no third-party ecosystems                              |

### Technical Constraints & Dependencies

**Framework Constraints:**
- Flutter stable channel required
- Dart null safety enforced
- Minimum targets: iOS 12.0+, Android API 21+

**Service Dependencies:**
- Firebase Auth (authentication)
- Cloud Firestore (database)
- Google Gemini API (AI generation)
- Hive (local storage)

**Portfolio Constraints:**
- Solo developer implementation
- Demonstrate production patterns without enterprise complexity
- Free/low-cost tier services preferred
- Must be showcasable in 20-second video demo

### Cross-Cutting Concerns

The following concerns span multiple features and require unified architectural solutions:

1. **Connectivity State Management**
   - Affects: Plan viewing, task completion, AI chat, sync
   - Solution needed: Centralized connectivity monitoring with state propagation

2. **AI Response Consistency**
   - Affects: Plan generation, modifications, chat
   - Solution needed: JSON schema validation, fallback handling, retry logic

3. **Local ↔ Remote Synchronization**
   - Affects: Plans, completions, streaks
   - Solution needed: Sync queue, conflict resolution, merge strategies

4. **Error Handling & Recovery**
   - Affects: All network operations
   - Solution needed: Unified error types, user-friendly messaging, recovery actions

5. **Authentication Flow**
   - Affects: All protected routes and data
   - Solution needed: Auth state stream, route guards, token refresh

6. **Performance Monitoring**
   - Affects: User experience, portfolio demonstration
   - Solution needed: Timing metrics, error logging, crash reporting

---

## Technology Stack & Starter Evaluation

### Primary Technology Domain

**Mobile Application (Flutter + Firebase + AI)** - Cross-platform mobile app with serverless backend and generative AI integration.

### Starter Options Evaluated

| Option            | Description                              | Pros                                             | Cons                                                  | Decision   |
| ----------------- | ---------------------------------------- | ------------------------------------------------ | ----------------------------------------------------- | ---------- |
| **Flutter CLI**   | `flutter create` standard initialization | Clean slate, full control, no extra dependencies | Manual architecture setup required                    | ✅ Selected |
| **Very Good CLI** | Enterprise Flutter CLI by VGV            | Pre-configured testing, CI/CD, bloc patterns     | Overkill for solo project, different state management | ❌ Rejected |
| **Mason Bricks**  | Code generation templates                | Consistent code structure                        | Extra tooling learning curve                          | ❌ Rejected |
| **Stacked CLI**   | MVVM architecture generator              | Good structure patterns                          | Tied to specific architecture                         | ❌ Rejected |

### Selected Approach: Flutter CLI + Manual Clean Architecture

**Rationale:**

1. **PRD Alignment** - Implements exact stack specified: Flutter + Riverpod + Firebase + Hive + Gemini
2. **Portfolio Value** - Demonstrates ability to architect from scratch (more impressive than using generator)
3. **Maintainability** - No dependency on third-party CLI tools that may become outdated
4. **Flexibility** - Can adapt architecture precisely to FitGenie's requirements
5. **Learning Opportunity** - Clear understanding of every architectural decision

### Initialization Command

```bash
# Create Flutter project with specific organization
flutter create --org com.fitgenie --platforms=ios,android,web fitgenie

# Navigate to project
cd fitgenie

# Initialize Firebase (interactive setup)
flutterfire configure
```

### Core Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  
  # Local Storage
  hive_flutter: ^1.1.0
  hive: ^2.2.3
  
  # AI Integration
  google_generative_ai: ^0.2.0
  
  # Utilities
  flutter_dotenv: ^5.1.0
  connectivity_plus: ^5.0.2
  go_router: ^13.0.1
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  
  # UI Components
  flutter_animate: ^4.3.0
  shimmer: ^3.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.8
  riverpod_generator: ^2.3.9
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  hive_generator: ^2.0.1
  
  # Testing
  mocktail: ^1.0.1
  
  # Linting
  flutter_lints: ^3.0.1
```

### Architectural Decisions Provided by Stack

| Decision             | Choice                          | Rationale                               |
| -------------------- | ------------------------------- | --------------------------------------- |
| **Language**         | Dart 3.x with null safety       | Modern Flutter requirement              |
| **State Management** | Riverpod 2.x                    | PRD specified; testable, provider-based |
| **Routing**          | go_router                       | Declarative, deep linking support       |
| **Data Classes**     | Freezed                         | Immutable, copyWith, JSON serialization |
| **Local Storage**    | Hive                            | Fast, type-safe, offline-first          |
| **HTTP/API**         | Built-in + google_generative_ai | Gemini SDK for AI calls                 |
| **Environment**      | flutter_dotenv                  | API key protection                      |
| **Connectivity**     | connectivity_plus               | Network state monitoring                |
| **Animations**       | flutter_animate                 | UX spec animations                      |
| **Loading States**   | shimmer                         | Skeleton screens                        |

### Development Experience Setup

| Capability          | Implementation                                 |
| ------------------- | ---------------------------------------------- |
| **Hot Reload**      | Flutter built-in                               |
| **Code Generation** | build_runner for Riverpod, Freezed, Hive, JSON |
| **Linting**         | flutter_lints (strict mode)                    |
| **Testing**         | flutter_test + mocktail                        |
| **Debugging**       | Flutter DevTools                               |
| **CI/CD**           | GitHub Actions (configured in Step 8)          |

---

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
1. Application Architecture Pattern (Clean Architecture layers)
2. Data Flow Strategy (Offline-first with sync)
3. AI Integration Pattern (Request/Response handling)
4. Authentication Architecture (Firebase Auth flow)

**Important Decisions (Shape Architecture):**
1. Error Handling Strategy
2. State Management Patterns
3. Caching Strategy
4. Testing Strategy

**Deferred Decisions (Post-MVP):**
1. Push Notification Architecture
2. Analytics & Crash Reporting
3. Premium Feature Gating
4. Multi-language Support

### Data Architecture

#### ADR-001: Firestore Data Model

**Decision:** Document-based data model with user-scoped collections

**Context:** Need to store user profiles, generated plans, and completion data with offline support

**Options Considered:**
| Option                        | Pros                               | Cons                       |
| ----------------------------- | ---------------------------------- | -------------------------- |
| Flat collections with queries | Flexible querying                  | Complex security rules     |
| User-scoped subcollections    | Simple security, natural hierarchy | Slightly more reads        |
| Denormalized single document  | Fast reads                         | Document size limits (1MB) |

**Decision:** User-scoped subcollections

**Rationale:**
- Security rules are simple: `request.auth.uid == userId`
- Natural data hierarchy: Users → Plans → Completions
- Firestore offline cache works well with this pattern
- Document size remains manageable

**Data Schema:**

```
/users/{userId}
├── email: string
├── createdAt: timestamp
├── onboarding: {
│     age: number
│     weight: number
│     weightUnit: 'kg' | 'lbs'
│     height: number
│     heightUnit: 'cm' | 'ft-in'
│     goal: 'muscle_gain' | 'weight_loss' | 'general_fitness' | 'endurance'
│     equipment: 'full_gym' | 'home_gym' | 'bodyweight' | 'mixed'
│     equipmentDetails: string[]
│     dietaryRestrictions: string[]
│     dietaryNotes: string
│   }
├── currentStreak: number
├── longestStreak: number
└── lastActiveDate: timestamp

/users/{userId}/plans/{planId}
├── generatedAt: timestamp
├── weeklyPlan: {
│     monday: { workout: {...}, meals: {...} }
│     tuesday: { workout: {...}, meals: {...} }
│     ...
│   }
├── isActive: boolean
└── chatHistory: [{ role: string, content: string, timestamp: timestamp }]

/users/{userId}/completions/{date}  // date format: YYYY-MM-DD
├── date: timestamp
├── tasks: {
│     'workout': boolean
│     'breakfast': boolean
│     'lunch': boolean
│     'dinner': boolean
│   }
└── completedAt: timestamp
```

#### ADR-002: Offline-First Data Strategy

**Decision:** Local-first with background sync and conflict resolution

**Context:** NFR requires 100% offline plan access; users need to track completions without connectivity

**Architecture:**

```
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

**Sync Strategy:**
1. **Write:** Write to Hive immediately → Queue for Firestore sync → Sync when online
2. **Read:** Read from Hive first → Update from Firestore in background
3. **Conflict Resolution:** Server timestamp wins for streaks; last-write-wins for completions

**Hive Box Structure:**

```dart
// Local storage boxes
@HiveType(typeId: 0)
class UserProfileLocal extends HiveObject { ... }

@HiveType(typeId: 1)
class WeeklyPlanLocal extends HiveObject { ... }

@HiveType(typeId: 2)
class DailyCompletionLocal extends HiveObject { ... }

@HiveType(typeId: 3)
class SyncQueueItem extends HiveObject { ... }
```

### Authentication & Security

#### ADR-003: Firebase Authentication Flow

**Decision:** Email/password authentication with persistent sessions

**Context:** PRD requires email/password auth; need secure token management

**Architecture:**

```
┌─────────────────────────────────────────────────────┐
│                  AUTH FLOW                           │
├─────────────────────────────────────────────────────┤
│                                                      │
│  App Start                                           │
│      ↓                                               │
│  [Check Auth State Stream]                           │
│      ↓                                               │
│  ┌────────────────────────────────────┐             │
│  │ Authenticated?                      │             │
│  └────────────────────────────────────┘             │
│      ↓ No                    ↓ Yes                   │
│  [Login Screen]         [Load User Data]            │
│      ↓                        ↓                      │
│  [Firebase Auth]        [Dashboard]                 │
│      ↓                                               │
│  [Create Firestore User Doc]                        │
│      ↓                                               │
│  [Onboarding Check]                                 │
│      ↓                                               │
│  ┌────────────────────────────────────┐             │
│  │ Onboarding Complete?                │             │
│  └────────────────────────────────────┘             │
│      ↓ No                    ↓ Yes                   │
│  [Onboarding Flow]      [Dashboard]                 │
│                                                      │
└─────────────────────────────────────────────────────┘
```

**Security Implementation:**

```dart
// Riverpod auth state provider
@riverpod
Stream<User?> authStateChanges(AuthStateChangesRef ref) {
  return FirebaseAuth.instance.authStateChanges();
}

// Route guard using go_router redirect
redirect: (context, state) {
  final isAuthenticated = ref.read(authStateProvider).valueOrNull != null;
  final isOnLoginPage = state.matchedLocation == '/login';
  
  if (!isAuthenticated && !isOnLoginPage) return '/login';
  if (isAuthenticated && isOnLoginPage) return '/dashboard';
  return null;
}
```

#### ADR-004: API Key Security

**Decision:** Environment variables with flutter_dotenv, never committed to repository

**Context:** Gemini API key must be protected; Firebase config is less sensitive but should be managed

**Implementation:**

```
.env (gitignored)
├── GEMINI_API_KEY=your_api_key_here

.env.example (committed)
├── GEMINI_API_KEY=your_api_key_here

pubspec.yaml
├── assets:
│     - .env
```

**Runtime Loading:**

```dart
Future<void> main() async {
  await dotenv.load(fileName: '.env');
  // Access via dotenv.env['GEMINI_API_KEY']
}
```

#### ADR-005: Firestore Security Rules

**Decision:** User-scoped access with strict rules

**Firestore Rules:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // User documents - only owner can read/write
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Plans subcollection
      match /plans/{planId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Completions subcollection
      match /completions/{completionId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Admin aggregates (read-only, admin SDK writes)
    match /analytics/{docId} {
      allow read: if request.auth != null && request.auth.token.admin == true;
      allow write: if false; // Only Cloud Functions
    }
  }
}
```

### AI Integration Architecture

#### ADR-006: Gemini API Integration Pattern

**Decision:** Repository pattern with structured prompts and JSON schema validation

**Context:** AI responses must be consistent, parseable, and safe for fitness guidance

**Architecture:**

```
┌─────────────────────────────────────────────────────────────────┐
│                    AI SERVICE LAYER                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐                                           │
│  │  GeminiService   │                                           │
│  │  (Repository)    │                                           │
│  └────────┬─────────┘                                           │
│           │                                                      │
│  ┌────────▼─────────┐    ┌──────────────────┐                   │
│  │ PromptBuilder    │───→│ System Prompt    │                   │
│  │                  │    │ + User Context   │                   │
│  └────────┬─────────┘    └──────────────────┘                   │
│           │                                                      │
│  ┌────────▼─────────┐                                           │
│  │ Gemini API Call  │                                           │
│  │ (with retry)     │                                           │
│  └────────┬─────────┘                                           │
│           │                                                      │
│  ┌────────▼─────────┐    ┌──────────────────┐                   │
│  │ ResponseParser   │───→│ JSON Validation  │                   │
│  │                  │    │ + Schema Check   │                   │
│  └────────┬─────────┘    └──────────────────┘                   │
│           │                                                      │
│  ┌────────▼─────────┐                                           │
│  │ WeeklyPlan Model │                                           │
│  │ (Freezed)        │                                           │
│  └──────────────────┘                                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**System Prompt Template:**

```dart
const systemPrompt = '''
You are FitGenie, an AI personal trainer and nutritionist.

CRITICAL RULES:
1. ONLY suggest exercises using the user's available equipment: {equipment}
2. RESPECT all dietary restrictions: {dietaryRestrictions}
3. NEVER suggest dangerous exercises for beginners
4. Always include warm-up and cool-down
5. Provide exercise modifications when appropriate

OUTPUT FORMAT:
Return ONLY valid JSON matching this schema:
{jsonSchema}

USER CONTEXT:
- Age: {age}
- Weight: {weight} {weightUnit}
- Height: {height} {heightUnit}
- Goal: {goal}
- Equipment: {equipment}
- Dietary Restrictions: {dietaryRestrictions}
''';
```

**JSON Schema for Plan:**

```dart
@freezed
class WeeklyPlan with _$WeeklyPlan {
  const factory WeeklyPlan({
    required DayPlan monday,
    required DayPlan tuesday,
    required DayPlan wednesday,
    required DayPlan thursday,
    required DayPlan friday,
    required DayPlan saturday,
    required DayPlan sunday,
  }) = _WeeklyPlan;

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) => 
      _$WeeklyPlanFromJson(json);
}

@freezed
class DayPlan with _$DayPlan {
  const factory DayPlan({
    required Workout workout,
    required Meals meals,
  }) = _DayPlan;
}

@freezed
class Workout with _$Workout {
  const factory Workout({
    required String name,
    required String duration,
    required String warmup,
    required List<Exercise> exercises,
    required String cooldown,
  }) = _Workout;
}

@freezed
class Exercise with _$Exercise {
  const factory Exercise({
    required String name,
    required String sets,
    required String reps,
    required String restTime,
    required String instructions,
    required List<String> equipmentUsed,
  }) = _Exercise;
}
```

#### ADR-007: AI Error Handling & Retry Strategy

**Decision:** Exponential backoff with graceful degradation

**Implementation:**

```dart
class GeminiService {
  static const maxRetries = 3;
  static const baseDelay = Duration(seconds: 1);

  Future<WeeklyPlan> generatePlan(UserProfile profile) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        final response = await _callGeminiApi(profile);
        return _parseAndValidate(response);
      } on GeminiException catch (e) {
        attempt++;
        if (attempt >= maxRetries) rethrow;
        
        final delay = baseDelay * pow(2, attempt);
        await Future.delayed(delay);
      } on JsonParseException catch (e) {
        // AI returned invalid JSON - retry with stricter prompt
        attempt++;
        if (attempt >= maxRetries) {
          throw AiResponseException('Unable to generate valid plan');
        }
      }
    }
    throw AiResponseException('Max retries exceeded');
  }
}
```

### Frontend Architecture

#### ADR-008: Clean Architecture Layers

**Decision:** Feature-first organization with clean architecture principles

**Layer Responsibilities:**

| Layer            | Responsibility                           | Dependencies     |
| ---------------- | ---------------------------------------- | ---------------- |
| **Presentation** | Widgets, screens, view logic             | Domain           |
| **Application**  | State management (Riverpod providers)    | Domain           |
| **Domain**       | Entities, repository interfaces          | None             |
| **Data**         | Repository implementations, data sources | Domain, External |
| **Core**         | Shared utilities, constants, extensions  | None             |

**Feature-First Structure:**

```
lib/
├── core/
│   ├── constants/
│   ├── exceptions/
│   ├── extensions/
│   ├── theme/
│   └── utils/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── onboarding/
│   ├── plan_generation/
│   ├── dashboard/
│   ├── chat/
│   └── profile/
├── shared/
│   ├── widgets/
│   └── providers/
└── main.dart
```

#### ADR-009: State Management Pattern

**Decision:** Riverpod with AsyncValue for loading/error states

**Patterns:**

```dart
// Repository provider
@riverpod
PlanRepository planRepository(PlanRepositoryRef ref) {
  return PlanRepository(
    firestore: ref.watch(firestoreProvider),
    hive: ref.watch(hivePlanBoxProvider),
    gemini: ref.watch(geminiServiceProvider),
  );
}

// Async state provider for current plan
@riverpod
Future<WeeklyPlan?> currentPlan(CurrentPlanRef ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  
  final repository = ref.watch(planRepositoryProvider);
  return repository.getCurrentPlan(userId);
}

// UI consumption with AsyncValue
class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(currentPlanProvider);
    
    return planAsync.when(
      data: (plan) => plan != null 
          ? TodaysPlanView(plan: plan)
          : GeneratePlanPrompt(),
      loading: () => PlanSkeletonLoader(),
      error: (e, st) => ErrorDisplay(error: e, onRetry: () => ref.refresh(currentPlanProvider)),
    );
  }
}
```

#### ADR-010: Navigation Architecture

**Decision:** go_router with shell routes and route guards

**Router Configuration:**

```dart
final router = GoRouter(
  initialLocation: '/dashboard',
  redirect: _authGuard,
  routes: [
    // Auth routes (no shell)
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    
    // Main app routes (with bottom nav shell)
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) => const ChatScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
```

### Infrastructure & Deployment

#### ADR-011: CI/CD Pipeline

**Decision:** GitHub Actions for automated testing and builds

**Workflow:**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.x'
          channel: 'stable'
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter analyze
      - run: flutter test --coverage

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v3
        with:
          name: android-release
          path: build/app/outputs/flutter-apk/app-release.apk
```

#### ADR-012: Environment Configuration

**Decision:** Separate configs for development, staging, and production

**Structure:**

```
├── .env.development
├── .env.staging
├── .env.production
├── .env.example
└── lib/
    └── core/
        └── config/
            └── environment.dart
```

**Environment Loading:**

```dart
enum Environment { development, staging, production }

class AppConfig {
  static late Environment environment;
  
  static Future<void> initialize(Environment env) async {
    environment = env;
    await dotenv.load(fileName: '.env.${env.name}');
  }
  
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY']!;
  static bool get isProduction => environment == Environment.production;
}
```

### Decision Impact Analysis

**Implementation Sequence:**

1. **Project Setup** - Flutter create, dependencies, folder structure
2. **Core Layer** - Theme, constants, exceptions, utilities
3. **Authentication** - Firebase Auth integration, providers, screens
4. **Data Layer** - Hive setup, Firestore integration, repositories
5. **Onboarding** - Profile collection, Firestore storage
6. **AI Integration** - Gemini service, prompt engineering, response parsing
7. **Dashboard** - Plan display, task completion, streak tracking
8. **Chat** - Modification interface, AI communication
9. **Offline Sync** - Background sync, conflict resolution
10. **Admin Dashboard** - Flutter Web, analytics views

**Cross-Component Dependencies:**

```
Auth ──────────────────────────────┐
  │                                 │
  ↓                                 ↓
Onboarding ───→ Plan Generation ───→ Dashboard
                      │                  │
                      ↓                  ↓
                    Chat ←────────→ Offline Sync
```

---

## Implementation Patterns & Consistency Rules

### Critical Conflict Points Identified

**15 areas** where implementation inconsistency could cause issues:

| Category      | Conflict Point           | Resolution                    |
| ------------- | ------------------------ | ----------------------------- |
| Naming        | File naming convention   | snake_case for files          |
| Naming        | Class/widget naming      | PascalCase                    |
| Naming        | Variable/function naming | camelCase                     |
| Naming        | Firestore field naming   | camelCase                     |
| Structure     | Test file location       | Co-located in same directory  |
| Structure     | Feature organization     | Feature-first folders         |
| Format        | Date handling            | ISO 8601 strings              |
| Format        | API response wrapper     | AsyncValue<T> pattern         |
| Communication | Provider naming          | descriptive + Provider suffix |
| Communication | Error types              | Typed exception classes       |
| Process       | Loading states           | AsyncValue.loading            |
| Process       | Error recovery           | Exponential backoff           |
| Process       | Validation timing        | On submit, not on change      |

### Naming Patterns

#### File Naming Conventions

**Rule:** All Dart files use `snake_case.dart`

```
✅ CORRECT:
lib/features/auth/presentation/login_screen.dart
lib/features/dashboard/domain/weekly_plan.dart
lib/core/utils/date_formatter.dart

❌ INCORRECT:
lib/features/auth/presentation/LoginScreen.dart
lib/features/dashboard/domain/WeeklyPlan.dart
lib/core/utils/DateFormatter.dart
```

#### Class & Widget Naming

**Rule:** Classes and widgets use `PascalCase`

```dart
// ✅ CORRECT:
class LoginScreen extends ConsumerWidget { }
class WeeklyPlan { }
class GeminiService { }
class PlanRepository { }

// ❌ INCORRECT:
class loginScreen extends ConsumerWidget { }
class weekly_plan { }
class gemini_service { }
```

#### Variable & Function Naming

**Rule:** Variables and functions use `camelCase`

```dart
// ✅ CORRECT:
final String userId = 'abc123';
Future<void> generatePlan() async { }
bool get isAuthenticated => _user != null;

// ❌ INCORRECT:
final String user_id = 'abc123';
Future<void> GeneratePlan() async { }
bool get is_authenticated => _user != null;
```

#### Provider Naming

**Rule:** Providers use descriptive names with appropriate suffixes

```dart
// ✅ CORRECT:
@riverpod
Stream<User?> authStateChanges(AuthStateChangesRef ref) { }

@riverpod
Future<WeeklyPlan?> currentPlan(CurrentPlanRef ref) { }

@riverpod
PlanRepository planRepository(PlanRepositoryRef ref) { }

// Provider usage:
ref.watch(authStateChangesProvider);
ref.watch(currentPlanProvider);
ref.watch(planRepositoryProvider);
```

#### Firestore Field Naming

**Rule:** Firestore documents use `camelCase` for field names

```dart
// ✅ CORRECT Firestore document:
{
  "userId": "abc123",
  "createdAt": "2025-12-21T10:00:00Z",
  "weeklyPlan": { ... },
  "dietaryRestrictions": ["vegetarian", "nut-free"]
}

// ❌ INCORRECT:
{
  "user_id": "abc123",
  "created_at": "2025-12-21T10:00:00Z",
  "weekly_plan": { ... }
}
```

### Structure Patterns

#### Feature-First Organization

**Rule:** Organize by feature, then by layer within each feature

```
lib/
├── core/                          # Shared across all features
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── app_sizes.dart
│   ├── exceptions/
│   │   ├── app_exception.dart
│   │   ├── auth_exception.dart
│   │   ├── ai_exception.dart
│   │   └── network_exception.dart
│   ├── extensions/
│   │   ├── context_extensions.dart
│   │   └── date_extensions.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── text_styles.dart
│   └── utils/
│       ├── validators.dart
│       └── formatters.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository.dart
│   │   │   └── auth_repository.g.dart      # Generated
│   │   ├── domain/
│   │   │   └── user_model.dart
│   │   ├── presentation/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── widgets/
│   │   │       └── auth_form.dart
│   │   └── auth_providers.dart
│   │
│   ├── onboarding/
│   │   ├── data/
│   │   ├── domain/
│   │   │   ├── onboarding_state.dart
│   │   │   └── user_profile.dart
│   │   ├── presentation/
│   │   │   ├── onboarding_screen.dart
│   │   │   └── steps/
│   │   │       ├── age_step.dart
│   │   │       ├── weight_step.dart
│   │   │       ├── goal_step.dart
│   │   │       ├── equipment_step.dart
│   │   │       └── dietary_step.dart
│   │   └── onboarding_providers.dart
│   │
│   ├── plan_generation/
│   │   ├── data/
│   │   │   ├── gemini_service.dart
│   │   │   ├── plan_repository.dart
│   │   │   └── prompt_builder.dart
│   │   ├── domain/
│   │   │   ├── weekly_plan.dart
│   │   │   ├── day_plan.dart
│   │   │   ├── workout.dart
│   │   │   ├── exercise.dart
│   │   │   └── meal.dart
│   │   ├── presentation/
│   │   │   └── plan_generation_screen.dart
│   │   └── plan_providers.dart
│   │
│   ├── dashboard/
│   │   ├── data/
│   │   │   ├── completion_repository.dart
│   │   │   └── streak_repository.dart
│   │   ├── domain/
│   │   │   ├── daily_completion.dart
│   │   │   └── streak_data.dart
│   │   ├── presentation/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── today_header.dart
│   │   │   │   ├── meal_card.dart
│   │   │   │   ├── workout_card.dart
│   │   │   │   ├── exercise_tile.dart
│   │   │   │   ├── streak_badge.dart
│   │   │   │   └── day_selector.dart
│   │   └── dashboard_providers.dart
│   │
│   ├── chat/
│   │   ├── data/
│   │   │   └── chat_repository.dart
│   │   ├── domain/
│   │   │   └── chat_message.dart
│   │   ├── presentation/
│   │   │   ├── chat_screen.dart
│   │   │   └── widgets/
│   │   │       ├── chat_bubble.dart
│   │   │       ├── chat_input.dart
│   │   │       └── modification_chips.dart
│   │   └── chat_providers.dart
│   │
│   └── profile/
│       ├── data/
│       ├── domain/
│       ├── presentation/
│       │   ├── profile_screen.dart
│       │   └── edit_profile_screen.dart
│       └── profile_providers.dart
│
├── shared/
│   ├── widgets/
│   │   ├── app_button.dart
│   │   ├── app_text_field.dart
│   │   ├── loading_overlay.dart
│   │   ├── skeleton_loader.dart
│   │   ├── error_display.dart
│   │   └── offline_banner.dart
│   ├── providers/
│   │   ├── connectivity_provider.dart
│   │   └── firebase_providers.dart
│   └── services/
│       ├── hive_service.dart
│       └── sync_service.dart
│
├── routing/
│   ├── app_router.dart
│   └── route_guards.dart
│
└── main.dart
```

#### Test File Location

**Rule:** Tests co-located with source files, suffixed with `_test.dart`

```
lib/features/auth/data/auth_repository.dart
lib/features/auth/data/auth_repository_test.dart  # Co-located

lib/features/plan_generation/domain/weekly_plan.dart
lib/features/plan_generation/domain/weekly_plan_test.dart
```

**Integration Tests:**

```
integration_test/
├── auth_flow_test.dart
├── onboarding_flow_test.dart
└── plan_generation_test.dart
```

### Format Patterns

#### Date & Time Handling

**Rule:** Use ISO 8601 strings for storage, `DateTime` in code

```dart
// ✅ CORRECT:
// Firestore storage: ISO 8601 string or Timestamp
final createdAt = DateTime.now().toIso8601String();

// JSON serialization
@freezed
class DailyCompletion with _$DailyCompletion {
  const factory DailyCompletion({
    @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
    required DateTime date,
  }) = _DailyCompletion;
}

DateTime _dateFromJson(String json) => DateTime.parse(json);
String _dateToJson(DateTime date) => date.toIso8601String();

// Display formatting
extension DateFormatting on DateTime {
  String get displayDate => DateFormat('EEEE, MMMM d').format(this);
  String get shortDate => DateFormat('MMM d').format(this);
}
```

#### Error Response Format

**Rule:** Typed exceptions with user-friendly messages

```dart
// Exception hierarchy
abstract class AppException implements Exception {
  String get message;
  String get userFriendlyMessage;
}

class AuthException extends AppException {
  final AuthErrorType type;
  final String message;
  
  AuthException(this.type, this.message);
  
  @override
  String get userFriendlyMessage => switch (type) {
    AuthErrorType.invalidEmail => 'Please enter a valid email address',
    AuthErrorType.wrongPassword => 'Incorrect password. Please try again.',
    AuthErrorType.userNotFound => 'No account found with this email',
    AuthErrorType.networkError => 'Connection failed. Please check your internet.',
    _ => 'Authentication failed. Please try again.',
  };
}

class AiException extends AppException {
  final AiErrorType type;
  final String message;
  
  AiException(this.type, this.message);
  
  @override
  String get userFriendlyMessage => switch (type) {
    AiErrorType.rateLimited => 'Our AI is taking a short break. Please wait a moment.',
    AiErrorType.invalidResponse => 'Unable to generate plan. Retrying...',
    AiErrorType.networkError => 'Connection lost. Using cached plan.',
    _ => 'Something went wrong. Please try again.',
  };
}
```

#### Loading & Async State Pattern

**Rule:** Use Riverpod `AsyncValue<T>` consistently

```dart
// ✅ CORRECT - Provider returns AsyncValue
@riverpod
Future<WeeklyPlan?> currentPlan(CurrentPlanRef ref) async {
  final repository = ref.watch(planRepositoryProvider);
  return repository.getCurrentPlan();
}

// ✅ CORRECT - UI handles all states
class PlanDisplay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(currentPlanProvider);
    
    return planAsync.when(
      data: (plan) => plan != null 
          ? TodaysPlanView(plan: plan) 
          : EmptyPlanView(),
      loading: () => const PlanSkeletonLoader(),
      error: (error, stack) => ErrorDisplay(
        error: error,
        onRetry: () => ref.invalidate(currentPlanProvider),
      ),
    );
  }
}

// ❌ INCORRECT - Manual loading states
class _PlanDisplayState extends State<PlanDisplay> {
  bool isLoading = false;
  String? error;
  WeeklyPlan? plan;
  
  // Don't do this - use AsyncValue instead
}
```

### Communication Patterns

#### Provider Communication

**Rule:** Providers communicate via `ref.watch` and `ref.read`

```dart
// ✅ CORRECT - Provider dependencies
@riverpod
Future<void> generateNewPlan(GenerateNewPlanRef ref) async {
  // Watch dependencies
  final userId = ref.watch(currentUserIdProvider);
  final profile = ref.watch(userProfileProvider);
  final gemini = ref.watch(geminiServiceProvider);
  final repository = ref.watch(planRepositoryProvider);
  
  if (userId == null || profile == null) {
    throw AuthException(AuthErrorType.notAuthenticated, 'User not logged in');
  }
  
  final plan = await gemini.generatePlan(profile);
  await repository.savePlan(userId, plan);
  
  // Invalidate dependent providers
  ref.invalidate(currentPlanProvider);
}
```

#### Event/Action Naming

**Rule:** Actions describe intent, not implementation

```dart
// ✅ CORRECT - Intent-focused naming
ref.read(generateNewPlanProvider.future);
ref.read(markTaskCompleteProvider(taskId).future);
ref.read(sendModificationRequestProvider(message).future);
ref.read(updateStreakProvider.future);

// ❌ INCORRECT - Implementation-focused
ref.read(callGeminiApiProvider.future);
ref.read(writeToFirestoreProvider(data).future);
```

### Process Patterns

#### Error Handling Pattern

**Rule:** Catch, transform, and propagate typed errors

```dart
// Repository layer - catch and transform
class PlanRepository {
  Future<WeeklyPlan> generatePlan(UserProfile profile) async {
    try {
      final response = await _geminiService.generatePlan(profile);
      return _parseResponse(response);
    } on GeminiRateLimitException {
      throw AiException(AiErrorType.rateLimited, 'Rate limit exceeded');
    } on GeminiInvalidResponseException catch (e) {
      throw AiException(AiErrorType.invalidResponse, e.message);
    } on SocketException {
      throw NetworkException('No internet connection');
    }
  }
}

// UI layer - display user-friendly message
ref.watch(generatePlanProvider).when(
  error: (error, _) {
    if (error is AppException) {
      return ErrorDisplay(message: error.userFriendlyMessage);
    }
    return ErrorDisplay(message: 'An unexpected error occurred');
  },
  // ...
);
```

#### Retry Pattern

**Rule:** Exponential backoff with max 3 attempts

```dart
class RetryHelper {
  static const maxRetries = 3;
  static const baseDelay = Duration(seconds: 1);
  
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    required bool Function(Exception) shouldRetry,
  }) async {
    int attempt = 0;
    
    while (true) {
      try {
        return await operation();
      } on Exception catch (e) {
        attempt++;
        
        if (attempt >= maxRetries || !shouldRetry(e)) {
          rethrow;
        }
        
        final delay = baseDelay * pow(2, attempt - 1);
        await Future.delayed(delay);
      }
    }
  }
}

// Usage
final result = await RetryHelper.withRetry(
  operation: () => geminiService.generatePlan(profile),
  shouldRetry: (e) => e is GeminiRateLimitException || e is SocketException,
);
```

#### Validation Pattern

**Rule:** Validate on submit, not on every keystroke

```dart
// ✅ CORRECT - Validate on submit
class LoginForm extends ConsumerWidget {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  void _handleSubmit(WidgetRef ref) {
    if (_formKey.currentState!.validate()) {
      ref.read(loginProvider(
        email: _emailController.text,
        password: _passwordController.text,
      ).future);
    }
  }
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            validator: Validators.email,  // Runs on submit
          ),
          // ...
          ElevatedButton(
            onPressed: () => _handleSubmit(ref),
            child: Text('Login'),
          ),
        ],
      ),
    );
  }
}
```

### Enforcement Guidelines

**All AI Agents and Developers MUST:**

1. ✅ Use `snake_case` for all file names
2. ✅ Use `PascalCase` for classes and widgets
3. ✅ Use `camelCase` for variables, functions, and Firestore fields
4. ✅ Organize code feature-first, then layer-within-feature
5. ✅ Co-locate tests with source files
6. ✅ Use `AsyncValue<T>` for all async state
7. ✅ Throw typed `AppException` subclasses
8. ✅ Use ISO 8601 for date serialization
9. ✅ Implement retry with exponential backoff (max 3)
10. ✅ Validate forms on submit, not on change

**Pattern Enforcement:**

- Code review checklist references this document
- Linting rules enforce naming conventions
- Unit tests verify exception typing
- PR template includes pattern compliance checkbox

### Anti-Patterns to Avoid

```dart
// ❌ ANTI-PATTERN: Mixed naming conventions
class user_profile { }  // Should be UserProfile
void GetUserData() { }   // Should be getUserData()
final user_name = '';    // Should be userName

// ❌ ANTI-PATTERN: Manual loading states
bool isLoading = false;
String? errorMessage;
// Use AsyncValue instead

// ❌ ANTI-PATTERN: Generic exceptions
throw Exception('Something went wrong');
// Use typed AppException subclasses

// ❌ ANTI-PATTERN: Tests in separate directory
test/features/auth/...  // Tests should be co-located

// ❌ ANTI-PATTERN: Layer-first organization
lib/data/repositories/...
lib/presentation/screens/...
// Use feature-first organization
```

---

## Project Structure & Architectural Boundaries

### Complete Project Directory Structure

```
fitgenie/
├── README.md
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
├── build.yaml
├── .env.example
├── .env.development
├── .env.production
├── .gitignore
├── .metadata
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── release.yml
│
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   ├── google-services.json          # Firebase config (gitignored)
│   │   └── src/
│   │       └── main/
│   │           ├── AndroidManifest.xml
│   │           └── kotlin/
│   └── build.gradle
│
├── ios/
│   ├── Runner/
│   │   ├── Info.plist
│   │   ├── GoogleService-Info.plist      # Firebase config (gitignored)
│   │   └── AppDelegate.swift
│   └── Podfile
│
├── web/
│   ├── index.html
│   └── manifest.json
│
├── assets/
│   ├── images/
│   │   ├── logo.png
│   │   ├── onboarding/
│   │   │   ├── step_1.png
│   │   │   ├── step_2.png
│   │   │   └── step_3.png
│   │   └── equipment/
│   │       ├── dumbbells.png
│   │       ├── pullup_bar.png
│   │       └── yoga_mat.png
│   └── icons/
│       ├── workout.svg
│       ├── meal.svg
│       └── streak.svg
│
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart             # FlutterFire generated
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_strings.dart
│   │   │   ├── app_sizes.dart
│   │   │   └── dietary_options.dart
│   │   │
│   │   ├── exceptions/
│   │   │   ├── app_exception.dart
│   │   │   ├── auth_exception.dart
│   │   │   ├── ai_exception.dart
│   │   │   ├── network_exception.dart
│   │   │   └── sync_exception.dart
│   │   │
│   │   ├── extensions/
│   │   │   ├── context_extensions.dart
│   │   │   ├── date_extensions.dart
│   │   │   └── string_extensions.dart
│   │   │
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── color_scheme.dart
│   │   │   └── text_styles.dart
│   │   │
│   │   ├── utils/
│   │   │   ├── validators.dart
│   │   │   ├── formatters.dart
│   │   │   ├── retry_helper.dart
│   │   │   └── json_parser.dart
│   │   │
│   │   └── config/
│   │       ├── environment.dart
│   │       └── app_config.dart
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── auth_repository.dart
│   │   │   │   └── auth_repository.g.dart
│   │   │   ├── domain/
│   │   │   │   ├── user_model.dart
│   │   │   │   ├── user_model.freezed.dart
│   │   │   │   └── user_model.g.dart
│   │   │   ├── presentation/
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── register_screen.dart
│   │   │   │   ├── forgot_password_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── auth_form.dart
│   │   │   │       └── social_buttons.dart
│   │   │   ├── auth_providers.dart
│   │   │   ├── auth_providers.g.dart
│   │   │   └── auth_repository_test.dart
│   │   │
│   │   ├── onboarding/
│   │   │   ├── data/
│   │   │   │   ├── onboarding_repository.dart
│   │   │   │   └── onboarding_repository.g.dart
│   │   │   ├── domain/
│   │   │   │   ├── onboarding_state.dart
│   │   │   │   ├── onboarding_state.freezed.dart
│   │   │   │   ├── user_profile.dart
│   │   │   │   ├── user_profile.freezed.dart
│   │   │   │   └── user_profile.g.dart
│   │   │   ├── presentation/
│   │   │   │   ├── onboarding_screen.dart
│   │   │   │   └── steps/
│   │   │   │       ├── welcome_step.dart
│   │   │   │       ├── age_weight_step.dart
│   │   │   │       ├── height_step.dart
│   │   │   │       ├── goal_step.dart
│   │   │   │       ├── equipment_step.dart
│   │   │   │       ├── dietary_step.dart
│   │   │   │       └── review_step.dart
│   │   │   ├── onboarding_providers.dart
│   │   │   └── onboarding_providers.g.dart
│   │   │
│   │   ├── plan_generation/
│   │   │   ├── data/
│   │   │   │   ├── gemini_service.dart
│   │   │   │   ├── gemini_service_test.dart
│   │   │   │   ├── plan_repository.dart
│   │   │   │   ├── plan_repository.g.dart
│   │   │   │   ├── plan_local_datasource.dart
│   │   │   │   ├── plan_remote_datasource.dart
│   │   │   │   └── prompt_builder.dart
│   │   │   ├── domain/
│   │   │   │   ├── weekly_plan.dart
│   │   │   │   ├── weekly_plan.freezed.dart
│   │   │   │   ├── weekly_plan.g.dart
│   │   │   │   ├── day_plan.dart
│   │   │   │   ├── day_plan.freezed.dart
│   │   │   │   ├── workout.dart
│   │   │   │   ├── workout.freezed.dart
│   │   │   │   ├── exercise.dart
│   │   │   │   ├── exercise.freezed.dart
│   │   │   │   ├── meal.dart
│   │   │   │   ├── meal.freezed.dart
│   │   │   │   └── weekly_plan_test.dart
│   │   │   ├── presentation/
│   │   │   │   ├── plan_generation_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       └── generation_animation.dart
│   │   │   ├── plan_providers.dart
│   │   │   └── plan_providers.g.dart
│   │   │
│   │   ├── dashboard/
│   │   │   ├── data/
│   │   │   │   ├── completion_repository.dart
│   │   │   │   ├── completion_repository.g.dart
│   │   │   │   ├── streak_repository.dart
│   │   │   │   └── streak_repository.g.dart
│   │   │   ├── domain/
│   │   │   │   ├── daily_completion.dart
│   │   │   │   ├── daily_completion.freezed.dart
│   │   │   │   ├── streak_data.dart
│   │   │   │   └── streak_data.freezed.dart
│   │   │   ├── presentation/
│   │   │   │   ├── dashboard_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── today_header.dart
│   │   │   │       ├── day_selector.dart
│   │   │   │       ├── meal_card.dart
│   │   │   │       ├── workout_card.dart
│   │   │   │       ├── exercise_tile.dart
│   │   │   │       ├── streak_badge.dart
│   │   │   │       ├── task_checkbox.dart
│   │   │   │       └── completion_summary.dart
│   │   │   ├── dashboard_providers.dart
│   │   │   └── dashboard_providers.g.dart
│   │   │
│   │   ├── chat/
│   │   │   ├── data/
│   │   │   │   ├── chat_repository.dart
│   │   │   │   └── chat_repository.g.dart
│   │   │   ├── domain/
│   │   │   │   ├── chat_message.dart
│   │   │   │   ├── chat_message.freezed.dart
│   │   │   │   └── modification_request.dart
│   │   │   ├── presentation/
│   │   │   │   ├── chat_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── chat_bubble.dart
│   │   │   │       ├── chat_input.dart
│   │   │   │       ├── modification_chips.dart
│   │   │   │       └── typing_indicator.dart
│   │   │   ├── chat_providers.dart
│   │   │   └── chat_providers.g.dart
│   │   │
│   │   └── profile/
│   │       ├── data/
│   │       │   ├── profile_repository.dart
│   │       │   └── profile_repository.g.dart
│   │       ├── presentation/
│   │       │   ├── profile_screen.dart
│   │       │   ├── edit_profile_screen.dart
│   │       │   └── widgets/
│   │       │       ├── profile_header.dart
│   │       │       ├── stats_card.dart
│   │       │       └── settings_tile.dart
│   │       ├── profile_providers.dart
│   │       └── profile_providers.g.dart
│   │
│   ├── shared/
│   │   ├── widgets/
│   │   │   ├── app_button.dart
│   │   │   ├── app_text_field.dart
│   │   │   ├── loading_overlay.dart
│   │   │   ├── skeleton_loader.dart
│   │   │   ├── error_display.dart
│   │   │   ├── offline_banner.dart
│   │   │   ├── animated_check.dart
│   │   │   └── empty_state.dart
│   │   │
│   │   ├── providers/
│   │   │   ├── connectivity_provider.dart
│   │   │   ├── connectivity_provider.g.dart
│   │   │   ├── firebase_providers.dart
│   │   │   └── firebase_providers.g.dart
│   │   │
│   │   └── services/
│   │       ├── hive_service.dart
│   │       ├── sync_service.dart
│   │       └── sync_queue.dart
│   │
│   └── routing/
│       ├── app_router.dart
│       ├── app_router.g.dart
│       └── route_guards.dart
│
├── integration_test/
│   ├── app_test.dart
│   ├── auth_flow_test.dart
│   ├── onboarding_flow_test.dart
│   └── plan_generation_test.dart
│
├── firestore.rules
├── firestore.indexes.json
└── firebase.json
```

### Architectural Boundaries

#### Layer Boundaries

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PRESENTATION LAYER                                 │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Screens (StatelessWidget/ConsumerWidget)                            │   │
│  │  └── Widgets (Reusable UI components)                                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              ↓ ref.watch()                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                           APPLICATION LAYER                                  │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Riverpod Providers (State + Business Logic)                         │   │
│  │  └── Feature Providers (auth_providers.dart, plan_providers.dart)    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              ↓ depends on                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                             DOMAIN LAYER                                     │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Entities (Freezed data classes)                                     │   │
│  │  └── weekly_plan.dart, user_profile.dart, etc.                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              ↓ used by                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                              DATA LAYER                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Repositories (Interface implementations)                            │   │
│  │  ├── Remote Datasources (Firestore, Gemini API)                      │   │
│  │  └── Local Datasources (Hive)                                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Feature Boundaries

| Feature             | Owns                         | Exposes                                               | Consumes                 |
| ------------------- | ---------------------------- | ----------------------------------------------------- | ------------------------ |
| **auth**            | User authentication state    | `authStateChangesProvider`, `currentUserIdProvider`   | Firebase Auth            |
| **onboarding**      | User profile data            | `userProfileProvider`, `isOnboardingCompleteProvider` | auth                     |
| **plan_generation** | AI plan generation           | `currentPlanProvider`, `generatePlanProvider`         | auth, onboarding, Gemini |
| **dashboard**       | Task completion, streaks     | `dailyCompletionProvider`, `streakProvider`           | auth, plan_generation    |
| **chat**            | Chat messages, modifications | `chatMessagesProvider`, `sendModificationProvider`    | auth, plan_generation    |
| **profile**         | Profile display/edit         | `profileScreenProvider`                               | auth, onboarding         |

#### External Service Boundaries

```
┌───────────────────────────────────────────────────────────────────────────┐
│                              FITGENIE APP                                  │
├───────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│   ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐        │
│   │  AuthRepository │   │ PlanRepository  │   │ GeminiService   │        │
│   └────────┬────────┘   └────────┬────────┘   └────────┬────────┘        │
│            │                     │                      │                  │
└────────────┼─────────────────────┼──────────────────────┼──────────────────┘
             │                     │                      │
             ↓                     ↓                      ↓
    ┌────────────────┐    ┌────────────────┐    ┌────────────────┐
    │  Firebase Auth │    │   Firestore    │    │  Gemini API    │
    │                │    │                │    │                │
    │  - Sign in     │    │  - Users       │    │  - Generate    │
    │  - Sign up     │    │  - Plans       │    │  - Modify      │
    │  - Sign out    │    │  - Completions │    │  - Chat        │
    │  - Reset pwd   │    │                │    │                │
    └────────────────┘    └────────────────┘    └────────────────┘
```

### Requirements to Structure Mapping

#### Functional Requirements Mapping

| FR Domain                          | Primary Location                | Related Files                                                            |
| ---------------------------------- | ------------------------------- | ------------------------------------------------------------------------ |
| **User Management (FR1-FR6)**      | `lib/features/auth/`            | `auth_repository.dart`, `login_screen.dart`, `register_screen.dart`      |
| **Onboarding (FR7-FR15)**          | `lib/features/onboarding/`      | `onboarding_screen.dart`, `steps/*.dart`, `user_profile.dart`            |
| **AI Plan Generation (FR16-FR21)** | `lib/features/plan_generation/` | `gemini_service.dart`, `prompt_builder.dart`, `plan_repository.dart`     |
| **Dashboard (FR22-FR30)**          | `lib/features/dashboard/`       | `dashboard_screen.dart`, `meal_card.dart`, `workout_card.dart`           |
| **Chat (FR31-FR36)**               | `lib/features/chat/`            | `chat_screen.dart`, `chat_repository.dart`, `modification_chips.dart`    |
| **Progress Tracking (FR37-FR40)**  | `lib/features/dashboard/`       | `streak_repository.dart`, `streak_badge.dart`, `completion_summary.dart` |
| **Offline (FR41-FR44)**            | `lib/shared/services/`          | `hive_service.dart`, `sync_service.dart`, `offline_banner.dart`          |
| **Admin (FR45-FR49)**              | Separate Flutter Web project    | `admin/` (separate codebase)                                             |

#### Non-Functional Requirements Mapping

| NFR                            | Implementation Location                                               |
| ------------------------------ | --------------------------------------------------------------------- |
| **Performance (NFR1-5)**       | Skeleton loaders in `shared/widgets/`, caching in `hive_service.dart` |
| **Security (NFR6-10)**         | `firestore.rules`, `.env.*` files, `route_guards.dart`                |
| **Reliability (NFR11-14)**     | `retry_helper.dart`, `sync_queue.dart`, exception classes             |
| **Usability (NFR15-18)**       | `app_theme.dart`, `error_display.dart`, responsive widgets            |
| **Maintainability (NFR19-22)** | Feature-first structure, co-located tests, CI/CD workflows            |

### Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           USER INTERACTION                                   │
│                                  │                                           │
│                                  ↓                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      PRESENTATION (UI)                               │   │
│  │  User taps "Generate Plan" → Loading animation → Display plan       │   │
│  └──────────────────────────────────┬──────────────────────────────────┘   │
│                                     │                                        │
│                          ref.read(generatePlanProvider)                     │
│                                     │                                        │
│  ┌──────────────────────────────────↓──────────────────────────────────┐   │
│  │                     APPLICATION (Providers)                          │   │
│  │                                                                       │   │
│  │   @riverpod                                                          │   │
│  │   Future<WeeklyPlan> generatePlan(ref) async {                       │   │
│  │     1. Get user profile → userProfileProvider                        │   │
│  │     2. Call Gemini → geminiServiceProvider                           │   │
│  │     3. Parse response → WeeklyPlan.fromJson()                        │   │
│  │     4. Save to Firestore → planRepositoryProvider                    │   │
│  │     5. Cache locally → hiveServiceProvider                           │   │
│  │     6. Invalidate currentPlanProvider                                │   │
│  │   }                                                                   │   │
│  │                                                                       │   │
│  └──────────────────────────────────┬──────────────────────────────────┘   │
│                                     │                                        │
│           ┌─────────────────────────┼─────────────────────────┐             │
│           ↓                         ↓                         ↓             │
│  ┌──────────────┐          ┌──────────────┐          ┌──────────────┐      │
│  │   Firestore  │          │  Gemini API  │          │     Hive     │      │
│  │   (Remote)   │  ←sync→  │  (AI)        │          │   (Local)    │      │
│  └──────────────┘          └──────────────┘          └──────────────┘      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Offline Sync Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         OFFLINE SYNC ARCHITECTURE                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     CONNECTIVITY PROVIDER                            │   │
│  │     Monitors network state → Triggers sync when online               │   │
│  └──────────────────────────────────┬──────────────────────────────────┘   │
│                                     │                                        │
│           ┌─────────────────────────┼─────────────────────────┐             │
│           ↓                         ↓                         ↓             │
│  ┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐    │
│  │   ONLINE MODE    │     │   OFFLINE MODE   │     │    SYNC QUEUE    │    │
│  ├──────────────────┤     ├──────────────────┤     ├──────────────────┤    │
│  │ Write: Hive +    │     │ Write: Hive only │     │ Pending writes   │    │
│  │ Firestore        │     │ + queue sync     │     │ with timestamps  │    │
│  │                  │     │                  │     │                  │    │
│  │ Read: Firestore  │     │ Read: Hive       │     │ Retry counter    │    │
│  │ → update Hive    │     │ (cached data)    │     │ per operation    │    │
│  └──────────────────┘     └──────────────────┘     └──────────────────┘    │
│                                                                              │
│  SYNC RESOLUTION:                                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  1. Completions: Last-write-wins (local timestamp)                   │   │
│  │  2. Streaks: Server-authoritative (recalculated on sync)            │   │
│  │  3. Plans: Newer timestamp wins (with merge for modifications)      │   │
│  │  4. Chat: Append-only (no conflicts possible)                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:**

All architectural decisions have been verified for compatibility:

| Technology Pair                       | Compatibility | Notes                                             |
| ------------------------------------- | ------------- | ------------------------------------------------- |
| Flutter 3.16.x + Dart 3.x             | ✅ Compatible  | Standard Flutter SDK pairing                      |
| Riverpod 2.x + Freezed 2.x            | ✅ Compatible  | Commonly used together, excellent code generation |
| Firebase Core + Auth + Firestore      | ✅ Compatible  | Same Firebase SDK version family                  |
| Hive 2.x + Hive Flutter               | ✅ Compatible  | Official Flutter integration                      |
| go_router 13.x + Riverpod             | ✅ Compatible  | Well-documented integration patterns              |
| google_generative_ai 0.2.x + Dart 3.x | ✅ Compatible  | Official Google SDK                               |

**Pattern Consistency:**

| Pattern Category              | Aligned With Stack    | Verification             |
| ----------------------------- | --------------------- | ------------------------ |
| AsyncValue for loading states | ✅ Riverpod native     | Built-in pattern         |
| Freezed for immutable data    | ✅ Dart 3.x + JSON     | Code generation works    |
| Feature-first organization    | ✅ Flutter conventions | Scalable structure       |
| Provider-based DI             | ✅ Riverpod philosophy | Clean dependency graph   |
| Repository pattern            | ✅ Clean architecture  | Standard Flutter pattern |

**Structure Alignment:**

The project structure fully supports all architectural decisions:
- Feature folders map to FR domains
- Layer separation (data/domain/presentation) within features
- Shared services for cross-cutting concerns
- Co-located tests for maintainability

### Requirements Coverage Validation ✅

**Functional Requirements Coverage:**

| FR Domain          | Count         | Architecture Coverage | Implementation Path         |
| ------------------ | ------------- | --------------------- | --------------------------- |
| User Management    | FR1-FR6 (6)   | ✅ 100%                | `features/auth/`            |
| Onboarding         | FR7-FR15 (9)  | ✅ 100%                | `features/onboarding/`      |
| AI Plan Generation | FR16-FR21 (6) | ✅ 100%                | `features/plan_generation/` |
| Dashboard          | FR22-FR30 (9) | ✅ 100%                | `features/dashboard/`       |
| Chat               | FR31-FR36 (6) | ✅ 100%                | `features/chat/`            |
| Progress Tracking  | FR37-FR40 (4) | ✅ 100%                | `features/dashboard/`       |
| Offline            | FR41-FR44 (4) | ✅ 100%                | `shared/services/`          |
| Admin Dashboard    | FR45-FR49 (5) | ✅ 100%                | Separate Flutter Web        |

**Total: 49/49 FRs architecturally supported (100%)**

**Non-Functional Requirements Coverage:**

| NFR Category    | Count    | Coverage | Implementation                                 |
| --------------- | -------- | -------- | ---------------------------------------------- |
| Performance     | NFR1-5   | ✅ 100%   | Hive caching, skeleton loaders, async patterns |
| Security        | NFR6-10  | ✅ 100%   | Firestore rules, .env, route guards, HTTPS     |
| Reliability     | NFR11-14 | ✅ 100%   | Offline sync, retry logic, transactions        |
| Usability       | NFR15-18 | ✅ 100%   | Material 3, WCAG 2.1 AA, responsive design     |
| Maintainability | NFR19-22 | ✅ 100%   | Clean architecture, tests, CI/CD               |

**Total: 22/22 NFRs architecturally supported (100%)**

### Implementation Readiness Validation ✅

**Decision Completeness:**

| Aspect                        | Status      | Details                                         |
| ----------------------------- | ----------- | ----------------------------------------------- |
| Architecture Decision Records | ✅ Complete  | 12 ADRs with context, options, rationale        |
| Technology versions           | ✅ Specified | All packages versioned in pubspec.yaml          |
| Data schemas                  | ✅ Defined   | Firestore structure, Hive boxes, Freezed models |
| API contracts                 | ✅ Defined   | Gemini prompt/response schema, error types      |
| Security implementation       | ✅ Specified | Firestore rules, API key handling               |

**Structure Completeness:**

| Element             | Count | Status        |
| ------------------- | ----- | ------------- |
| Root config files   | 15    | ✅ All defined |
| Feature directories | 6     | ✅ All mapped  |
| Shared components   | 20+   | ✅ All listed  |
| Integration tests   | 4     | ✅ Planned     |
| CI/CD workflows     | 2     | ✅ Configured  |

**Pattern Completeness:**

| Pattern Type           | Patterns Defined | Status     |
| ---------------------- | ---------------- | ---------- |
| Naming conventions     | 6                | ✅ Complete |
| Structure patterns     | 4                | ✅ Complete |
| Format patterns        | 3                | ✅ Complete |
| Communication patterns | 3                | ✅ Complete |
| Process patterns       | 4                | ✅ Complete |

### Gap Analysis Results

**Critical Gaps:** None identified ✅

**Minor Gaps (Documented as Post-MVP):**

| Gap                                    | Priority | Resolution                                               |
| -------------------------------------- | -------- | -------------------------------------------------------- |
| Admin dashboard implementation details | Low      | Separate Flutter Web project; basic analytics for MVP    |
| Push notifications architecture        | Low      | Phase 2 feature; Firebase Cloud Messaging when needed    |
| Premium feature gating                 | Low      | Phase 2; simple flag-based approach sufficient initially |
| Wearable integration                   | Low      | Phase 3; not architecturally blocking                    |

### Architecture Completeness Checklist

**✅ Requirements Analysis**
- [x] Project context thoroughly analyzed
- [x] 49 FRs identified and categorized
- [x] 22 NFRs identified and mapped
- [x] Scale and complexity assessed (Medium)
- [x] Technical constraints identified
- [x] Cross-cutting concerns mapped (6 concerns)

**✅ Technology Stack**
- [x] Framework selected (Flutter)
- [x] State management chosen (Riverpod)
- [x] Database selected (Firestore + Hive)
- [x] AI service chosen (Gemini)
- [x] All dependencies versioned

**✅ Architectural Decisions**
- [x] 12 ADRs documented
- [x] Data architecture defined
- [x] Authentication architecture defined
- [x] AI integration patterns defined
- [x] Offline sync strategy defined
- [x] CI/CD pipeline configured

**✅ Implementation Patterns**
- [x] Naming conventions established (6 categories)
- [x] Structure patterns defined
- [x] Communication patterns specified
- [x] Error handling patterns documented
- [x] Enforcement guidelines listed (10 rules)
- [x] Anti-patterns documented

**✅ Project Structure**
- [x] Complete directory tree defined (150+ files)
- [x] Feature boundaries established
- [x] Layer boundaries defined
- [x] External service boundaries mapped
- [x] Data flow architecture visualized
- [x] Offline sync flow documented

### Architecture Readiness Assessment

**Overall Status:** ✅ READY FOR IMPLEMENTATION

**Confidence Level:** HIGH

Based on:
- 100% functional requirements coverage
- 100% non-functional requirements coverage
- Complete technology stack specification
- Comprehensive implementation patterns
- Detailed project structure

**Key Strengths:**

1. **Production-Ready Patterns** - Clean architecture with Riverpod demonstrates professional Flutter development
2. **Offline-First Design** - Comprehensive sync strategy addresses a critical user need
3. **AI Safety Integration** - Prompt constraints and response validation ensure reliable AI behavior
4. **Portfolio Demonstration Value** - Architecture showcases full-stack mobile + AI capabilities
5. **Scalable Foundation** - Feature-first organization allows easy addition of Phase 2/3 features

**Areas for Future Enhancement:**

1. **Analytics Integration** - Add Firebase Analytics or custom tracking in Phase 2
2. **A/B Testing Infrastructure** - Consider for premium feature rollout
3. **Crash Reporting** - Add Firebase Crashlytics for production monitoring
4. **Performance Monitoring** - Add Firebase Performance for production insights

### Implementation Handoff

**AI Agent Guidelines:**

1. **Follow all ADRs exactly** - Decisions are documented with rationale; don't deviate
2. **Use implementation patterns consistently** - Naming, structure, and communication patterns are mandatory
3. **Respect project structure** - Files go where specified; no ad-hoc organization
4. **Consult this document first** - For any architectural question, this is the authoritative source

**Implementation Priority Order:**

1. **Project Setup** (Day 1)
   ```bash
   flutter create --org com.fitgenie --platforms=ios,android,web fitgenie
   cd fitgenie
   # Add dependencies to pubspec.yaml
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   ```

2. **Core Layer** - `lib/core/` (theme, constants, exceptions, utils)
3. **Shared Services** - `lib/shared/` (Hive, Firebase providers, connectivity)
4. **Auth Feature** - `lib/features/auth/`
5. **Onboarding Feature** - `lib/features/onboarding/`
6. **Plan Generation Feature** - `lib/features/plan_generation/`
7. **Dashboard Feature** - `lib/features/dashboard/`
8. **Chat Feature** - `lib/features/chat/`
9. **Profile Feature** - `lib/features/profile/`
10. **Integration Tests** - `integration_test/`
11. **CI/CD Pipeline** - `.github/workflows/`

---

## Architecture Completion Summary

### Workflow Completion

**Architecture Decision Workflow:** COMPLETED ✅  
**Total Steps Completed:** 8  
**Date Completed:** 2025-12-21  
**Document Location:** `_bmad-output/architecture.md`

### Final Architecture Deliverables

**📋 Complete Architecture Document**

- 12 Architecture Decision Records (ADRs) with context, options, and rationale
- 15+ implementation patterns ensuring AI agent consistency
- Complete project structure with 150+ files and directories mapped
- Full requirements-to-architecture mapping
- Comprehensive validation confirming coherence and completeness

**🏗️ Implementation Ready Foundation**

| Deliverable                         | Count              |
| ----------------------------------- | ------------------ |
| Architectural Decisions             | 12 ADRs            |
| Implementation Patterns             | 15+ categories     |
| Consistency Rules                   | 10 mandatory rules |
| Feature Modules                     | 6 features         |
| Functional Requirements Covered     | 49/49 (100%)       |
| Non-Functional Requirements Covered | 22/22 (100%)       |

**📚 AI Agent Implementation Guide**

This document provides AI agents with:
- Exact technology versions to use
- Naming conventions to follow
- File organization patterns
- Error handling approaches
- State management patterns
- Testing co-location rules

### Quality Assurance Checklist

**✅ Architecture Coherence**
- [x] All technology choices are compatible (Flutter + Riverpod + Firebase + Hive + Gemini)
- [x] Patterns support the architectural decisions
- [x] Structure aligns with all choices
- [x] No contradictory decisions

**✅ Requirements Coverage**
- [x] All 49 functional requirements are supported
- [x] All 22 non-functional requirements are addressed
- [x] 6 cross-cutting concerns are handled
- [x] All integration points are defined

**✅ Implementation Readiness**
- [x] Decisions are specific and actionable
- [x] Patterns prevent agent conflicts
- [x] Structure is complete and unambiguous
- [x] Code examples are provided for clarity

### Project Success Factors

**🎯 Clear Decision Framework**  
Every technology choice was made with clear rationale, ensuring all stakeholders understand the architectural direction.

**🔧 Consistency Guarantee**  
Implementation patterns and rules ensure that multiple AI agents will produce compatible, consistent code that works together seamlessly.

**📋 Complete Coverage**  
All project requirements are architecturally supported, with clear mapping from business needs to technical implementation.

**🏗️ Solid Foundation**  
The Flutter + Riverpod + Firebase architecture provides a production-ready foundation following current best practices.

**🎨 Portfolio Excellence**  
The architecture demonstrates full-stack mobile development with AI integration, state management, offline-first design, and clean architecture patterns—ideal for impressing Fiverr clients.

---

## Appendix: Quick Reference

### Technology Stack Summary

| Layer            | Technology      | Version |
| ---------------- | --------------- | ------- |
| Framework        | Flutter         | 3.16.x  |
| Language         | Dart            | 3.x     |
| State Management | Riverpod        | 2.4.x   |
| Remote Database  | Cloud Firestore | 4.14.x  |
| Local Storage    | Hive            | 2.2.x   |
| Authentication   | Firebase Auth   | 4.16.x  |
| AI Service       | Google Gemini   | 0.2.x   |
| Routing          | go_router       | 13.0.x  |
| Data Classes     | Freezed         | 2.4.x   |
| Animations       | flutter_animate | 4.3.x   |

### Key Commands

```bash
# Project initialization
flutter create --org com.fitgenie --platforms=ios,android,web fitgenie
cd fitgenie
flutterfire configure

# Development
flutter pub get
dart run build_runner watch --delete-conflicting-outputs
flutter run

# Testing
flutter test
flutter test --coverage
flutter test integration_test/

# Build
flutter build apk --release
flutter build ios --release
flutter build web
```

### ADR Index

| ADR     | Title                              | Domain                |
| ------- | ---------------------------------- | --------------------- |
| ADR-001 | Firestore Data Model               | Data Architecture     |
| ADR-002 | Offline-First Data Strategy        | Data Architecture     |
| ADR-003 | Firebase Authentication Flow       | Auth & Security       |
| ADR-004 | API Key Security                   | Auth & Security       |
| ADR-005 | Firestore Security Rules           | Auth & Security       |
| ADR-006 | Gemini API Integration Pattern     | AI Integration        |
| ADR-007 | AI Error Handling & Retry Strategy | AI Integration        |
| ADR-008 | Clean Architecture Layers          | Frontend Architecture |
| ADR-009 | State Management Pattern           | Frontend Architecture |
| ADR-010 | Navigation Architecture            | Frontend Architecture |
| ADR-011 | CI/CD Pipeline                     | Infrastructure        |
| ADR-012 | Environment Configuration          | Infrastructure        |

---

**Architecture Status:** ✅ READY FOR IMPLEMENTATION

**Next Phase:** Begin implementation using the architectural decisions and patterns documented herein.

**Document Maintenance:** Update this architecture when major technical decisions are made during implementation.

---

*This Architecture Decision Document was created using the BMAD Architecture Workflow and serves as the authoritative source for all technical decisions on the FitGenie project.*