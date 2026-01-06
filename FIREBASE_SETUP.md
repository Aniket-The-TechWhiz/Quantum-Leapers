# Firebase Setup Guide

This guide will help you set up Firebase for the ArogyaSOS+ app.

## Prerequisites

1. A Firebase account (create one at https://console.firebase.google.com/)
2. FlutterFire CLI installed globally

## Setup Steps

### 1. Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 2. Login to Firebase

```bash
firebase login
```

### 3. Configure Firebase for your Flutter app

Navigate to your project root directory and run:

```bash
flutterfire configure
```

This command will:
- Detect your Firebase projects
- Let you select which Firebase project to use
- Generate the `firebase_options.dart` file automatically
- Configure Firebase for all platforms (Android, iOS, Web, etc.)

### 4. Update main.dart

After running `flutterfire configure`, update `lib/main.dart` to import the generated options:

```dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // ... rest of your code
}
```

### 5. Install Dependencies

Run the following command to install all dependencies:

```bash
flutter pub get
```

### 6. Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database**
4. Click **Create Database**
5. Start in **test mode** (for development) or **production mode** (for production)
6. Choose your preferred location

### 7. Firestore Security Rules (Recommended for Production)

Update your Firestore security rules in the Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // First Aid Guides - Read only for all users
    match /first_aid_guides/{guideId} {
      allow read: if true;
      allow write: if request.auth != null; // Only authenticated users can write
    }
  }
}
```

### 8. Test the Connection

Run your app and navigate to the First Aid Guides screen. The app will automatically:
- Initialize Firebase on startup
- Create default guides if the database is empty
- Load guides from Firestore in real-time

## Troubleshooting

### Error: "FirebaseApp not initialized"

- Make sure you've run `flutterfire configure`
- Check that `firebase_options.dart` exists in `lib/`
- Verify Firebase.initializeApp() is called before using Firebase services

### Error: "Permission denied"

- Check your Firestore security rules
- Ensure your app has internet connectivity
- Verify your Firebase project is active

### Guides not appearing

- Check Firebase Console to see if guides were created
- Verify your Firestore database is created
- Check the console for any error messages

## Adding More Guides

You can add more first aid guides through:
1. Firebase Console (manually)
2. The app's Firebase service (programmatically)
3. Admin panel (if you create one)

## Next Steps

- Set up Firebase Authentication for user-specific features
- Configure Firebase Storage for document attachments
- Set up Firebase Analytics for usage tracking
- Implement offline persistence with Firestore

