# GST Billing SaaS

Production-oriented GST billing app built with Flutter and Firebase.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Firestore](https://img.shields.io/badge/Firestore-Realtime-FF6F00)](https://firebase.google.com/docs/firestore)
[![Auth](https://img.shields.io/badge/Auth-Email%2FPassword-0A84FF)](https://firebase.google.com/docs/auth)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-2E7D32)](https://flutter.dev/multi-platform)

## Project Layout

```text
roh/
└── my_first_app/   # Flutter + Firebase app source
```

## Current Highlights

- Firebase Authentication (register/login/logout, auth state gate)
- Multi-company support with active company switcher
- Company-scoped clients, products, invoices, reminders, recurring invoices
- GST calculation engine (CGST/SGST/IGST)
- Recurring invoice scheduling and auto-generation
- Real-time dashboard and financial reports (streams)
- Firestore role-aware rules (admin/staff behavior)

## Quick Start

```bash
cd my_first_app
flutter pub get
flutter run -d chrome
```

## Detailed Documentation

See: [`my_first_app/README.md`](./my_first_app/README.md)

