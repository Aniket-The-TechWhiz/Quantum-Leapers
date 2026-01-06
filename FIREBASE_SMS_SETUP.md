# Firebase SMS Service Setup Guide

This guide will help you set up Firebase Cloud Functions to send SMS messages to emergency contacts using Twilio.

## Prerequisites

1. Firebase project with billing enabled (Cloud Functions require a paid plan)
2. Node.js installed (version 18 or higher)
3. Firebase CLI installed (`npm install -g firebase-tools`)
4. Twilio account (sign up at https://www.twilio.com/try-twilio)

## Step 1: Set Up Twilio Account

1. Sign up for a Twilio account at https://www.twilio.com/try-twilio
2. Get your Account SID and Auth Token from the Twilio Console Dashboard
3. Purchase a Twilio phone number capable of sending SMS
4. Note: Twilio trial accounts can only send SMS to verified numbers

## Step 2: Install Dependencies

```bash
cd functions
npm install
```

## Step 3: Configure Firebase Functions

Set your Twilio credentials as Firebase Functions config:

```bash
firebase functions:config:set twilio.account_sid="YOUR_ACCOUNT_SID"
firebase functions:config:set twilio.auth_token="YOUR_AUTH_TOKEN"
firebase functions:config:set twilio.phone_number="YOUR_TWILIO_PHONE_NUMBER"
```

Replace:
- `YOUR_ACCOUNT_SID` with your Twilio Account SID
- `YOUR_AUTH_TOKEN` with your Twilio Auth Token
- `YOUR_TWILIO_PHONE_NUMBER` with your Twilio phone number (E.164 format, e.g., +1234567890)

## Step 4: Deploy Cloud Functions

```bash
firebase deploy --only functions
```

This will deploy the `sendSMS` function that your Flutter app will call.

## Step 5: Verify Deployment

After deployment, you should see output like:
```
✔  functions[sendSMS(us-central1)] Successful create operation.
```

## Step 6: Test the Function

You can test the function using the Firebase Console:
1. Go to Firebase Console > Functions
2. Click on the `sendSMS` function
3. Use the testing interface to send a test SMS

Or test from your Flutter app by triggering an emergency alert.

## Phone Number Format

The service expects phone numbers in E.164 format:
- Format: `+[country code][number]`
- Example: `+911234567890` (India)
- Example: `+1234567890` (USA)

The Flutter app automatically normalizes phone numbers to this format.

## Security Considerations

1. **Authentication**: The current implementation allows unauthenticated calls. For production, uncomment the authentication check in `functions/index.js`:
   ```javascript
   if (!context.auth) {
     return {
       success: false,
       message: 'Authentication required',
     };
   }
   ```

2. **Rate Limiting**: Consider implementing rate limiting to prevent abuse and manage costs.

3. **Firestore Security Rules**: If you store SMS logs in Firestore, ensure proper security rules.

## Troubleshooting

### Error: "SMS service not configured"
- Make sure you've set all three Twilio config variables
- Verify the config: `firebase functions:config:get`

### Error: "Invalid phone number"
- Ensure phone numbers are in E.164 format (+country code + number)
- Check that the number doesn't have spaces or special characters

### Error: "Unverified phone number"
- Twilio trial accounts can only send to verified numbers
- Verify recipient numbers in Twilio Console or upgrade your account

### Function not found
- Make sure you've deployed the functions: `firebase deploy --only functions`
- Check that your Flutter app is using the correct Firebase project

## Cost Considerations

- Twilio charges per SMS sent (varies by country)
- Firebase Cloud Functions have a free tier, then pay-as-you-go
- Monitor usage in both Firebase and Twilio dashboards

## Alternative: Using HTTP Instead of Functions SDK

If you prefer HTTP calls, you can use the `sendSMSHTTP` function:

1. Get the function URL from Firebase Console
2. Update `FirebaseSMSService` to use `sendSMSViaHTTP` method
3. Pass the function URL when initializing the service:
   ```dart
   final smsService = FirebaseSMSService(
     functionUrl: 'https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/sendSMSHTTP'
   );
   ```

## Support

For issues:
- Firebase Functions: https://firebase.google.com/docs/functions
- Twilio: https://www.twilio.com/docs/sms
- Flutter Firebase: https://firebase.flutter.dev/

