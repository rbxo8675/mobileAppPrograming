# Firestore Permission Error Fix Guide

## Problem
You're experiencing the following error:
```
[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

This occurs when trying to access bookmarks and other Firestore collections.

## Root Causes

### 1. **Anonymous Authentication Not Enabled** (Most Likely)
The app tries to sign in anonymously on startup, but if Anonymous Authentication is not enabled in Firebase Console, the sign-in fails silently, and subsequent Firestore queries fail with permission errors.

### 2. **Race Condition**
Firestore queries might execute before authentication completes.

## Solution Steps

### Step 1: Enable Anonymous Authentication in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **CookTalk**
3. Navigate to: **Authentication** > **Sign-in method**
4. Find **Anonymous** in the list
5. Click on it and toggle **Enable**
6. Click **Save**

**This is the most important step!**

### Step 2: Verify Firestore Rules (Already Correct)

Your `firestore.rules` file already has the correct configuration:

```javascript
// Bookmarks Collection (Top-level)
match /bookmarks/{bookmarkId} {
  allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
  allow update: if isAuthenticated() && resource.data.userId == request.auth.uid;
  allow delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
  // DEBUG: Allow public read to test if it's an auth issue or path issue
  allow read: if true;  // ✅ This allows anyone to read bookmarks
}
```

### Step 3: Deploy Updated Firestore Rules

If you made any changes to `firestore.rules`, deploy them:

```bash
firebase deploy --only firestore:rules
```

### Step 4: Test the Fix

1. **Stop the app completely** (not just hot reload)
2. **Clear app data** or uninstall and reinstall
3. **Run the app again**:
   ```bash
   flutter run
   ```
4. Watch the logs for:
   ```
   Auto signed in anonymously: <user-id>
   ```

### Step 5: Verify Authentication in Logs

Look for these log messages in your console:

✅ **Success:**
```
[00:00:00] ℹ️  INFO Firebase initialized successfully
[00:00:00] ℹ️  INFO Auto signed in anonymously: abc123xyz
[00:00:00] ℹ️  INFO Getting bookmarked recipes for user: abc123xyz
```

❌ **Failure:**
```
[00:00:00] ❌ ERROR Failed to auto sign in anonymously
[00:00:00] ⚠️  IMPORTANT: Enable Anonymous Authentication in Firebase Console
```

## Code Changes Made

I've updated the following files to improve error handling:

### 1. `lib/data/repositories/firestore_recipe_repository.dart`
- Added authentication verification before Firestore queries
- Better error logging with stack traces
- Early return if user is not authenticated

### 2. `lib/main.dart`
- Added delay after anonymous sign-in to ensure auth state propagates
- Better warning messages when authentication fails
- More detailed logging

## Testing Checklist

- [ ] Anonymous Authentication is enabled in Firebase Console
- [ ] App logs show successful anonymous sign-in
- [ ] No permission errors when fetching bookmarks
- [ ] Bookmarking/unbookmarking recipes works
- [ ] User can view their bookmarked recipes

## Troubleshooting

### If you still see permission errors after enabling Anonymous Auth:

1. **Check Firebase Console > Authentication > Users**
   - You should see anonymous users listed there
   - If not, anonymous sign-in is failing

2. **Check Firestore Security Rules in Console**
   - Go to: Firestore Database > Rules
   - Verify the rules match your `firestore.rules` file
   - Make sure they're published (check the timestamp)

3. **Enable Firestore Debug Logging** (optional):
   
   Add this to `main.dart` before Firebase initialization:
   ```dart
   FirebaseFirestore.setLoggingEnabled(true);
   ```

4. **Test with a real user account**:
   - Sign in with email/password instead of anonymous
   - This helps determine if it's an anonymous auth issue specifically

5. **Check Firebase project configuration**:
   ```bash
   flutter clean
   cd android && ./gradlew clean && cd ..
   cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
   flutter pub get
   ```

## Additional Notes

### Why Anonymous Authentication?

Your app uses anonymous authentication to allow users to:
- Browse recipes
- Bookmark recipes
- Like recipes
- Use the cooking assistant

**Without authentication**, users can only read public data (recipes), but cannot:
- Create bookmarks (requires authentication)
- Like recipes (requires authentication)
- Post comments (requires authentication)

### Security Implications

Your current rules allow:
- ✅ Anyone can read recipes (good for browsing)
- ✅ Anyone can read bookmarks (temporary debug setting)
- ✅ Only authenticated users can create/update/delete their own data

**Consider updating the bookmark read rule after debugging:**

```javascript
match /bookmarks/{bookmarkId} {
  allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
  // Change from: allow read: if true;
}
```

## Quick Fix Command

Run this to restart your app with clean state:

```bash
flutter clean && flutter pub get && flutter run
```

## Need More Help?

If the issue persists:
1. Check the Firebase Console for any error messages
2. Verify your Firebase project has Firestore enabled
3. Ensure your app's Firebase configuration files are up to date:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
   - `lib/core/config/firebase_options.dart`

---

**Last Updated:** December 2025
