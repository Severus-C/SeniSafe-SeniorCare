import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/emergency_packet.dart';
import '../models/medication.dart';
import '../models/medication_recognition_result.dart';
import '../models/user.dart';

class SeniSafeApiService {
  SeniSafeApiService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? 'http://10.0.2.2:8000',
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  bool get needsIpReminder {
    if (baseUrl.contains('10.0.2.2') || baseUrl.contains('localhost')) {
      return false;
    }
    return !(Platform.isAndroid || Platform.isIOS);
  }

  String? get baseUrlReminder {
    if (needsIpReminder) {
      return '当前 Base URL 不是模拟器回环地址，请确认已经改成可访问的局域网 IP。';
    }
    return null;
  }

  Future<MedicationRecognitionResult> recognizeMedication({
    required User user,
    required List<Medication> currentMedications,
    required File imageFile,
    required String mockHintText,
  }) async {
    final http.StreamedResponse response = await _sendMultipart(
      path: '/medication/recognize',
      fields: <String, String>{
        'user_id': user.id,
        'mock_hint_text': mockHintText,
        'current_medications': jsonEncode(
          currentMedications
              .map(
                (Medication medication) => <String, String>{
                  'name': medication.name,
                  'dosage': medication.dosage,
                },
              )
              .toList(),
        ),
      },
      fileField: 'image',
      file: imageFile,
    );
    final String responseBody = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('药盒识别服务暂时不可用，请稍后再试。');
    }

    return MedicationRecognitionResult.fromJson(
      jsonDecode(responseBody) as Map<String, dynamic>,
    );
  }

  Future<MedicationConfirmResult> confirmMedication({
    required String userId,
    required RecognizedMedicationDetail medication,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/medication/confirm');
    final http.Response response = await _client.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        <String, dynamic>{
          'user_id': userId,
          'name': medication.name,
          'dosage': medication.dosage,
          'usage': medication.usage,
          'contraindications': medication.contraindications,
          'confirmed_at': DateTime.now().toUtc().toIso8601String(),
        },
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('药物确认录入暂未成功，请稍后再试。');
    }

    return MedicationConfirmResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<EmergencyPreparePacketResponse> prepareEmergencyPacket({
    required String userId,
    required Medication medication,
    DateTime? confirmedAt,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/emergency/prepare_packet');
    final http.Response response = await _client.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        <String, dynamic>{
          'user_id': userId,
          'medication_name': medication.name,
          'dosage': medication.dosage,
          'confirmed_at':
              (confirmedAt ?? DateTime.now()).toUtc().toIso8601String(),
        },
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('急救数据包暂未同步成功。');
    }

    return EmergencyPreparePacketResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<EmergencyPacketCard> fetchEmergencyPacket({
    required String userId,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/emergency/packet/$userId');
    final http.Response response = await _client.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('急救名片暂时拉取失败，请稍后再试。');
    }

    return EmergencyPacketCard.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  void dispose() {
    _client.close();
  }

  Future<http.StreamedResponse> _sendMultipart({
    required String path,
    required Map<String, String> fields,
    required String fileField,
    required File file,
  }) async {
    final Uri uri = Uri.parse('$baseUrl$path');
    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..fields.addAll(fields)
      ..files.add(
        await http.MultipartFile.fromPath(
          fileField,
          file.path,
          filename: file.uri.pathSegments.isNotEmpty
              ? file.uri.pathSegments.last
              : 'capture.jpg',
        ),
      );
    return request.send();
  }
}
