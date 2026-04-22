import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/medication_recognition_result.dart';
import '../../services/voice_service.dart';
import '../../state/senisafe_app_state.dart';
import '../../theme/senisafe_theme.dart';

enum MedicationAssistantStage {
  preview,
  scanning,
  recognized,
  conflict,
}

class MedicationAssistantScreen extends StatefulWidget {
  const MedicationAssistantScreen({super.key});

  @override
  State<MedicationAssistantScreen> createState() =>
      _MedicationAssistantScreenState();
}

class _MedicationAssistantScreenState extends State<MedicationAssistantScreen> {
  CameraController? _cameraController;
  Future<void>? _cameraInitialization;
  StreamSubscription? _voiceRecognitionSubscription;
  StreamSubscription? _voiceAnnouncementSubscription;

  MedicationAssistantStage _stage = MedicationAssistantStage.preview;
  MedicationRecognitionResult? _recognitionResult;
  String _voiceBubbleText = '爷爷/奶奶，您可以拍药盒，我会帮您看清楚。';
  String _recognizedVoiceBanner = '支持方言提问，例如：“这个药咋个吃”。';
  bool _showUsageHighlight = false;
  bool _showConflictOverlay = false;
  bool _isBusy = false;
  bool _cameraReady = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _bindVoiceEvents();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _cameraInitialization = _setupCamera();
    });
    await _cameraInitialization;
  }

  Future<void> _setupCamera() async {
    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = '当前设备未检测到可用摄像头，请稍后再试。';
          _cameraReady = false;
        });
        return;
      }

      final CameraDescription selectedCamera = cameras.first;
      final CameraController controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _cameraReady = true;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _cameraReady = false;
        _errorMessage = '相机暂时无法打开，我们会先保留识别流程入口。';
      });
    }
  }

  void _bindVoiceEvents() {
    final SeniSafeAppState appState = context.read<SeniSafeAppState>();

    _voiceRecognitionSubscription =
        appState.voiceService.recognitionStream.listen((event) {
      if (!mounted) {
        return;
      }

      setState(() {
        _recognizedVoiceBanner = '已识别方言指令：${event.rawText}';
        _showUsageHighlight = event.intent == 'intent.highlight_usage';
      });

      if (event.intent == 'intent.highlight_usage') {
        HapticFeedback.selectionClick();
      }
    });

    _voiceAnnouncementSubscription =
        appState.voiceService.announcementStream.listen((event) {
      if (!mounted) {
        return;
      }
      setState(() {
        _voiceBubbleText = event.text;
      });
    });
  }

  Future<void> _simulateMedicationCapture() async {
    if (_isBusy) {
      return;
    }

    final SeniSafeAppState appState = context.read<SeniSafeAppState>();
    setState(() {
      _isBusy = true;
      _stage = MedicationAssistantStage.scanning;
      _recognitionResult = null;
      _showConflictOverlay = false;
      _showUsageHighlight = false;
      _errorMessage = null;
    });

    await HapticFeedback.mediumImpact();
    await appState.voiceService.speak('爷爷/奶奶，正在帮您认药，请拿稳手机。');

    try {
      final String payload = _buildMockImagePayload();
      final MedicationRecognitionResult result =
          await appState.apiService.recognizeMedication(
        user: appState.currentUser,
        currentMedications: appState.todayMedications,
        imageBase64: payload,
        mockHintText: 'aspirin',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _recognitionResult = result;
        _stage = result.hasConflict
            ? MedicationAssistantStage.conflict
            : MedicationAssistantStage.recognized;
        _showConflictOverlay = result.hasConflict;
        _voiceBubbleText = result.hasConflict
            ? result.conflictWarning!.voicePrompt
            : '已识别完成，您可以查看用法用量。';
      });

      if (result.hasConflict) {
        await HapticFeedback.heavyImpact();
        await appState.voiceService.speak(
          result.conflictWarning!.voicePrompt,
          style: VoiceAnnouncementStyle.warning,
        );
      } else {
        await appState.voiceService.speak(
          '识别完成，您可以问我这个药怎么吃。',
          style: VoiceAnnouncementStyle.guidance,
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _stage = MedicationAssistantStage.preview;
        _errorMessage = '药盒识别暂时没有成功，请检查网络后再试。';
        _voiceBubbleText = '网络有一点忙，我们稍后再帮您认药。';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  String _buildMockImagePayload() {
    final Uint8List bytes = Uint8List.fromList(
      utf8.encode('senisafe-demo-image:aspirin'),
    );
    return base64Encode(bytes);
  }

  @override
  void dispose() {
    _voiceRecognitionSubscription?.cancel();
    _voiceAnnouncementSubscription?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SeniSafeAppState appState = context.watch<SeniSafeAppState>();

    return SafeArea(
      child: Stack(
        children: <Widget>[
          CustomScrollView(
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 180),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    <Widget>[
                      Text('药盒助手', style: theme.textTheme.displayMedium),
                      const SizedBox(height: 12),
                      Text(
                        '拍一下药盒，系统会帮您认药、看用法，还会检查和现有药物有没有冲突。',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: SeniSafeTheme.sectionSpacing),
                      _buildScannerPanel(theme),
                      const SizedBox(height: 20),
                      _VoiceCoachBall(message: _voiceBubbleText),
                      const SizedBox(height: SeniSafeTheme.sectionSpacing),
                      _buildResultCard(theme, appState),
                      const SizedBox(height: SeniSafeTheme.sectionSpacing),
                      _buildVoiceTestingCard(theme, appState),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showConflictOverlay && _recognitionResult?.conflictWarning != null)
            Positioned.fill(
              child: _ConflictOverlay(
                warning: _recognitionResult!.conflictWarning!,
                onDismiss: () {
                  setState(() {
                    _showConflictOverlay = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerPanel(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text('OCR 扫描页', style: theme.textTheme.headlineSmall),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _isBusy
                        ? SeniSafeTheme.warmApricot
                        : SeniSafeTheme.pineGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    _stage == MedicationAssistantStage.scanning
                        ? '识别中'
                        : '待扫描',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: SeniSafeTheme.pineGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(SeniSafeTheme.largeRadius),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    if (_cameraReady && _cameraController != null)
                      CameraPreview(_cameraController!)
                    else
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              Color(0xFFF0F4EE),
                              Color(0xFFD7E5D3),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _errorMessage ?? '正在准备相机预览窗口，请稍候。',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: SeniSafeTheme.pineGreen,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    const _NewChineseScanFrame(),
                    if (_stage == MedicationAssistantStage.scanning)
                      Container(
                        color: Colors.black.withOpacity(0.16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const SizedBox(
                              width: 64,
                              height: 64,
                              child: CircularProgressIndicator(
                                strokeWidth: 6,
                                color: SeniSafeTheme.warmApricot,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              '正在识别药盒文字与风险信息',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '扫描提示：请把药盒正面放进框内，尽量保持手稳，系统会自动检查冲突风险。',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isBusy ? null : _simulateMedicationCapture,
              icon: const Icon(Icons.camera_alt_outlined, size: 34),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('拍药盒并上传识别'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme, SeniSafeAppState appState) {
    final MedicationRecognitionResult? result = _recognitionResult;
    final RecognizedMedicationDetail? medication = result?.medication;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('识别结果页', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              result?.message ?? '扫描后会在这里显示药品名、用法用量和冲突提示。',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _ResultInfoTile(
              label: '药品名',
              value: medication?.name ?? '待识别',
            ),
            const SizedBox(height: 18),
            _ResultInfoTile(
              label: '剂量',
              value: medication?.dosage ?? '待识别',
            ),
            const SizedBox(height: 18),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _showUsageHighlight
                    ? SeniSafeTheme.warmApricot.withOpacity(0.45)
                    : SeniSafeTheme.pineGreen.withOpacity(0.06),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _showUsageHighlight
                      ? SeniSafeTheme.warningOrange
                      : SeniSafeTheme.pineGreen.withOpacity(0.08),
                  width: _showUsageHighlight ? 3 : 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text('用法用量', style: theme.textTheme.labelLarge),
                      ),
                      if (_showUsageHighlight)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: SeniSafeTheme.warningOrange,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            '已高亮',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    medication?.usage ?? '这里会根据识别结果展示服药时间与方法。',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: SeniSafeTheme.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _ResultInfoTile(
              label: '禁忌症',
              value: medication?.contraindications ?? '待识别',
            ),
            if (result?.hasConflict ?? false) ...<Widget>[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: SeniSafeTheme.warningOrange.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Text(
                  result!.conflictWarning!.detail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: SeniSafeTheme.ink,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (appState.latestSyncMessage != null)
              Text(
                appState.latestSyncMessage!,
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceTestingCard(ThemeData theme, SeniSafeAppState appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('方言语音联动', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(_recognizedVoiceBanner, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                appState.voiceService.dispatchMockRecognition('这个药咋个吃');
              },
              icon: const Icon(Icons.mic_none_rounded, size: 32),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('模拟四川话识别'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewChineseScanFrame extends StatelessWidget {
  const _NewChineseScanFrame();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: SeniSafeTheme.warmApricot,
            width: 3,
          ),
          gradient: LinearGradient(
            colors: <Color>[
              Colors.white.withOpacity(0.05),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: const <Widget>[
            Positioned(top: 18, left: 18, child: _FrameCorner()),
            Positioned(top: 18, right: 18, child: _FrameCorner(isMirrored: true)),
            Positioned(bottom: 18, left: 18, child: _FrameCorner(isVerticalFlip: true)),
            Positioned(
              bottom: 18,
              right: 18,
              child: _FrameCorner(isMirrored: true, isVerticalFlip: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrameCorner extends StatelessWidget {
  const _FrameCorner({
    this.isMirrored = false,
    this.isVerticalFlip = false,
  });

  final bool isMirrored;
  final bool isVerticalFlip;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(
        isMirrored ? -1 : 1,
        isVerticalFlip ? -1 : 1,
        1,
      ),
      child: SizedBox(
        width: 56,
        height: 56,
        child: CustomPaint(
          painter: _FrameCornerPainter(),
        ),
      ),
    );
  }
}

class _FrameCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = SeniSafeTheme.warmApricot
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path()
      ..moveTo(0, size.height * 0.45)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.45, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VoiceCoachBall extends StatelessWidget {
  const _VoiceCoachBall({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: <Color>[
                  SeniSafeTheme.warmApricot,
                  SeniSafeTheme.pineGreen,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.record_voice_over_outlined,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: SeniSafeTheme.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultInfoTile extends StatelessWidget {
  const _ResultInfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SeniSafeTheme.pineGreen.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: SeniSafeTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConflictOverlay extends StatelessWidget {
  const _ConflictOverlay({
    required this.warning,
    required this.onDismiss,
  });

  final MedicationConflictWarning warning;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ColoredBox(
      color: const Color(0xAA1A1A1A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xE6C86A1E),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: SeniSafeTheme.warmApricot,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '注意用药冲突',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontSize: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  warning.summary,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  warning.detail,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '冲突药物：${warning.interactingMedication}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onDismiss,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: SeniSafeTheme.warningOrange,
                  ),
                  child: const Text('我知道了，先咨询医生'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
