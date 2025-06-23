import 'dart:io';
import 'package:dio/dio.dart';

class WhisperApiService {
  static final WhisperApiService _instance = WhisperApiService._internal();
  factory WhisperApiService() => _instance;
  WhisperApiService._internal();

  // Change this to your computer's IP address where the Python server is running
  // For Android emulator: use 10.0.2.2
  // For physical device: use your computer's local IP (e.g., 192.168.1.100)
  static const String _baseUrl = 'http://192.168.1.95:5000';

  late final Dio _dio;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
    ));

    // Add interceptors for logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: true,
      error: true,
    ));
  }

  Future<bool> checkServerHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200 &&
          response.data['status'] == 'healthy' &&
          response.data['model_loaded'] == true;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  Future<TranscriptionResult?> transcribeAudio(String audioFilePath) async {
    try {
      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw Exception('Audio file does not exist');
      }

      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioFilePath,
          filename: 'audio.wav',
        ),
      });

      final response = await _dio.post(
        '/transcribe',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return TranscriptionResult.fromJson(response.data);
      } else {
        throw Exception(response.data['error'] ?? 'Transcription failed');
      }
    } on DioException catch (e) {
      print('Dio error: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response!.data}');
        throw Exception(e.response!.data['error'] ?? 'Network error occurred');
      } else {
        throw Exception('Connection failed. Make sure the Python server is running.');
      }
    } catch (e) {
      print('Transcription error: $e');
      throw Exception('Transcription failed: $e');
    }
  }

  Future<RealtimeTranscriptionResult?> transcribeRealtimeAudio(String audioFilePath) async {
    try {
      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw Exception('Audio file does not exist');
      }

      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioFilePath,
          filename: 'audio.wav',
        ),
      });

      final response = await _dio.post(
        '/transcribe_realtime',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return RealtimeTranscriptionResult.fromJson(response.data);
      } else {
        throw Exception(response.data['error'] ?? 'Real-time transcription failed');
      }
    } on DioException catch (e) {
      print('Dio error: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response!.data}');
        throw Exception(e.response!.data['error'] ?? 'Network error occurred');
      } else {
        throw Exception('Connection failed. Make sure the Python server is running.');
      }
    } catch (e) {
      print('Real-time transcription error: $e');
      throw Exception('Real-time transcription failed: $e');
    }
  }

  String getServerUrl() => _baseUrl;
}

class TranscriptionResult {
  final String transcription;
  final String language;
  final bool success;

  TranscriptionResult({
    required this.transcription,
    required this.language,
    required this.success,
  });

  factory TranscriptionResult.fromJson(Map<String, dynamic> json) {
    return TranscriptionResult(
      transcription: json['transcription'] ?? '',
      language: json['language'] ?? 'unknown',
      success: json['success'] ?? false,
    );
  }
}

class TranscriptionSegment {
  final double start;
  final double end;
  final String text;

  TranscriptionSegment({
    required this.start,
    required this.end,
    required this.text,
  });

  factory TranscriptionSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptionSegment(
      start: (json['start'] ?? 0).toDouble(),
      end: (json['end'] ?? 0).toDouble(),
      text: json['text'] ?? '',
    );
  }
}

class RealtimeTranscriptionResult {
  final String transcription;
  final List<TranscriptionSegment> segments;
  final String language;
  final bool success;

  RealtimeTranscriptionResult({
    required this.transcription,
    required this.segments,
    required this.language,
    required this.success,
  });

  factory RealtimeTranscriptionResult.fromJson(Map<String, dynamic> json) {
    final segmentsList = json['segments'] as List<dynamic>? ?? [];
    final segments = segmentsList
        .map((segment) => TranscriptionSegment.fromJson(segment))
        .toList();

    return RealtimeTranscriptionResult(
      transcription: json['transcription'] ?? '',
      segments: segments,
      language: json['language'] ?? 'unknown',
      success: json['success'] ?? false,
    );
  }
}