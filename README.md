# Expense Tracker

A Flutter expense management application for tracking income, expenses, budgets, categories, reports, and user activity with a clean dashboard UI.

## Overview

This project helps users:

- Add, edit, and delete income and expense transactions
- Track spending by category
- View monthly and category-based summaries
- Monitor income vs. expenses through dashboards and analytics
- Manage a default or user-specific profile
- Persist data locally using SQLite and authenticate users with Firebase

## Tech Stack

- Flutter & Dart
- Firebase Authentication
- Firebase Core
- SQLite with sqflite
- Provider state management
- FlChart for analytics and reports
- Shared Preferences for local settings

## Features

- Secure local database per user
- Income and expense transaction history
- Smart category management
- Dashboard overview and recent transactions
- Monthly analytics and reports
- Dark/light theme support
- Splash and authentication flow
- User profile settings

## Project Structure

```text
lib/
  database/
  models/
  providers/
  screens/
  services/
  utils/
  widgets/
assets/
android/
web/
```

## Getting Started

### Prerequisites

- Flutter SDK installed
- Android Studio / VS Code set up for Flutter
- Firebase project configured for Android

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run -d <device-id>
```

### Build Android release

```bash
flutter build apk --release
```

The generated APK is placed in:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Firebase Setup

This app uses Firebase for authentication and app initialization.

Make sure the Firebase configuration is available in the project, including:

- `android/app/google-services.json`
- `lib/firebase_options.dart`

If needed, regenerate it using:

```bash
flutterfire configure
```

## SQLite Database

The app stores local transaction and category data in SQLite using `sqflite`.

Database features include:

- create database
- create tables
- categorize transactions
- insert/update/delete transactions
- fetch income, expenses, and reports
- support existing migration logic

## Notes

- Android uses the standard SQLite path.
- Desktop platforms can use the FFI setup when needed.
- The project keeps the existing UI, Firebase flow, income/expense logic, and report features intact.

## License

This project is for personal/educational use and is not published to a public package registry.

## Release APK (54MB)
 
 - [text](build/app/outputs/flutter-apk/app-release.apk)

## 🚀 Upcoming Features

- 💳 UPI Payment Integration
- 🏦 Bank Account Integration
- 🔐 Google Sign-In
- ☁️ Cloud Data Synchronization
- 💰 Budget Management
- 🔔 Budget Notifications
- 📊 Advanced Spending Analytics
- 📄 PDF/Excel Report Export
- 🔄 Recurring Transactions
- 🌍 Multiple Currency Support
- 🌙 Dark Mode
- 🔒 PIN/Fingerprint App Lock
- 📅 Yearly Financial Reports
- 💾 Backup and Restore


