# 🏏 CricManager — Frontend Client

A high-performance, responsive Flutter Web, Mobile, and Desktop application for **CricManager** (*Moneyball for the Indian Premier League*).

[![Flutter](https://img.shields.io/badge/Flutter-3.x_Web-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Firebase Hosting](https://img.shields.io/badge/Firebase-Hosting-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)

---

## 🎨 UI/UX & Design Philosophy

The client is built using a modern **Cyberpunk / Sports Stadium** aesthetic:
* **Color Palette**: Pitch Black background (`#000000`), Dark Surface Card (`#0D0D0D`, `#111111`), with high-contrast **Neon Pink** primary accents (`#FF2D78`).
* **Role Color Coding**: Emerald for Batters (`#34D399`), Electric Blue for Bowlers (`#60A5FA`), Violet for All-Rounders (`#A78BFA`), and Amber Gold for Wicketkeepers (`#FBBF24`).
* **Typography**: Clean, modern pairing with Google Fonts — **Outfit** for energetic headings and **Inter** for dense statistical data tables.
* **Glassmorphism & Micro-animations**: Glass panels, glowing borders, smooth hover interactions, and animated counter tickers.

---

## 📱 Core Screens & User Experience

1. **Landing & Hero Screen (`landing_screen.dart`)**:
   * Interactive overview of the Moneyball concept with animated draft console preview, interactive rule checklist, and quick CTA to enter the arena.
2. **Authentication Modal (`login_screen.dart`)**:
   * Clean, responsive dialog supporting both JWT login and new manager registration with persistent token storage via `shared_preferences`.
3. **Dashboard & Main Menu (`main_menu_screen.dart`)**:
   * Career statistics overview (campaigns, win ratios, championships), historic IPL season selector (2008–2026), and global manager leaderboard.
4. **Draft Room & Auction Console (`draft_room_screen.dart`)**:
   * Real-time ₹100 Cr purse tracker.
   * Multi-criteria filtering (Role, Indian vs Overseas, Budget tiers, Player ratings).
   * Live squad constraint validation checklist (12-man roster, $\ge 1$ WK, $\ge 4$ Bowlers/ARs, $\ge 1$ Spin Bowler, $\le 5$ Overseas).
5. **Starting XI & Tactical Lineup (`lineup_screen.dart`)**:
   * Designate Starting XI and substitute assets.
   * Enforces the official IPL 4-overseas player restriction in the playing eleven.
   * Calculates dynamic team batting, bowling, and clutch ratings in real time.
6. **Simulation Arena (`simulation_screen.dart`)**:
   * Fixture-by-fixture match simulations with animated scoreboards and results.
   * Dynamic live-updating Points Table (Matches, Wins, Losses, Points).
   * Complete IPL Playoff Bracket progression (Qualifier 1, Eliminator, Qualifier 2, Grand Final).
7. **Season Complete Ceremony (`season_completed_screen.dart`)**:
   * Celebratory championship screen, final standings recap, and career stat synchronization.

---

## 🏗️ State Architecture

Managed via `provider` (`GameProvider`):
* Reactive state changes notify UI without unnecessary redraws.
* Centralized API interaction with error handling, authentication headers, and automatic environment URL switching (Web vs Android Emulator vs Localhost).
* Zero client calculation: all match results and playoff brackets are computed on the backend server for complete simulation integrity.

---

## 🚀 Running Locally

```bash
# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Build production web bundle
flutter build web --release
```

---

## 📦 Docker & Production Deployment

The frontend includes a multi-stage `Dockerfile` and `nginx.conf`:
* Stage 1: Compiles Flutter web using the official SDK.
* Stage 2: Packages static assets into an ultra-lightweight `nginx:alpine` image with gzip compression and SPA fallback routing.

```bash
docker build -t cricmanager-frontend .
docker run -p 3000:80 cricmanager-frontend
```
