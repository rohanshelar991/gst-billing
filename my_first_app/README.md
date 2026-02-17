# GST Billing SaaS App

Smart GST billing and business operations app built with Flutter + Firebase.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Integrated-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Firestore](https://img.shields.io/badge/Cloud%20Firestore-Live%20Streams-FF6F00)](https://firebase.google.com/docs/firestore)
[![Auth](https://img.shields.io/badge/Auth-Email%2FPassword-0A84FF)](https://firebase.google.com/docs/auth)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-2E7D32)](https://flutter.dev/multi-platform)

## Why This Project

This app is designed as a mini SaaS billing system, not a UI-only prototype.
It supports secure multi-user access, multi-company data isolation, recurring billing, GST calculations, and live financial reporting.

## Core Features

- Authentication
  - Register/Login/Logout with Firebase Auth
  - Auth gate with persisted session handling
- Multi-company support
  - Add/Edit/Delete company
  - Active company switcher in app bar
  - All business data scoped per selected company
- Business modules
  - Clients CRUD
  - Products CRUD
  - Invoices CRUD
  - Reminders CRUD
  - Recurring invoices with pause/resume and auto-generate
- Billing engine
  - GST slab handling (0/5/12/18/28 in calculator + invoices)
  - Same-state logic: CGST + SGST
  - Different-state logic: IGST
  - Payment tracking: paid amount, balance amount, payment history
- Reporting and exports
  - Monthly revenue report
  - GST summary report
  - Top clients report
  - CSV exports
- Security
  - Firestore rules scoped to authenticated user path
  - Role-aware invoice delete rule (admin/owner only)

## Architecture

```mermaid
flowchart LR
  UI["Flutter Screens"] --> Services["Service Layer"]
  Services --> Auth["Firebase Auth"]
  Services --> DB["Cloud Firestore"]
  Services --> Analytics["Firebase Analytics"]
  Services --> Messaging["Firebase Messaging"]
  DB --> Streams["Realtime Streams"]
  Streams --> UI
```

## Project Structure

```text
lib/
├── models/
├── screens/
├── services/
├── theme/
└── widgets/
```

## Firestore Data Model

```text
users/{uid}
  - profile fields
  - role (admin/staff)
  - activeCompanyId
  activityLogs/{logId}
  clients/{clientId}                 # legacy migration support
  products/{productId}               # legacy migration support
  invoices/{invoiceId}               # legacy migration support
  reminders/{reminderId}             # legacy migration support
  companies/{companyId}
    - company profile fields
    clients/{clientId}
    products/{productId}
    invoices/{invoiceId}
    reminders/{reminderId}
    recurringInvoices/{recurringId}
    analytics/{eventId}
```

## Firebase Setup

1. Create or use project: `rohandb-58168`
2. Enable Authentication provider:
   - `Authentication > Sign-in method > Email/Password`
3. Configure FlutterFire:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=rohandb-58168 --platforms=android,ios,web
```

4. Deploy Firestore rules:

```bash
firebase deploy --only firestore:rules --project rohandb-58168
```

## Local Development

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

## Web Notes (FCM)

This repo includes web service worker support:

- `web/firebase-messaging-sw.js`

If push notifications are not needed in local web debug, app still runs safely without crashing.

## QA Status

- Analyzer: no issues
- Widget tests: passing
- Runtime smoke checks: completed on Chrome debug

## Roadmap

- Invoice PDF generation and upload to Firebase Storage
- Cloud Functions for scheduled recurring invoice generation
- Extended charting and financial drill-downs
- CI workflow for analyze + test + rules validation

