/**
 * Firebase Cloud Functions for ArogyaSOS+ SMS Service
 * 
 * This function sends SMS messages using Twilio.
 * 
 * Setup Instructions:
 * 1. Install dependencies: cd functions && npm install
 * 2. Set up Twilio account and get credentials:
 *    - Sign up at https://www.twilio.com/try-twilio
 *    - Get Account SID, Auth Token, and Phone Number
 * 3. Set environment variables:
 *    firebase functions:config:set twilio.account_sid="YOUR_ACCOUNT_SID"
 *    firebase functions:config:set twilio.auth_token="YOUR_AUTH_TOKEN"
 *    firebase functions:config:set twilio.phone_number="YOUR_TWILIO_PHONE_NUMBER"
 * 4. Deploy: firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const twilio = require('twilio');

// Initialize Firebase Admin
admin.initializeApp();

/**
 * Cloud Function to send SMS via Twilio
 * 
 * Call this function from your Flutter app:
 * 
 * Using Firebase Functions SDK:
 * final callable = FirebaseFunctions.instance.httpsCallable('sendSMS');
 * final result = await callable.call({
 *   'phoneNumber': '+1234567890',
 *   'message': 'Your message here'
 * });
 * 
 * Expected request body:
 * {
 *   "phoneNumber": "+1234567890",  // E.164 format
 *   "message": "Your SMS message"
 * }
 * 
 * Returns:
 * {
 *   "success": true/false,
 *   "message": "Status message",
 *   "sid": "Twilio message SID (if successful)"
 * }
 */
exports.sendSMS = functions.https.onCall(async (data, context) => {
  // Get Twilio credentials from Firebase config
  const accountSid = functions.config().twilio.account_sid;
  const authToken = functions.config().twilio.auth_token;
  const twilioPhoneNumber = functions.config().twilio.phone_number;

  // Validate configuration
  if (!accountSid || !authToken || !twilioPhoneNumber) {
    console.error('Twilio configuration missing');
    return {
      success: false,
      message: 'SMS service not configured. Please contact support.',
    };
  }

  // Validate input
  const { phoneNumber, message } = data;
  
  if (!phoneNumber || !message) {
    return {
      success: false,
      message: 'Phone number and message are required',
    };
  }

  // Validate phone number format (should be E.164: +1234567890)
  const phoneRegex = /^\+[1-9]\d{1,14}$/;
  if (!phoneRegex.test(phoneNumber)) {
    return {
      success: false,
      message: 'Invalid phone number format. Use E.164 format (e.g., +1234567890)',
    };
  }

  // Optional: Add authentication check
  // Uncomment the following lines if you want to require authentication
  /*
  if (!context.auth) {
    return {
      success: false,
      message: 'Authentication required',
    };
  }
  */

  try {
    // Initialize Twilio client
    const client = twilio(accountSid, authToken);

    // Send SMS
    const twilioMessage = await client.messages.create({
      body: message,
      from: twilioPhoneNumber,
      to: phoneNumber,
    });

    console.log(`SMS sent successfully. SID: ${twilioMessage.sid}`);

    return {
      success: true,
      message: 'SMS sent successfully',
      sid: twilioMessage.sid,
    };
  } catch (error) {
    console.error('Error sending SMS:', error);
    
    // Return user-friendly error message
    let errorMessage = 'Failed to send SMS';
    if (error.code === 21211) {
      errorMessage = 'Invalid phone number';
    } else if (error.code === 21608) {
      errorMessage = 'Unverified phone number. Please verify your Twilio number.';
    } else if (error.message) {
      errorMessage = error.message;
    }

    return {
      success: false,
      message: errorMessage,
      error: error.code || 'UNKNOWN_ERROR',
    };
  }
});

/**
 * HTTP Cloud Function alternative (if you prefer HTTP calls)
 * 
 * Call this function via HTTP POST:
 * POST https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/sendSMSHTTP
 * Content-Type: application/json
 * 
 * Body:
 * {
 *   "phoneNumber": "+1234567890",
 *   "message": "Your SMS message"
 * }
 */
exports.sendSMSHTTP = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight OPTIONS request
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    res.status(405).json({
      success: false,
      message: 'Method not allowed',
    });
    return;
  }

  // Get Twilio credentials
  const accountSid = functions.config().twilio.account_sid;
  const authToken = functions.config().twilio.auth_token;
  const twilioPhoneNumber = functions.config().twilio.phone_number;

  // Validate configuration
  if (!accountSid || !authToken || !twilioPhoneNumber) {
    console.error('Twilio configuration missing');
    res.status(500).json({
      success: false,
      message: 'SMS service not configured',
    });
    return;
  }

  // Validate input
  const { phoneNumber, message } = req.body;
  
  if (!phoneNumber || !message) {
    res.status(400).json({
      success: false,
      message: 'Phone number and message are required',
    });
    return;
  }

  // Validate phone number format
  const phoneRegex = /^\+[1-9]\d{1,14}$/;
  if (!phoneRegex.test(phoneNumber)) {
    res.status(400).json({
      success: false,
      message: 'Invalid phone number format. Use E.164 format (e.g., +1234567890)',
    });
    return;
  }

  try {
    // Initialize Twilio client
    const client = twilio(accountSid, authToken);

    // Send SMS
    const twilioMessage = await client.messages.create({
      body: message,
      from: twilioPhoneNumber,
      to: phoneNumber,
    });

    console.log(`SMS sent successfully. SID: ${twilioMessage.sid}`);

    res.status(200).json({
      success: true,
      message: 'SMS sent successfully',
      sid: twilioMessage.sid,
    });
  } catch (error) {
    console.error('Error sending SMS:', error);
    
    let errorMessage = 'Failed to send SMS';
    if (error.code === 21211) {
      errorMessage = 'Invalid phone number';
    } else if (error.code === 21608) {
      errorMessage = 'Unverified phone number. Please verify your Twilio number.';
    } else if (error.message) {
      errorMessage = error.message;
    }

    res.status(500).json({
      success: false,
      message: errorMessage,
      error: error.code || 'UNKNOWN_ERROR',
    });
  }
});

/**
 * Realtime Database Trigger: Process SMS Queue
 * 
 * This function automatically triggers when a new SMS request is added to
 * the Realtime Database queue at /smsQueue/{smsId}
 * 
 * Database URL: https://arogyasos-c23e6-default-rtdb.firebaseio.com/
 */
exports.processSMSQueue = functions.database
  .ref('/smsQueue/{smsId}')
  .onCreate(async (snapshot, context) => {
    const smsData = snapshot.val();
    const smsId = context.params.smsId;
    
    // Only process pending SMS
    if (smsData.status !== 'pending') {
      console.log(`SMS ${smsId} is not pending, skipping`);
      return null;
    }
    
    const { phoneNumber, message } = smsData;
    
    // Validate data
    if (!phoneNumber || !message) {
      console.error(`Invalid SMS data for ${smsId}`);
      await snapshot.ref.update({ status: 'failed', error: 'Invalid data' });
      return null;
    }
    
    // Get Twilio credentials
    const accountSid = functions.config().twilio.account_sid;
    const authToken = functions.config().twilio.auth_token;
    const twilioPhoneNumber = functions.config().twilio.phone_number;
    
    // Validate configuration
    if (!accountSid || !authToken || !twilioPhoneNumber) {
      console.error('Twilio configuration missing');
      await snapshot.ref.update({ 
        status: 'failed', 
        error: 'SMS service not configured' 
      });
      return null;
    }
    
    try {
      // Initialize Twilio client
      const client = twilio(accountSid, authToken);
      
      // Update status to processing
      await snapshot.ref.update({ status: 'processing' });
      
      // Send SMS
      const twilioMessage = await client.messages.create({
        body: message,
        from: twilioPhoneNumber,
        to: phoneNumber,
      });
      
      console.log(`SMS sent successfully. SID: ${twilioMessage.sid}, Queue ID: ${smsId}`);
      
      // Update status to completed
      await snapshot.ref.update({
        status: 'completed',
        twilioSid: twilioMessage.sid,
        completedAt: admin.database.ServerValue.TIMESTAMP,
      });
      
      return null;
    } catch (error) {
      console.error(`Error sending SMS for ${smsId}:`, error);
      
      let errorMessage = 'Failed to send SMS';
      if (error.code === 21211) {
        errorMessage = 'Invalid phone number';
      } else if (error.code === 21608) {
        errorMessage = 'Unverified phone number';
      } else if (error.message) {
        errorMessage = error.message;
      }
      
      // Update status to failed
      await snapshot.ref.update({
        status: 'failed',
        error: errorMessage,
        errorCode: error.code || 'UNKNOWN_ERROR',
        failedAt: admin.database.ServerValue.TIMESTAMP,
      });
      
      return null;
    }
  });

