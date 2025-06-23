import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_service.dart';
import '../services/whisper_api_service.dart';

class VoiceRecorderScreen extends StatefulWidget {
  @override
  _VoiceRecorderScreenState createState() => _VoiceRecorderScreenState();
}

class _VoiceRecorderScreenState extends State<VoiceRecorderScreen>
    with TickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  final WhisperApiService _whisperService = WhisperApiService();

  bool _isRecording = false;
  bool _isProcessing = false;
  bool _serverHealthy = false;
  String _transcriptionText = '';
  String _errorMessage = '';
  String _statusMessage = 'Ready to record';

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeServices() async {
    _whisperService.initialize();
    await _checkServerHealth();
  }

  Future<void> _checkServerHealth() async {
    setState(() {
      _statusMessage = 'Checking server connection...';
    });

    try {
      final healthy = await _whisperService.checkServerHealth();
      setState(() {
        _serverHealthy = healthy;
        _statusMessage = healthy
            ? 'Server connected successfully'
            : 'Server connection failed';
        _errorMessage = healthy ? '' : 'Make sure Python server is running on ${_whisperService.getServerUrl()}';
      });
    } catch (e) {
      setState(() {
        _serverHealthy = false;
        _statusMessage = 'Server connection failed';
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _toggleRecording() async {
    if (!_serverHealthy) {
      _showSnackBar('Server not available. Please check connection.');
      return;
    }

    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioService.hasPermission();
      if (!hasPermission) {
        final granted = await _audioService.requestPermissions();
        if (!granted) {
          _showSnackBar('Microphone permission is required');
          return;
        }
      }

      final path = await _audioService.startRecording();
      if (path != null) {
        setState(() {
          _isRecording = true;
          _statusMessage = 'Recording... Tap to stop';
          _errorMessage = '';
          _transcriptionText = '';
        });

        _animationController.forward();
        _pulseController.repeat(reverse: true);

        // Haptic feedback
        HapticFeedback.mediumImpact();
      } else {
        _showSnackBar('Failed to start recording');
      }
    } catch (e) {
      _showSnackBar('Recording error: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final recordingPath = await _audioService.stopRecording();

      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _statusMessage = 'Processing audio...';
      });

      _animationController.reverse();
      _pulseController.stop();
      _pulseController.reset();

      // Haptic feedback
      HapticFeedback.lightImpact();

      if (recordingPath != null) {
        await _transcribeAudio(recordingPath);
      } else {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Recording failed';
          _errorMessage = 'No audio file was created';
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Recording error';
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _transcribeAudio(String audioPath) async {
    try {
      final result = await _whisperService.transcribeRealtimeAudio(audioPath);

      if (result != null && result.success) {
        setState(() {
          _transcriptionText = result.transcription;
          _statusMessage = 'Transcription completed';
          _errorMessage = '';
        });

        // Success haptic feedback
        HapticFeedback.selectionClick();
      } else {
        setState(() {
          _statusMessage = 'Transcription failed';
          _errorMessage = 'No transcription result received';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Transcription error';
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });

      // Clean up the audio file
      try {
        await _audioService.deleteRecording(audioPath);
      } catch (e) {
        print('Failed to delete recording: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _copyToClipboard() {
    if (_transcriptionText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _transcriptionText));
      _showSnackBar('Text copied to clipboard');
    }
  }

  void _clearTranscription() {
    setState(() {
      _transcriptionText = '';
      _statusMessage = 'Ready to record';
      _errorMessage = '';
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Whisper Voice Recorder'),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_serverHealthy ? Icons.cloud_done : Icons.cloud_off),
            onPressed: _checkServerHealth,
            tooltip: 'Check server connection',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[700]!,
              Colors.blue[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Status Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              _serverHealthy ? Icons.check_circle : Icons.error,
                              color: _serverHealthy ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _statusMessage,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Recording Button
                Center(
                  child: GestureDetector(
                    onTap: _isProcessing ? null : _toggleRecording,
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: _isRecording
                                  ? [Colors.red[400]!, Colors.red[700]!]
                                  : [Colors.blue[400]!, Colors.blue[700]!],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isRecording ? Colors.red : Colors.blue)
                                    .withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isProcessing
                                ? Icons.hourglass_empty
                                : _isRecording
                                ? Icons.stop
                                : Icons.mic,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isRecording ? _pulseAnimation.value : 1.0,
                            child: child,
                          );
                        },
                      ),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Instructions
                Text(
                  _isRecording
                      ? 'Recording... Tap to stop'
                      : _isProcessing
                      ? 'Processing audio...'
                      : 'Tap to start recording',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 30),

                // Transcription Result
                if (_transcriptionText.isNotEmpty) ...[
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Transcription:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: _copyToClipboard,
                                    tooltip: 'Copy to clipboard',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: _clearTranscription,
                                    tooltip: 'Clear',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: SelectableText(
                              _transcriptionText,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Footer Info
                if (!_serverHealthy)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Server Setup Required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Run: python whisper_server.py\nServer URL: ${_whisperService
                              .getServerUrl()}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
   }
  }