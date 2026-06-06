# TaskDigest Mobile App

TaskDigest is a premium productivity mobile application built with Flutter. It syncs with the TaskDigest Laravel backend to provide smart, AI-driven task scheduling, real-time push notifications, custom reminders, and recurrence settings.

## Features

- **Sleek UI/UX**: Dark mode aesthetic, glassmorphism cards, interactive priority indicators, and responsive layouts.
- **Smart Reminders**: Schedule multiple reminders per task (e.g. 5m before, 30m before, custom times).
- **AI Task Parsing**: Input natural language sentences (e.g. "Doctor appointment tomorrow at 8 PM priority high") and let Google Gemini AI auto-detect scheduling, category, and priority details!
- **Recurrence Support**: Repeat tasks Daily, Weekly, or Monthly.
- **Push Notifications**: Receive instant notifications on task events via Firebase Cloud Messaging.

## Setup Instructions

1. **Prerequisites**: Ensure you have Flutter SDK installed (`>=3.0.0`).
2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
3. **Firebase Configuration**:
   - Place your `google-services.json` in `android/app/`
   - Place your `GoogleService-Info.plist` in `ios/Runner/`
4. **Run Application**:
   ```bash
   flutter run
   ```
