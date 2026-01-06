# Firebase Realtime Database onChange Listeners

This document describes the real-time database listeners implemented in the ArogyaSOS+ app.

## Overview

The app uses Firebase Realtime Database onChange listeners to provide real-time updates across various features. These listeners automatically update the UI when data changes in the Firebase database.

## Implemented Listeners

### 1. SOS Notification Status Listener

**Location:** `lib/screens/emergency_sos_screen.dart`

**Purpose:** Monitors the status of SOS notifications sent by the user.

**What it listens to:**
- `/sosNotifications/{notificationId}` - Status changes (pending → processing → completed/failed)

**Features:**
- Automatically starts listening after sending an SOS alert
- Shows real-time status updates to the user:
  - `processing`: Shows "Processing emergency alert..." message
  - `completed`: Shows success count and failure count
  - `failed`: Shows error message

**Usage:**
```dart
_fcmService.watchSOSNotificationStatus(notificationId).listen((data) {
  // Handle status updates
});
```

### 2. Emergency Contact FCM Tokens Listener

**Location:** `lib/screens/emergency_sos_screen.dart`

**Purpose:** Monitors changes to emergency contact FCM tokens.

**What it listens to:**
- `/fcmTokens/emergencyContacts/{userId}` - Token updates for emergency contacts

**Features:**
- Automatically tracks when emergency contacts register or update their FCM tokens
- Useful for ensuring notifications can be sent to all registered contacts

**Usage:**
```dart
_fcmService.watchEmergencyContactTokens().listen((tokens) {
  // Handle token updates
});
```

### 3. Pharmacies Data Listener

**Location:** `lib/screens/medicine_finder_screen.dart`

**Purpose:** Monitors real-time changes to pharmacy data in the database.

**What it listens to:**
- `/pharmacies` - All pharmacy data changes (open/closed status, ratings, etc.)

**Features:**
- Automatically updates the pharmacy list when:
  - New pharmacies are added
  - Pharmacy data is updated (hours, ratings, status)
  - Pharmacy information changes
- Recalculates distances when pharmacy data updates
- No need to manually refresh the screen

**Usage:**
```dart
FirebaseDatabase.instance.ref('pharmacies').onValue.listen((event) {
  // Handle pharmacy data updates
});
```

## Available Listener Methods in FirebaseFCMService

The `FirebaseFCMService` class provides several listener methods:

### 1. `watchSOSNotificationStatus(String notificationId)`
Listen to status changes of a specific SOS notification.

### 2. `watchUserSOSNotifications()`
Listen to all SOS notifications for the current user.

### 3. `watchEmergencyContactTokens()`
Listen to FCM token changes for emergency contacts.

### 4. `watchUserFCMToken()`
Listen to changes in the user's own FCM token.

### 5. `watchDatabasePath(String path)`
Generic listener for any database path.

### 6. `watchChildAdded(String path)`
Listen to when new children are added to a path.

### 7. `watchChildChanged(String path)`
Listen to when children are modified in a path.

### 8. `watchChildRemoved(String path)`
Listen to when children are removed from a path.

## Database Structure

The listeners monitor the following database structure:

```
/pharmacies/
  ph_001/
    id, name, address, rating, isOpen, distanceText, contactNumber, location

/sosNotifications/
  sos_1234567890/
    userId, userName, message, location, coordinates, locationLink, medicalInfo
    status, timestamp, successCount, failureCount, completedAt

/fcmTokens/
  {userId}/
    token, updatedAt
  emergencyContacts/
    {userId}/
      {contactId}/
        token, phone, name, updatedAt
```

## Best Practices

1. **Always cancel subscriptions in dispose()**: Prevent memory leaks by canceling all StreamSubscriptions when widgets are disposed.

2. **Check mounted state**: Before calling `setState()`, always check if the widget is still mounted.

3. **Handle errors**: Always provide error handlers for streams to handle network or permission issues gracefully.

4. **Use specific paths**: Listen to specific paths rather than the root to reduce data transfer and improve performance.

## Example: Adding a New Listener

To add a new real-time listener:

```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  StreamSubscription<DatabaseEvent>? _mySubscription;

  @override
  void initState() {
    super.initState();
    _setupListener();
  }

  void _setupListener() {
    _mySubscription = FirebaseDatabase.instance
        .ref('myPath')
        .onValue
        .listen((event) {
      if (mounted) {
        setState(() {
          // Update UI based on event.snapshot.value
        });
      }
    }, onError: (error) {
      debugPrint('Error: $error');
    });
  }

  @override
  void dispose() {
    _mySubscription?.cancel();
    super.dispose();
  }
}
```

## Benefits

1. **Real-time Updates**: Users see data changes immediately without manual refresh
2. **Better UX**: No need to pull-to-refresh or reload screens
3. **Automatic Sync**: Data stays synchronized across all devices
4. **Efficient**: Only updates when data actually changes
5. **Reliable**: Firebase handles reconnection and offline support automatically

## Cloud Functions Integration

The listeners work seamlessly with Cloud Functions:

1. User sends SOS alert → Queued in `/sosNotifications`
2. Cloud Function triggers → Processes notification
3. Function updates status → Listener detects change
4. UI updates automatically → User sees real-time status

This creates a complete real-time feedback loop for the user.

