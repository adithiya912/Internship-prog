# Flutter Speech to Text App

A simple Flutter application that converts speech to text in real-time using the device's microphone.

![App Screenshot](screenshot.png) <!-- Add a screenshot if available -->

## Features

- Real-time speech recognition(without whisper)
- Confidence level display
- Cross-platform (Android & iOS)
- Simple and intuitive UI
- Proper permission handling

## Prerequisites

- Flutter SDK (latest stable version)
- Android Studio (for emulator/simulator)
- Physical device recommended for best results

## Development Process

1. Created project structure:
   - Created `pages` folder inside `lib`
   - Added `home_page.dart` inside `pages` folder

2. Updated dependencies:
   - Added `speech_to_text: ^6.3.0` to `pubspec.yaml`
   - Ran `flutter pub get` to install dependencies

3. Configured platform-specific files:
   - Updated `Info.plist` for iOS permissions:
     ```xml
     <key>NSSpeechRecognitionUsageDescription</key>
     <string>Permission required for speech recognition</string>
     <key>NSMicrophoneUsageDescription</key>
     <string>Permission required to use microphone</string>
     ```
   - Updated `AndroidManifest.xml` for Android permissions:
     ```xml
     <uses-permission android:name="android.permission.RECORD_AUDIO"/>
     <uses-permission android:name="android.permission.INTERNET"/>
     ```
   - Updated Gradle files as needed

4. Implemented core functionality:
   - Updated `main.dart` to use `HomePage`
   - Developed speech recognition logic in `home_page.dart`

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/week1.git
