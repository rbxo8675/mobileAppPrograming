# Task List: Running the App on a Real Device

This document outlines the steps to run the CookTalk application on a physical Android or iOS device.

## Prerequisites

1.  **Flutter SDK:** Ensure you have the Flutter SDK installed and configured correctly on your development machine.
2.  **Android Studio / Xcode:**
    *   For **Android**, have Android Studio installed to get the necessary Android toolchain.
    *   For **iOS**, have Xcode installed on a macOS machine.
3.  **Physical Device:** An Android or iOS device.

## Steps to Run the Application

### 1. Connect Your Device

Connect your Android or iOS device to your computer using a USB cable.

### 2. Enable Developer Mode and USB Debugging (Android Only)

If you are using an Android device, you need to enable Developer Options and USB Debugging.

*   Go to **Settings** > **About phone**.
*   Tap on the **Build number** seven times to enable Developer Options.
*   Go back to **Settings** > **System** > **Developer options**.
*   Enable **USB debugging**.

For iOS, you may need to trust the computer on your device and have a valid Apple Developer account configured in Xcode.

### 3. Verify Device Connection

Open your terminal or command prompt and run the following command to check if your device is recognized by Flutter:

```bash
flutter devices
```

You should see your connected device listed in the output.

### 4. Run the App

Navigate to the project's root directory (`D:\mobileAppProgramming\cooktalk`) in your terminal and run the following command:

```bash
flutter run
```

Flutter will build the application and install it on your connected device. The app will start automatically once the installation is complete.

### 5. Troubleshooting

*   If the device is not found, ensure the USB cable is working and the device is properly connected. For Android, check if USB debugging is enabled. For iOS, ensure you have trusted the computer.
*   If the build fails, check the error messages in the console. It might be related to missing dependencies or platform-specific configuration issues. Run `flutter doctor` to diagnose any potential problems with your setup.
