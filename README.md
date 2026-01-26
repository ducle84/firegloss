# firegloss

A new Flutter project with Python backend integration.

## Project Structure

```
firegloss/
├── lib/                    # Flutter app source code
├── firegloss_backend/      # Python backend with Firebase
├── android/               # Android platform files
├── ios/                   # iOS platform files
├── web/                   # Web platform files
└── windows/               # Windows platform files
```

## Quick Start

### Flutter App

```bash
flutter run
# or for web
flutter run -d chrome
```

### Python Backend

```bash
# Windows
start_backend.bat

# Or manually:
cd firegloss_backend
.\venv\Scripts\Activate.ps1
python main.py
```

## Backend API

- **Server**: http://127.0.0.1:8000
- **Documentation**: http://127.0.0.1:8000/docs

## Firebase Integration

- Frontend: Firebase Auth, Firestore client
- Backend: Firebase Admin SDK for server operations

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
