# Real-Time Speech-to-Text with Translation

A Flutter application that performs real-time speech recognition and translation using Google's ML Kit for Android.

## Features

- Real-time speech recognition
- Translation to multiple languages
- Works offline (for supported languages)
- Easy-to-use interface
- Sound level monitoring
- Partial results display
- Multiple locale support

## Prerequisites

- Flutter SDK (version 3.0.0 or higher)
- Android Studio
- Android device or emulator (API level 21 or higher)
- Google Play Services (for ML Kit functionality)

## Installation

### 1. Dependencies

Add these dependencies to your `pubspec.yaml` file:

```yaml
name: speech_translation_app
description: A Flutter app for real-time speech recognition and translation.

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.0.0"

dependencies:
  flutter:
    sdk: flutter
  speech_to_text: ^6.3.0
  google_mlkit_translation: ^0.10.0
  permission_handler: ^10.4.3
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true
```

### 2. Install Dependencies

Run the following command in your project root:

```bash
flutter pub get
```

### 3. Android Configuration

Add these permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Required permissions -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.MICROPHONE" />
    
    <!-- For Android 10+ (API level 29+) -->
    <queries>
        <intent>
            <action android:name="android.speech.RecognitionService" />
        </intent>
    </queries>

    <application
        android:label="Speech Translation App"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Your activity configuration -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
                
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

## Usage

### 1. Initialize Speech Recognition

```dart
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class SpeechTranslationService {
  final SpeechToText speech = SpeechToText();
  OnDeviceTranslator? translator;
  String recognizedText = '';
  String translatedResult = '';
  double soundLevel = 0.0;
  String _currentLocaleId = 'en_US';

  Future<void> initSpeech() async {
    bool available = await speech.initialize(
      onStatus: (status) => print('Speech Status: $status'),
      onError: (error) => print('Speech Error: $error'),
    );
    
    if (available) {
      print("Speech recognition available");
      await _initializeTranslator();
    } else {
      print("Speech recognition not available");
    }
  }

  Future<void> _initializeTranslator() async {
    translator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: TranslateLanguage.french, // Default target
    );
  }
}
```

### 2. Start Listening

```dart
void startListening() async {
  if (!speech.isAvailable) {
    await initSpeech();
  }
  
  await speech.listen(
    onResult: (result) {
      recognizedText = result.recognizedWords;
      
      if (result.finalResult) {
        translateText(recognizedText);
      }
    },
    listenFor: Duration(minutes: 5),
    pauseFor: Duration(seconds: 5),
    partialResults: true,
    localeId: _currentLocaleId,
    onSoundLevelChange: (level) {
      soundLevel = level;
    },
  );
}
```

### 3. Stop Listening

```dart
void stopListening() async {
  await speech.stop();
}
```

### 4. Translate Text

```dart
Future<void> translateText(String text) async {
  if (translator == null) return;
  
  try {
    final translatedText = await translator!.translateText(text);
    translatedResult = translatedText;
  } catch (e) {
    print('Translation error: $e');
    translatedResult = 'Translation failed';
  }
}
```

### 5. Change Translation Language

```dart
Future<void> changeTargetLanguage(TranslateLanguage targetLanguage) async {
  translator?.close();
  
  translator = OnDeviceTranslator(
    sourceLanguage: TranslateLanguage.english,
    targetLanguage: targetLanguage,
  );
}
```

### 6. Get Available Locales

```dart
Future<List<LocaleName>> getAvailableLocales() async {
  if (speech.isAvailable) {
    return await speech.locales();
  }
  return [];
}
```

### 7. Complete Example Widget

```dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class SpeechTranslationPage extends StatefulWidget {
  @override
  _SpeechTranslationPageState createState() => _SpeechTranslationPageState();
}

class _SpeechTranslationPageState extends State<SpeechTranslationPage> {
  final SpeechToText _speech = SpeechToText();
  OnDeviceTranslator? _translator;
  
  String _recognizedText = '';
  String _translatedText = '';
  bool _isListening = false;
  double _soundLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize();
    if (available) {
      _translator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.english,
        targetLanguage: TranslateLanguage.spanish,
      );
    }
    setState(() {});
  }

  void _startListening() async {
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });
        if (result.finalResult) {
          _translateText(_recognizedText);
        }
      },
      onSoundLevelChange: (level) {
        setState(() {
          _soundLevel = level;
        });
      },
    );
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _translateText(String text) async {
    if (_translator != null && text.isNotEmpty) {
      final translated = await _translator!.translateText(text);
      setState(() {
        _translatedText = translated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speech Translation'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recognized Text:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(_recognizedText.isEmpty ? 'Tap microphone to start...' : _recognizedText),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Translation:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(_translatedText.isEmpty ? 'Translation will appear here...' : _translatedText),
                ],
              ),
            ),
            Spacer(),
            LinearProgressIndicator(value: _soundLevel),
            SizedBox(height: 16),
            FloatingActionButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Icon(_isListening ? Icons.mic : Icons.mic_none),
              backgroundColor: _isListening ? Colors.red : Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _translator?.close();
    super.dispose();
  }
}
```

## Supported Languages

### Speech Recognition Locales
Common supported locales include:
- English (US): `en_US`
- English (UK): `en_GB`
- Spanish: `es_ES`
- French: `fr_FR`
- German: `de_DE`
- Italian: `it_IT`
- Portuguese: `pt_BR`
- Chinese: `zh_CN`
- Japanese: `ja_JP`
- Korean: `ko_KR`

### Translation Languages
Supported translation languages:
- English (`TranslateLanguage.english`)
- Spanish (`TranslateLanguage.spanish`)
- French (`TranslateLanguage.french`)
- German (`TranslateLanguage.german`)
- Italian (`TranslateLanguage.italian`)
- Portuguese (`TranslateLanguage.portuguese`)
- Chinese (`TranslateLanguage.chinese`)
- Japanese (`TranslateLanguage.japanese`)
- Korean (`TranslateLanguage.korean`)
- Russian (`TranslateLanguage.russian`)
- Arabic (`TranslateLanguage.arabic`)
- Hindi (`TranslateLanguage.hindi`)
- Dutch (`TranslateLanguage.dutch`)
- Polish (`TranslateLanguage.polish`)
- Turkish (`TranslateLanguage.turkish`)

## Important Notes

### Model Downloads
- Translation models are downloaded automatically on first use
- Downloaded models are cached for offline use
- Ensure internet connection for initial model download
- Models are approximately 30-40MB each

### Performance Tips
- Speech recognition accuracy improves with:
  - Clear pronunciation
  - Minimal background noise
  - Proper microphone positioning
  - Speaking at moderate pace

### Offline Usage
- Speech recognition works offline after initial setup
- Translation works offline after models are downloaded
- No internet required for cached language pairs

## Troubleshooting

### Speech Recognition Issues
1. **Permission denied**: Check microphone permissions in device settings
2. **Not available**: Verify Google Play Services are installed and updated
3. **Poor accuracy**: Reduce background noise, speak clearly
4. **App crashes**: Check Android API level compatibility (minimum API 21)

### Translation Issues
1. **Translation fails**: Check internet connection for model download
2. **Empty results**: Verify source text is not empty
3. **Unsupported language**: Check supported language list
4. **Memory issues**: Close translator instances when done

### Common Solutions
```dart
// Check permissions
Future<bool> checkPermissions() async {
  return await Permission.microphone.request().isGranted;
}

// Verify speech availability
Future<bool> isSpeechAvailable() async {
  return await SpeechToText().initialize();
}

// Handle translation errors
Future<String> safeTranslate(String text) async {
  try {
    return await translator?.translateText(text) ?? 'Translation unavailable';
  } catch (e) {
    return 'Translation error: ${e.toString()}';
  }
}
```



## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Google ML Kit for translation capabilities
- Speech-to-Text plugin for Flutter
- Flutter team for the amazing framework

---

**Note**: This app currently supports Android only. iOS support may be added in future versions using Apple's Speech Framework.
