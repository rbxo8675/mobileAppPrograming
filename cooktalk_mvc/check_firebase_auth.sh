#!/bin/bash

echo "================================"
echo "Firebase Authentication Checker"
echo "================================"
echo ""

echo "1. Checking Firebase configuration files..."
echo ""

if [ -f "android/app/google-services.json" ]; then
    echo "✅ android/app/google-services.json exists"
else
    echo "❌ android/app/google-services.json NOT found"
fi

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo "✅ ios/Runner/GoogleService-Info.plist exists"
else
    echo "❌ ios/Runner/GoogleService-Info.plist NOT found"
fi

if [ -f "lib/core/config/firebase_options.dart" ]; then
    echo "✅ lib/core/config/firebase_options.dart exists"
else
    echo "❌ lib/core/config/firebase_options.dart NOT found"
fi

echo ""
echo "2. Checking Firestore rules..."
echo ""

if [ -f "firestore.rules" ]; then
    echo "✅ firestore.rules exists"
    echo ""
    echo "Bookmark rules:"
    grep -A 5 "match /bookmarks" firestore.rules | head -10
else
    echo "❌ firestore.rules NOT found"
fi

echo ""
echo "================================"
echo "Next Steps:"
echo "================================"
echo ""
echo "1. ⚠️  IMPORTANT: Enable Anonymous Authentication"
echo "   Go to: https://console.firebase.google.com/"
echo "   Navigate to: Authentication > Sign-in method > Anonymous"
echo "   Toggle: Enable"
echo ""
echo "2. Run your app and check logs for:"
echo "   ✅ 'Auto signed in anonymously'"
echo "   ❌ 'Failed to auto sign in anonymously'"
echo ""
echo "3. If you see the error, Anonymous Auth is not enabled!"
echo ""

