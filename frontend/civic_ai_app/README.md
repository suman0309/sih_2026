# CivicAI mobile app

Flutter client for the CivicAI pothole-reporting prototype.

## Run with the backend

1. Start the YOLO detector on port `8000` and the CivicAI backend on port `3001`.
2. From this folder, run `flutter pub get`.
3. Run the app with the appropriate backend address:

```powershell
# Android emulator
flutter run

# Physical phone: replace this with your laptop's Wi-Fi IPv4 address
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:3001
```

Use the scanner to capture or choose a road image. The app uploads it to
`POST /api/reports`, displays the returned YOLO detections, then adds the
saved report to the local feed.

`android.permission.INTERNET`, camera access, and clear-text local HTTP are
enabled for this development prototype. Use HTTPS and proper authentication
before deployment.
