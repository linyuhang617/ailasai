# ailasai 📚
### Intelligent Vocabulary Learning — Spaced Repetition for Serious Learners

> A Flutter app for vocabulary acquisition using SM-2 and FSRS spaced repetition algorithms, with teacher/classroom management, morpheme breakdown, and real-time memory analytics.

---

## Screenshots

<!-- 截圖放這裡 -->
*Coming soon*

---

## Features

### 🃏 Smart Flashcard Review
- Flip-card animation with smooth 3D transitions
- Four-rating system (Again / Hard / Good / Easy) with next-interval preview
- **SM-2** and **FSRS** algorithm support — switchable in settings
- Practice mode (in-memory, no DB write) for extra drilling
- New card daily limit to prevent overload

### 🧠 Memory Science
- FSRS retrievability formula: `R = e^(-t/S)` calculated in real time
- Stability distribution chart (1–3 / 4–7 / 8–14 / 15–30 / 30+ days)
- Per-card stability and retrievability displayed on card back
- 30-day correctness trend chart

### 🔤 Morpheme Breakdown
- Prefix / root / suffix colour-coded on card back
- Tap any segment to see the word family (words sharing the same morpheme)
- Managed via CMS (Directus + Supabase)

### 📚 Word Library
- Browse and join curated word lists (IELTS, TEF, etc.)
- Per-library progress tracking
- Offline building search with online fallback

### 🏠 Home Dashboard
- Daily due count, today completed, new words, streak
- Active library progress bars
- One-tap start review

### 👨‍🏫 Teacher & Classroom (Role-Based)
- Teacher/student role selection at registration
- Create classrooms with secure invite codes + QR scanner
- Assign word lists to entire class with due dates
- View per-student progress (total reviews, correct rate, avg stability)

### 🎓 Student Side
- Join classroom via invite code or QR scan
- View assigned word lists with progress bars and due-date indicators
- My Classrooms section on home screen

### ⚙️ Settings
- Daily reminder push notifications with custom time picker
- 5 theme colours (Purple / Coral / Teal / Amber / Blue)
- Accessibility-aware — themes applied globally with no flash on startup

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (iOS / Android / Web / macOS) |
| State Management | Riverpod (`AsyncNotifierProvider`, `FutureProvider`) |
| Navigation | go_router (ShellRoute + deep links) |
| Local DB | Isar 3.1.0 |
| Backend | Supabase (PostgreSQL + Auth + RLS) |
| ORM / Query | Supabase Dart client (typed queries + RPC) |
| SRS Algorithm | SM-2 (custom) + FSRS (`fsrs` package) |
| Charts | fl_chart |
| Notifications | flutter_local_notifications + timezone |
| QR | qr_flutter + mobile_scanner 7.x (Apple Vision API) |
| Theme Persistence | SharedPreferences |

---

## Architecture

```
lib/
├── core/
│   ├── models/          # Word, CardState, WordList, Classroom, Assignment...
│   ├── services/        # WordService, SyncService, FsrsService, AlgorithmService...
│   ├── router/          # app_router.dart (go_router + ShellRoute)
│   └── theme/           # app_themes.dart, theme_provider.dart
└── features/
    ├── auth/            # Login, Register (role selection)
    ├── home/            # Dashboard, streak, stats
    ├── review/          # WordCard, ReviewSession, PracticeSession
    ├── library/         # WordListCard, WordListDetailScreen, MemoryStatsSection
    ├── settings/        # ThemePicker, NotificationSettings, AlgorithmToggle
    ├── teacher/         # TeacherHome, ClassroomScreen, StudentProgressScreen
    └── student/         # JoinClassroom, QrScanner
```

**Data flow:**
- CardState lives in **Isar** (fast, offline-first)
- After every review, `pushSingleCardState` upserts to **Supabase** asynchronously
- On login, `SyncService` merges local ↔ server (newer `lastReviewedAt` wins)

---

## Database Schema

| Table | Description |
|-------|-------------|
| `word_lists` | Curated vocabulary sets |
| `words` | Individual vocabulary entries |
| `card_states` | Per-user SRS state (SM-2 + FSRS fields) |
| `user_word_lists` | User ↔ word list join |
| `user_settings` | Theme, algorithm preference |
| `morphemes` | Prefix / root / suffix definitions |
| `word_morphemes` | Word ↔ morpheme join (with position) |
| `classrooms` | Teacher-owned classrooms with invite codes |
| `classroom_members` | Student ↔ classroom join |
| `assignments` | Word list assigned to classroom with due date |
| `assignment_progress` | Per-student word completion tracking |

All cross-table queries use **SECURITY DEFINER RPCs** — RLS policies never query other tables to avoid infinite recursion.

---

## Quick Start

```bash
# Clone
git clone https://github.com/linyuhang617/ailasai.git
cd ailasai

# Install dependencies
flutter pub get

# Set up environment
cp lib/core/env.dart.example lib/core/env.dart
# Fill in your Supabase URL and anon key

# Run migrations
# Apply supabase/migrations/*.sql in order via Supabase Dashboard

# Run
flutter run
```

---

## My Contributions

Built end-to-end across 14 development slices:

- **SRS engine** — SM-2 from scratch + FSRS integration with CardState ↔ fsrs.Card conversion layer
- **Offline-first architecture** — Isar local DB with async Supabase sync on every review
- **FSRS memory analytics** — retrievability formula, stability distribution, 30-day trend chart
- **Morpheme breakdown** — colour-coded prefix/root/suffix with family word lookup via Bottom Sheet
- **Teacher/student RBAC** — role at registration, ShellRoute branching, SECURITY DEFINER RPCs for all cross-table queries
- **Classroom & assignment system** — invite codes, QR scanner (mobile_scanner 7.x), per-student progress RPC
- **Theme system** — 5 colour schemes, SharedPreferences pre-load to eliminate startup flash
- **Push notifications** — daily reminder with zonedSchedule, deep link on tap, iOS + Android platform config
- **Full deployment** — Supabase project setup, 10 migrations, RLS policies

---

## Version History

| Slice | Feature |
|-------|---------|
| 1 | Flashcard flip animation, Supabase word fetch |
| 2 | SM-2 algorithm, Isar local storage, review session |
| 3 | Practice mode (in-memory, no DB write) |
| 4 | Auth (JWT), multi-device sync on login |
| 5 | Word library browse & join, ShellRoute nav |
| 6 | Home dashboard — streak, stats, due words |
| 7 | Push notifications — daily reminder, deep link |
| 8 | Theme picker — 5 colours, startup flash fix |
| 9 | Morpheme breakdown — prefix/root/suffix + word family |
| 10 | FSRS algorithm — switchable in settings |
| 11 | Memory stats dashboard — fl_chart, retrievability |
| 12 | Teacher classrooms — invite code, QR, member list |
| 13 | Student progress — per-student stats, student home |
| **14** | **Assignments — assign word list, track per-word completion** |