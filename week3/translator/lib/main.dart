import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late OnDeviceTranslator onDeviceTranslator;
  final modelManager = OnDeviceTranslatorModelManager();
  bool isTranslatorReady = false;
  TextEditingController inputCon = TextEditingController();
  var resultText = "translated text";
  TranslateLanguage sourceLang = TranslateLanguage.english;
  TranslateLanguage targetLang = TranslateLanguage.tamil;
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isModelDownloaded();
    onDeviceTranslator = OnDeviceTranslator(
      sourceLanguage: sourceLang,
      targetLanguage: targetLang,
    );
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      inputCon.text = result.recognizedWords;
      performTranslation();
    });
  }

  isModelDownloaded() async {
    bool isSourceDownloaded = await modelManager.isModelDownloaded(
      sourceLang.bcpCode,
    );
    bool isTargetDownloaded = await modelManager.isModelDownloaded(
      targetLang.bcpCode,
    );
    if (isSourceDownloaded && isTargetDownloaded) {
      isTranslatorReady = true;
    } else {
      if (isSourceDownloaded == false) {
        isSourceDownloaded = await modelManager.downloadModel(
          sourceLang.bcpCode,
        );
      }
      if (isTargetDownloaded == false) {
        isTargetDownloaded = await modelManager.downloadModel(
          targetLang.bcpCode,
        );
      }
      if (isSourceDownloaded && isTargetDownloaded) {
        isTranslatorReady = true;
      }
    }
  }

  performTranslation() async {
    if (isTranslatorReady) {
      resultText = await onDeviceTranslator.translateText(inputCon.text);
      setState(() {
        resultText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Speech to Text ', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                child: Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      maxLines: 10,
                      decoration: InputDecoration(
                        hintText: "Enter your text",
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 25),
                      ),
                      controller: inputCon,
                      style: TextStyle(fontSize: 25),
                      onChanged: (text) {
                        performTranslation();
                      },
                    ),
                  ),
                ),
              ),
              //ElevatedButton(onPressed: (){performTranslation();}, child: Text('Translate')),
              Expanded(
                child: Card(
                  color: Colors.white,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    width: MediaQuery.of(context).size.width,
                    child: SingleChildScrollView(child: Text(resultText, style: TextStyle(fontSize: 25))),
                  ),
                ),
              ),
              Card(
                child: InkWell(
                  onTap: (){
                    _startListening();

                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    child: Icon(Icons.mic, size: 40, color: Colors.white),
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                color: Colors.blue.shade800,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
