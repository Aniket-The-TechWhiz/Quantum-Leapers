# Firebase Realtime Database Integration

This document explains how the SMS service integrates with your Firebase Realtime Database.

## Database Location

- **Project**: `arogyasos-c23e6`
- **Database URL**: `https://arogyasos-c23e6-default-rtdb.firebaseio.com/`
- **Console**: https://console.firebase.google.com/u/0/project/arogyasos-c23e6/database/arogyasos-c23e6-default-rtdb/data/~2F

## How It Works

The SMS service uses Firebase Realtime Database to queue SMS requests, which are then automatically processed by Cloud Functions triggers.

### Flow:

1. **App queues SMS** → Writes to `/smsQueue/{smsId}` in Realtime Database
2. **Cloud Function triggers** → `processSMSQueue` function detects new entry
3. **SMS sent via Twilio** → Cloud Function sends SMS and updates status
4. **Status updated** → Database entry updated with completion status

## Database Structure

```
/smsQueue/
  ├── sms_1234567890/
  │   ├── phoneNumber: "+911234567890"
  │   ├── message: "Emergency alert message..."
  │   ├── timestamp: 1234567890
  │   ├── status: "pending" | "processing" | "completed" | "failed"
  │   ├── createdAt: "2024-01-01T12:00:00.000Z"
  │   ├── twilioSid: "SM1234567890abcdef" (if completed)
  │   └── error: "Error message" (if failed)
```

## Setup Instructions

### 1. Enable Realtime Database

1. Go to [Firebase Console](https://console.firebase.google.com/project/arogyasos-c23e6/database)
2. Navigate to **Realtime Database**
3. Click **Create Database** (if not already created)
4. Choose your region
5. Start in **test mode** for development (update rules for production)

### 2. Configure Database Rules

Update your Realtime Database security rules:

```json
{
  "rules": {
    "smsQueue": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$smsId": {
        ".validate": "newData.hasChildren(['phoneNumber', 'message', 'status'])"
      }
    },
    "users": {
      "$userId": {
        ".read": "$userId === auth.uid",
        ".write": "$userId === auth.uid"
      }
    }
  }
}
```

**Note**: For production, implement proper authentication and restrict access.

### 3. Deploy Cloud Functions

The `processSMSQueue` function automatically processes SMS requests:

```bash
cd functions
npm install
firebase deploy --only functions:processSMSQueue
```

### 4. Configure Twilio

Set Twilio credentials in Firebase Functions config:

```bash
firebase functions:config:set twilio.account_sid="YOUR_ACCOUNT_SID"
firebase functions:config:set twilio.auth_token="YOUR_AUTH_TOKEN"
firebase functions:config:set twilio.phone_number="YOUR_TWILIO_PHONE_NUMBER"
```

## Usage in Flutter App

The SMS service automatically uses Realtime Database when available:

```dart
// In emergency_sos_screen.dart
final smsService = FirebaseSMSService();

// Queue SMS in Realtime Database (automatically processed by Cloud Functions)
await smsService.queueSMSInRealtimeDatabase(
  phoneNumber: '+911234567890',
  message: 'Emergency alert message',
);
```

## Monitoring

### View SMS Queue in Firebase Console

1. Go to Realtime Database
2. Navigate to `/smsQueue`
3. View all queued SMS requests and their status

### Check Cloud Functions Logs

```bash
firebase functions:log --only processSMSQueue
```

## Benefits

1. **Automatic Processing**: SMS requests are automatically processed by Cloud Functions
2. **Status Tracking**: Each SMS request has a status (pending, processing, completed, failed)
3. **Reliability**: Failed SMS can be retried
4. **Scalability**: Handles multiple SMS requests efficiently
5. **Offline Support**: SMS requests are queued even if device is offline

## Troubleshooting

### SMS not being sent

1. Check Realtime Database rules allow writes
2. Verify Cloud Function is deployed: `firebase functions:list`
3. Check Cloud Function logs for errors
4. Verify Twilio credentials are configured

### Database permission errors

1. Update security rules to allow writes
2. Ensure authentication is set up (if using auth-based rules)
3. Check Firebase project permissions

### Cloud Function not triggering

1. Verify function is deployed: `firebase functions:list`
2. Check function logs: `firebase functions:log`
3. Ensure Realtime Database is enabled in Firebase Console
4. Verify database URL matches in code

## Security Considerations

1. **Authentication**: Implement Firebase Authentication for production
2. **Rate Limiting**: Add rate limiting to prevent abuse
3. **Validation**: Validate phone numbers and message content
4. **Access Control**: Restrict database access based on user authentication

## Cost Considerations

- **Realtime Database**: Free tier includes 1 GB storage and 10 GB/month transfer
- **Cloud Functions**: Free tier includes 2 million invocations/month
- **Twilio**: Pay per SMS sent (varies by country)

Monitor usage in Firebase Console and Twilio Dashboard.

