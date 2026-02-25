# Environment Setup

This project uses environment variables to securely store Firebase configuration.

## Setup Instructions

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Environment file:**
   - The `.env` file has been created with your Firebase configuration
   - This file is already added to `.gitignore` for security
   - **Never commit the `.env` file to version control**

3. **Environment Variables:**
   The following variables are used:
   - `FIREBASE_PROJECT_ID` - Your Firebase project ID
   - `FIREBASE_WEB_API_KEY` - Web API key
   - `FIREBASE_ANDROID_API_KEY` - Android API key
   - `FIREBASE_WEB_APP_ID` - Web app ID
   - `FIREBASE_ANDROID_APP_ID` - Android app ID
   - `FIREBASE_MESSAGING_SENDER_ID` - Sender ID for FCM
   - `FIREBASE_AUTH_DOMAIN` - Auth domain
   - `FIREBASE_STORAGE_BUCKET` - Storage bucket
   - `FIREBASE_MEASUREMENT_ID` - Analytics measurement ID

## Security Notes

- ✅ API keys are now stored in `.env` file
- ✅ `.env` is added to `.gitignore`
- ✅ No hardcoded secrets in source code
- ✅ Environment variables are loaded at runtime

## Deployment

For production deployment:
1. Set environment variables in your hosting service
2. Do NOT deploy the `.env` file
3. Ensure all required environment variables are configured

## Development

The app will show clear error messages if environment variables are missing:
- `MISSING_WEB_API_KEY`
- `MISSING_ANDROID_API_KEY`
- etc.

This helps identify configuration issues quickly.
