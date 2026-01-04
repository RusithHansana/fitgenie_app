# Product Requirements Document - FitGenie

**Author:** RusithHansana
**Date:** 2025-12-21  
**Version:** 1.0  
**Status:** Complete

---

## Executive Summary

### Product Vision

**FitGenie** is a cross-platform mobile application (iOS/Android) that revolutionizes personal fitness by combining Generative AI with personalized health guidance. Unlike static fitness apps that offer pre-built workout templates, FitGenie acts as an **automated personal trainer and nutritionist**, creating fully customized 7-day workout plans and meal schedules tailored to each user's unique biometrics, available equipment, and dietary restrictions.

### Problem Statement

Millions of people want to improve their fitness but face significant barriers:
- **Cost barrier**: Personal trainers cost $50-100+ per session, putting quality guidance out of reach for most people
- **One-size-fits-all solutions**: Generic fitness apps don't account for individual equipment, dietary needs, or physical limitations
- **Lack of personalization**: Users with home gym setups, dietary restrictions, or specific goals can't find plans that truly fit their situation
- **Inconsistent guidance**: Switching between workout apps and nutrition apps creates fragmented, uncoordinated fitness plans

### Solution

FitGenie solves these problems by leveraging **Google Gemini AI** to generate comprehensive, personalized fitness and nutrition plans in under 30 seconds. Users receive:
- Custom workout routines adapted to their equipment (gym, home, or bodyweight only)
- Personalized meal plans respecting dietary restrictions and preferences
- AI-powered chat for real-time plan modifications ("swap Tuesday's lunch for something vegan")
- Progress tracking with streak-based motivation

### Product Differentiator

**What makes FitGenie unique:**
1. **True AI Personalization**: Not just filtering templates—generating genuinely custom plans using generative AI
2. **Unified Experience**: Single app for both workouts AND nutrition, coordinated by AI
3. **Conversational Modifications**: Natural language chat to adjust plans on-the-fly
4. **Offline-First Design**: Full plan access without internet connectivity
5. **Portfolio Showcase Value**: Demonstrates full-stack AI implementation (Flutter + Firebase + Gemini API)

### Target Users

| User Type          | Description                                        | Primary Need                      |
| ------------------ | -------------------------------------------------- | --------------------------------- |
| **Primary User**   | Fitness-seekers who can't afford personal trainers | Affordable, personalized guidance |
| **Secondary User** | Busy professionals needing efficient workout plans | Time-optimized routines           |
| **Tertiary User**  | Home gym enthusiasts                               | Equipment-specific workouts       |
| **Admin User**     | App administrator                                  | User analytics and monitoring     |

### Business Context

This project serves as a **portfolio demonstration** for Fiverr freelance clients, showcasing:
- Full-stack mobile development capabilities (Flutter)
- Cloud backend architecture (Firebase)
- AI/ML integration (Google Gemini)
- Freemium monetization model implementation
- Professional app architecture and state management

---

## Success Criteria

### User Success

| Metric                       | Target                                                | Measurement Method            |
| ---------------------------- | ----------------------------------------------------- | ----------------------------- |
| Plan generation satisfaction | Users receive plan in <30 seconds                     | In-app timing metrics         |
| Task completion rate         | 70%+ of daily tasks marked complete                   | Firebase analytics            |
| Streak maintenance           | Average streak >5 days for active users               | Database queries              |
| Plan modification success    | AI successfully handles 90%+ of modification requests | Chat interaction logs         |
| Offline usability            | 100% of cached plans accessible offline               | Hive local storage validation |

### Business Success

| Metric                        | Target                                                  | Measurement Method       |
| ----------------------------- | ------------------------------------------------------- | ------------------------ |
| Portfolio demonstration value | Clearly showcases Standard-to-Premium tier capabilities | Client feedback          |
| Code quality                  | Well-structured, documented codebase                    | GitHub repository review |
| Feature completeness          | All 6 core FRs implemented                              | Feature checklist        |
| Demo readiness                | 20-second video demo + screenshots available            | Marketing assets         |

### Technical Success

| Metric                     | Target                                    | Measurement Method       |
| -------------------------- | ----------------------------------------- | ------------------------ |
| AI response latency        | <5 seconds for plan generation            | API response timing      |
| Data persistence           | 100% successful Firestore operations      | Error logging            |
| Offline availability       | Previously loaded plans work 100% offline | Manual testing           |
| Cross-platform consistency | Identical UX on iOS and Android           | Device testing matrix    |
| Build stability            | APK builds successfully on CI/CD          | GitHub Actions/Codemagic |

### Measurable Outcomes

**3-Month Portfolio Success Indicators:**
- GitHub repository with 50+ stars
- At least 3 Fiverr client inquiries referencing the project
- Functional demo deployed and accessible
- Positive feedback from code reviewers

---

## Product Scope

### MVP - Minimum Viable Product (Phase 1)

**Core Capabilities Required for Launch:**

1. **User Authentication**
   - Email/password authentication via Firebase Auth
   - Persistent login sessions

2. **Onboarding Wizard**
   - Multi-step form collecting: age, weight, height, fitness goal, equipment, dietary restrictions
   - Data validation and storage

3. **AI Plan Generation**
   - Integration with Google Gemini API
   - Structured JSON response parsing
   - 7-day workout and meal plan generation

4. **Dashboard Experience**
   - "Today's Plan" view with breakfast, workout, lunch, dinner
   - Exercise list with details
   - Task completion tracking

5. **Basic Chat Interface**
   - Send modification requests to AI
   - Receive and apply plan updates

6. **Offline Support**
   - Cache generated plans locally with Hive
   - Access cached plans without connectivity

### Post-MVP Features (Phase 2 - Growth)

- **Admin Dashboard**: Flutter Web panel for user analytics
- **Push Notifications**: Daily reminders and streak alerts
- **Progress Photos**: Before/after image storage
- **Workout Timer**: Built-in rest timer for exercises
- **Social Sharing**: Share achievements and streaks
- **Multiple Plan Storage**: Save and switch between different plans

### Future Vision (Phase 3 - Expansion)

- **Wearable Integration**: Apple Watch, Fitbit sync
- **Video Exercise Guides**: Embedded tutorial videos
- **Community Features**: Public challenges, leaderboards
- **Premium Subscription**: Advanced AI features, priority support
- **Trainer Marketplace**: Connect with human trainers for hybrid coaching

### Out of Scope (Explicitly Excluded)

- Real-time video coaching
- Calorie counting with barcode scanning
- Integration with grocery delivery services
- Medical advice or health condition management
- Multi-language support (English only for MVP)

---

## User Journeys

### Journey 1: Alex Chen - From Couch to Confident

**Background:** Alex is a 28-year-old software developer who's been meaning to get in shape for years. He has a basic home gym setup (dumbbells, pull-up bar, yoga mat) but every fitness app he's tried assumes he has access to a full gym. He's vegetarian and works long hours, so meal prep needs to be simple.

**Discovery:** While scrolling through Reddit's r/fitness community, Alex sees someone mention FitGenie as "the app that actually understands home workouts." Curious, he downloads it.

**Onboarding Experience:** The app greets him with a friendly wizard. Alex enters his stats (5'10", 175 lbs, goal: build muscle) and feels genuinely excited when he reaches the equipment page—finally, an app asking what he *actually* has! He selects "Home Gym" and checks off his specific equipment. When the dietary restrictions page appears, he selects "Vegetarian" and notes he's allergic to tree nuts.

**The Magic Moment:** Alex taps "Generate My Plan" and watches a clean loading animation for about 4 seconds. Then it happens—a complete 7-day plan appears, and every single workout uses only his equipment. The meal plan is entirely vegetarian with no nuts anywhere. For the first time, a fitness app *gets him*.

**Daily Usage:** Each morning, Alex opens FitGenie to see his "Today's Plan." He completes his morning workout, tapping each exercise as he finishes. The app tracks his 12-day streak, and he feels motivated to keep it going. On Thursday, he tweaks his plan via chat: "My shoulder is sore, modify upper body workouts for this week." The AI regenerates relevant days, and his streak remains intact.

**Outcome:** Three months later, Alex has visible muscle definition and has recommended FitGenie to four coworkers. He finally feels like he has a personal trainer—one that works around his schedule and limitations.

---

### Journey 2: Maria Santos - The Busy Professional

**Background:** Maria is a 34-year-old marketing manager and mother of two. She has a gym membership but can only use it twice a week. The rest of her workouts need to happen at home during her 6 AM window before the kids wake up. She's trying to lose 20 pounds and needs quick, efficient routines.

**Discovery:** Maria's colleague mentions FitGenie during a team lunch, explaining how the AI creates custom plans. That evening, she downloads the app.

**Onboarding Experience:** Maria appreciates the straightforward setup. She selects "Weight Loss" as her goal and indicates "Mixed" for equipment—full gym twice weekly, bodyweight only other days. For dietary preferences, she selects "Low Carb" and notes she's lactose intolerant.

**The Magic Moment:** The generated plan impresses her immediately. Monday and Thursday show gym workouts with machines and weights, while Tuesday, Wednesday, and Friday feature 20-minute HIIT sessions she can do in her living room. The meal plan includes quick-prep breakfast options and meal-prep-friendly lunches.

**Daily Usage:** Maria's morning routine becomes streamlined. She opens the app at 5:50 AM, sees exactly what she needs to do, and gets it done efficiently. On weeks when she can only hit the gym once, she uses the chat: "I can only go to the gym on Thursday this week." The AI redistributes her workouts without missing a beat.

**Outcome:** After two months, Maria has lost 12 pounds and feels more energetic than she has in years. She starts a fitness group chat with friends, all now using FitGenie.

---

### Journey 3: Admin Dashboard - Operations Visibility

**Background:** As the app owner/administrator, Rusit needs visibility into user adoption and engagement to demonstrate the app's value to potential clients.

**Admin Experience:** Rusit opens the Flutter Web admin dashboard (`admin.fitgenie.app`). The dashboard displays:
- Total registered users: 1,247
- Active plans (generated in last 7 days): 892
- Average streak length: 6.3 days
- Most popular fitness goal: Weight Loss (42%)
- Most common equipment: Home Gym (38%)

**Value Demonstration:** When showcasing the portfolio to a potential Fiverr client, Rusit shares a screenshot of the dashboard showing real user data, demonstrating the app's full-stack capabilities and production readiness.

---

### Journey 4: Recovery Path - When Things Go Wrong

**Background:** A user experiences an error during plan generation due to API rate limiting.

**Error Experience:** The loading animation plays for 10 seconds, then displays a friendly message: "Our AI is taking a short break! We'll retry in a moment..." The app automatically retries with exponential backoff. On the third attempt, the plan generates successfully.

**Offline Recovery:** A user opens the app while on a subway with no signal. The app immediately loads their cached plan from Hive, with a subtle banner indicating "Offline Mode - showing your saved plan." All features except chat and plan regeneration work normally.

---

## Domain-Specific Requirements

### Health & Fitness Domain Considerations

**Safety-First AI Prompt Design:**
The AI system prompt must include explicit safety constraints:
- Never suggest exercises requiring equipment the user doesn't have
- Avoid high-risk exercises for beginners (e.g., heavy deadlifts without spotter)
- Respect injury indications (shoulder issues → no overhead pressing)
- Include proper warm-up and cool-down recommendations
- Provide exercise modifications for common limitations

**Nutrition Responsibility:**
- Clearly state the app provides general guidance, not medical advice
- Respect all dietary restrictions without exception
- Ensure nutritionally balanced meal suggestions
- Include hydration reminders in daily plans

**Data Sensitivity:**
- User biometric data (weight, height, age) is personal health information
- Must be stored securely with proper Firebase security rules
- Never share individual user data in analytics or admin views
- Allow users to delete their data completely

### AI Prompt Engineering Requirements

**Structured Output Enforcement:**
The Gemini API must return consistent JSON that the Flutter app can parse reliably:

```json
{
  "weeklyPlan": {
    "monday": {
      "workout": {
        "name": "Upper Body Strength",
        "duration": "45 mins",
        "exercises": [...]
      },
      "meals": {
        "breakfast": {...},
        "lunch": {...},
        "dinner": {...}
      }
    }
    // ... remaining days
  }
}
```

**Prompt Safety Constraints:**
- System prompt must enforce equipment limitations
- Must prevent exercise suggestions beyond user's capability level
- Must respect all dietary restrictions absolutely
- Include fallback instructions if uncertain

---

## Mobile App Specific Requirements

### Platform Requirements

| Requirement             | Specification                          |
| ----------------------- | -------------------------------------- |
| **Platforms**           | iOS 12.0+, Android API 21+ (Lollipop+) |
| **Framework**           | Flutter (Stable channel)               |
| **State Management**    | Riverpod or Bloc                       |
| **Minimum Screen Size** | iPhone SE (375pt width)                |
| **Maximum Screen Size** | Large tablets (responsive design)      |

### Device Feature Usage

| Feature            | Purpose                   | Permission Required |
| ------------------ | ------------------------- | ------------------- |
| Internet           | API calls, sync           | Yes (implicit)      |
| Local Storage      | Offline caching           | No                  |
| Push Notifications | Daily reminders (Phase 2) | Yes                 |
| Camera             | Progress photos (Phase 2) | Yes                 |

### Mobile UX Considerations

- **Touch Targets**: Minimum 44pt for all interactive elements
- **Loading States**: Skeleton screens during data fetch
- **Gesture Support**: Swipe to navigate between days
- **Haptic Feedback**: Subtle vibration on task completion
- **Dark Mode**: Support system appearance preference

---

## Technical Architecture Considerations

### Technology Stack

| Layer                | Technology            | Justification                                             |
| -------------------- | --------------------- | --------------------------------------------------------- |
| **Frontend**         | Flutter (Dart)        | Cross-platform, single codebase, portfolio-friendly       |
| **State Management** | Riverpod              | Modern, testable, recommended for new Flutter projects    |
| **Backend**          | Firebase (Serverless) | Rapid development, generous free tier, proven scalability |
| **Authentication**   | Firebase Auth         | Secure, easy integration, multiple providers              |
| **Database**         | Cloud Firestore       | Real-time sync, offline support, document model           |
| **AI Service**       | Google Gemini API     | Free tier available, excellent prompt engineering support |
| **Local Storage**    | Hive                  | Fast, lightweight, type-safe local persistence            |
| **Admin Panel**      | Flutter Web           | Code sharing with mobile app                              |

### Data Model Approach

**User Document:**
```
/users/{userId}
  - email
  - createdAt
  - onboarding: { age, weight, height, goal, equipment, dietaryRestrictions }
  - currentStreak
  - longestStreak
```

**Plan Document:**
```
/users/{userId}/plans/{planId}
  - generatedAt
  - weeklyPlan: { monday: {...}, tuesday: {...}, ... }
  - completedTasks: { "monday-workout": true, ... }
```

### Environment & Security

- Store API keys in `.env` using `flutter_dotenv`
- Never commit secrets to GitHub
- Implement Firestore security rules restricting access to `request.auth.uid`
- Use Firebase App Check for additional API protection (Phase 2)

---

## Functional Requirements

### User Management

- **FR1**: Users can create an account using email and password
- **FR2**: Users can log in to an existing account
- **FR3**: Users can log out from their account
- **FR4**: Users can reset their password via email
- **FR5**: Users can view and edit their profile information
- **FR6**: Users can delete their account and all associated data

### Onboarding & Profile

- **FR7**: Users can enter their age during onboarding
- **FR8**: Users can enter their weight (with unit selection: kg/lbs) during onboarding
- **FR9**: Users can enter their height (with unit selection: cm/ft-in) during onboarding
- **FR10**: Users can select their fitness goal (Muscle Gain, Weight Loss, General Fitness, Endurance)
- **FR11**: Users can select their available equipment (Full Gym, Home Gym, Bodyweight Only, Mixed)
- **FR12**: Users can specify equipment details when selecting Home Gym or Mixed
- **FR13**: Users can select dietary restrictions (Vegetarian, Vegan, Gluten-Free, Lactose-Free, Halal, Kosher, None)
- **FR14**: Users can add custom dietary notes (allergies, preferences)
- **FR15**: Users can update their onboarding information at any time

### AI Plan Generation

- **FR16**: Users can request generation of a new 7-day fitness and nutrition plan
- **FR17**: System sends user context to Gemini API and receives structured JSON plan
- **FR18**: System parses AI response and stores plan in Firestore
- **FR19**: System displays loading animation during plan generation
- **FR20**: System handles API errors gracefully with retry logic
- **FR21**: System caches generated plan locally for offline access

### Dashboard & Plan Display

- **FR22**: Users can view "Today's Plan" showing all scheduled activities
- **FR23**: Users can view breakfast details including ingredients and preparation
- **FR24**: Users can view lunch details including ingredients and preparation
- **FR25**: Users can view dinner details including ingredients and preparation
- **FR26**: Users can view workout details including exercise list
- **FR27**: Users can see exercise details (name, sets, reps, rest time, instructions)
- **FR28**: Users can navigate between days of the week to view different plans
- **FR29**: Users can mark individual tasks (meals, workouts) as complete
- **FR30**: Users can see their current streak count

### Chat & Modifications

- **FR31**: Users can access a chat interface to communicate with the AI
- **FR32**: Users can send natural language requests to modify their plan
- **FR33**: System sends modification request to Gemini API with current plan context
- **FR34**: System receives modified plan and updates Firestore
- **FR35**: System updates local cache with modified plan
- **FR36**: Users can see chat history for the current session

### Progress Tracking

- **FR37**: Users can view their streak history
- **FR38**: System automatically updates streak count based on daily task completion
- **FR39**: Users can see completion percentage for each day
- **FR40**: Users can see weekly completion summary

### Offline Functionality

- **FR41**: Users can view cached plans when offline
- **FR42**: System displays offline indicator when not connected
- **FR43**: System syncs completed tasks when connection is restored
- **FR44**: System queues modification requests when offline (sync when online)

### Admin Dashboard (Web)

- **FR45**: Admins can log in to the web admin dashboard
- **FR46**: Admins can view total registered user count
- **FR47**: Admins can view count of active plans (generated in last 7 days)
- **FR48**: Admins can view aggregate statistics (popular goals, equipment, dietary choices)
- **FR49**: Admin dashboard respects user privacy (no individual user details visible)

---

## Non-Functional Requirements

### Performance

| Requirement                        | Specification                    |
| ---------------------------------- | -------------------------------- |
| **NFR1**: App cold start time      | < 3 seconds on mid-range devices |
| **NFR2**: AI plan generation       | < 5 seconds API response time    |
| **NFR3**: Screen transitions       | < 300ms animation completion     |
| **NFR4**: Cached plan loading      | < 500ms from local storage       |
| **NFR5**: Task completion feedback | < 100ms haptic/visual response   |

### Security

| Requirement                   | Specification                                                  |
| ----------------------------- | -------------------------------------------------------------- |
| **NFR6**: Authentication      | Firebase Auth with secure token management                     |
| **NFR7**: Data access         | Firestore rules restrict read/write to `request.auth.uid` only |
| **NFR8**: API key protection  | Keys stored in `.env`, never committed to repository           |
| **NFR9**: Data encryption     | All data encrypted in transit (HTTPS/TLS)                      |
| **NFR10**: Session management | Automatic token refresh, secure logout                         |

### Reliability

| Requirement                     | Specification                                   |
| ------------------------------- | ----------------------------------------------- |
| **NFR11**: Offline availability | 100% of cached plans accessible without network |
| **NFR12**: API failure handling | Exponential backoff with 3 retry attempts       |
| **NFR13**: Data consistency     | Firestore transactions for streak updates       |
| **NFR14**: Error logging        | Comprehensive error capture for debugging       |

### Usability

| Requirement                  | Specification                                    |
| ---------------------------- | ------------------------------------------------ |
| **NFR15**: Accessibility     | WCAG 2.1 AA compliance (contrast, touch targets) |
| **NFR16**: Responsive design | Support screens from 375pt to 1024pt width       |
| **NFR17**: Loading feedback  | Skeleton screens and progress indicators         |
| **NFR18**: Error messages    | User-friendly, actionable error descriptions     |

### Maintainability

| Requirement               | Specification                                            |
| ------------------------- | -------------------------------------------------------- |
| **NFR19**: Code structure | Clean architecture with separation of concerns           |
| **NFR20**: Testing        | Unit tests for JSON parsing and business logic           |
| **NFR21**: Documentation  | README with setup instructions and architecture overview |
| **NFR22**: CI/CD          | Automated APK builds via GitHub Actions or Codemagic     |

---

## Risks & Mitigations

### Technical Risks

| Risk                                   | Probability | Impact | Mitigation Strategy                                                                |
| -------------------------------------- | ----------- | ------ | ---------------------------------------------------------------------------------- |
| AI hallucination (dangerous exercises) | Medium      | High   | Strict system prompt with safety constraints; equipment/capability limits enforced |
| Gemini API rate limits                 | Medium      | Medium | Implement exponential backoff; cache aggressively; consider response caching       |
| Inconsistent JSON from AI              | Medium      | High   | Robust parsing with fallbacks; schema validation; retry with refined prompt        |
| Firebase free tier limits              | Low         | Medium | Monitor usage; optimize queries; plan upgrade path                                 |

### Product Risks

| Risk                        | Probability | Impact | Mitigation Strategy                                                               |
| --------------------------- | ----------- | ------ | --------------------------------------------------------------------------------- |
| Users expect medical advice | Medium      | High   | Clear disclaimers; avoid medical terminology; recommend professional consultation |
| Low user engagement         | Medium      | Medium | Streak gamification; push notifications (Phase 2); compelling UX                  |
| Feature scope creep         | High        | Medium | Strict MVP definition; phased rollout; prioritize portfolio value                 |

### Business Risks

| Risk                            | Probability | Impact | Mitigation Strategy                                               |
| ------------------------------- | ----------- | ------ | ----------------------------------------------------------------- |
| Portfolio not impressive enough | Low         | High   | Include video demo; professional screenshots; detailed README     |
| Similar apps in market          | Medium      | Low    | Emphasize AI differentiation; showcase code quality over features |

---

## Appendix

### Glossary

| Term           | Definition                                                 |
| -------------- | ---------------------------------------------------------- |
| **Gemini API** | Google's generative AI API for natural language processing |
| **Firestore**  | Firebase's NoSQL document database                         |
| **Hive**       | Lightweight, fast local storage for Flutter                |
| **Riverpod**   | Modern state management solution for Flutter               |
| **Streak**     | Consecutive days of completing daily tasks                 |
| **MVP**        | Minimum Viable Product - smallest feature set for launch   |

### References

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Google Gemini API](https://ai.google.dev/)
- [Material Design 3](https://m3.material.io/)

### Document History

| Version | Date       | Author | Changes              |
| ------- | ---------- | ------ | -------------------- |
| 1.0     | 2025-12-21 | Rusit  | Initial PRD creation |

---

*This PRD serves as the foundation for all subsequent design, architecture, and development work on FitGenie.*
