import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models/emergency_packet.dart';
import '../models/emergency_record.dart';
import '../models/medication.dart';
import '../models/medication_recognition_result.dart';
import '../models/user.dart';
import '../services/senisafe_api_service.dart';
import '../services/voice_service.dart';

enum AppTab { home, medication, emergency }

class SeniSafeAppState extends ChangeNotifier {
  SeniSafeAppState({
    required this.currentUser,
    required this.todayMedications,
    required this.emergencyRecords,
    required this.apiService,
    required this.voiceService,
  });

  final User currentUser;
  final List<EmergencyRecord> emergencyRecords;
  final List<Medication> todayMedications;
  final SeniSafeApiService apiService;
  final VoiceService voiceService;

  AppTab currentTab = AppTab.home;
  bool isVoiceAssistantActive = false;
  bool isPreparingEmergencyPacket = false;
  bool isLoadingEmergencyCard = false;
  bool isConfirmingMedication = false;
  EmergencyPreparePacketResponse? latestEmergencyPacket;
  EmergencyPacketCard? activeEmergencyCard;
  String? latestSyncMessage;
  String? emergencyErrorMessage;

  int get pendingMedicationCount {
    return todayMedications
        .where((item) => item.intakeState == MedicationIntakeState.pending)
        .length;
  }

  void switchTab(AppTab tab) {
    if (currentTab == tab) {
      return;
    }
    HapticFeedback.selectionClick();
    currentTab = tab;
    notifyListeners();
  }

  Future<void> confirmMedicationByFace(String medicationId) async {
    final int targetIndex =
        todayMedications.indexWhere((item) => item.id == medicationId);
    if (targetIndex == -1) {
      return;
    }
    final Medication confirmedMedication = todayMedications[targetIndex];

    // 先给出强触觉反馈，帮助长者确认自己已经触发关键操作。
    await HapticFeedback.heavyImpact();
    todayMedications[targetIndex] = confirmedMedication.copyWith(
      intakeState: MedicationIntakeState.confirmed,
    );
    isPreparingEmergencyPacket = true;
    latestSyncMessage = '正在整理最近 24 小时服药记录，准备急救数据包。';
    notifyListeners();

    try {
      latestEmergencyPacket = await apiService.prepareEmergencyPacket(
        userId: currentUser.id,
        medication: confirmedMedication,
      );
      latestSyncMessage = latestEmergencyPacket?.summary;
    } catch (_) {
      latestSyncMessage = '本地已确认服药，网络恢复后将继续同步急救数据包。';
    } finally {
      isPreparingEmergencyPacket = false;
      notifyListeners();
    }
  }

  Future<void> triggerEmergencyPacket({bool fromVoice = false}) async {
    isLoadingEmergencyCard = true;
    emergencyErrorMessage = null;
    if (fromVoice) {
      await voiceService.speak('收到呼救，我正在整理急救名片，请稍候。');
    }
    notifyListeners();

    try {
      final EmergencyPacketCard packet = await apiService.fetchEmergencyPacket(
        userId: currentUser.id,
      );
      activeEmergencyCard = packet;
      latestSyncMessage = packet.summary;
      await HapticFeedback.heavyImpact();
    } catch (_) {
      emergencyErrorMessage = '急救名片暂未生成成功，请检查网络后重试。';
    } finally {
      isLoadingEmergencyCard = false;
      notifyListeners();
    }
  }

  Future<void> toggleVoiceAssistant() async {
    isVoiceAssistantActive = !isVoiceAssistantActive;
    await HapticFeedback.mediumImpact();
    notifyListeners();
  }

  Future<MedicationConfirmResult> confirmRecognizedMedication({
    required RecognizedMedicationDetail medication,
  }) async {
    isConfirmingMedication = true;
    latestSyncMessage = '正在为您录入药物，请稍候。';
    notifyListeners();

    try {
      final MedicationConfirmResult result = await apiService.confirmMedication(
        userId: currentUser.id,
        medication: medication,
      );

      if (result.isSaved) {
        final bool alreadyExists = todayMedications.any(
          (Medication item) => item.name == medication.name,
        );
        if (!alreadyExists) {
          todayMedications.add(
            Medication(
              id: 'med-${DateTime.now().millisecondsSinceEpoch}',
              name: medication.name,
              dosage: medication.dosage,
              scheduleLabel: '新录入药物',
              instructions: medication.usage,
              requiresFaceScan: true,
              intakeState: MedicationIntakeState.pending,
            ),
          );
        }
        latestSyncMessage = result.message;
      } else {
        latestSyncMessage = result.message;
      }
      return result;
    } finally {
      isConfirmingMedication = false;
      notifyListeners();
    }
  }

  // 预留方言意图映射入口，后续可接入 Fun-ASR 1.5 的流式结果。
  String mapDialectTextToIntent(String rawText) {
    if (rawText.contains('脚麻') || rawText.contains('唔舒服')) {
      return 'intent.request_assistance';
    }
    return voiceService.parseIntentFromText(rawText);
  }

  static SeniSafeAppState bootstrap() {
    final SeniSafeApiService apiService = SeniSafeApiService();
    final VoiceService voiceService = VoiceService();
    return SeniSafeAppState(
      currentUser: const User(
        id: 'user-001',
        name: '李秀兰',
        age: 72,
        bloodType: 'A+',
        primaryContactName: '李建国',
        primaryContactPhone: '138-0000-6688',
        chronicConditions: <String>['高血压', '2 型糖尿病'],
        allergies: <String>['青霉素'],
      ),
      todayMedications: const <Medication>[
        Medication(
          id: 'med-001',
          name: '缬沙坦胶囊',
          dosage: '80mg / 次',
          scheduleLabel: '早餐后 08:00',
          instructions: '请配温水服用，服药后休息 10 分钟。',
          requiresFaceScan: true,
          intakeState: MedicationIntakeState.pending,
        ),
        Medication(
          id: 'med-002',
          name: '二甲双胍缓释片',
          dosage: '500mg / 次',
          scheduleLabel: '午餐后 12:30',
          instructions: '避免空腹服药，餐后 15 分钟内完成。',
          requiresFaceScan: true,
          intakeState: MedicationIntakeState.pending,
          conflict: MedicationConflict(
            level: ConflictLevel.caution,
            summary: '与近期胃药存在吸收冲突',
            detail: '建议与奥美拉唑间隔 2 小时，避免影响药效。',
          ),
        ),
      ],
      emergencyRecords: <EmergencyRecord>[
        EmergencyRecord(
          id: 'emg-001',
          triggeredAt: DateTime.now().subtract(const Duration(days: 4)),
          reason: '夜间头晕求助',
          status: EmergencyStatus.completed,
          packetSummary: '已打包健康档案、定位信息与近 72 小时服药记录',
          latitude: 31.2304,
          longitude: 121.4737,
        ),
      ],
      apiService: apiService,
      voiceService: voiceService,
    );
  }

  @override
  void dispose() {
    apiService.dispose();
    voiceService.dispose();
    super.dispose();
  }
}
