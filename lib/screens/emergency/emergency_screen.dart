import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/emergency_packet.dart';
import '../../state/senisafe_app_state.dart';
import '../../theme/senisafe_theme.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathingController;
  StreamSubscription? _voiceRecognitionSubscription;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
      lowerBound: 0.94,
      upperBound: 1.04,
    )..repeat(reverse: true);
    _bindVoiceTrigger();
  }

  void _bindVoiceTrigger() {
    final SeniSafeAppState appState = context.read<SeniSafeAppState>();
    _voiceRecognitionSubscription =
        appState.voiceService.recognitionStream.listen((event) {
      if (event.rawText.contains('救命') || event.rawText.contains('快来救我')) {
        appState.triggerEmergencyPacket(fromVoice: true);
      }
    });
  }

  @override
  void dispose() {
    _voiceRecognitionSubscription?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SeniSafeAppState appState = context.watch<SeniSafeAppState>();
    final EmergencyPacketCard? packet = appState.activeEmergencyCard;

    return SafeArea(
      child: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                <Widget>[
                  Text('智慧急救', style: theme.textTheme.displayMedium),
                  const SizedBox(height: 12),
                  Text(
                    '紧急时只保留一个大按钮，也支持直接喊“救命”，系统会马上准备数字化急救名片。',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: SeniSafeTheme.sectionSpacing),
                  if (appState.apiService.baseUrlReminder != null)
                    _NetworkReminderCard(
                      message: appState.apiService.baseUrlReminder!,
                    ),
                  if (appState.apiService.baseUrlReminder != null)
                    const SizedBox(height: SeniSafeTheme.sectionSpacing),
                  _VoiceWakeupCard(
                    onSimulateHelp: () {
                      HapticFeedback.selectionClick();
                      context
                          .read<SeniSafeAppState>()
                          .voiceService
                          .dispatchMockRecognition('救命');
                    },
                  ),
                  const SizedBox(height: SeniSafeTheme.sectionSpacing),
                  _SosHeroButton(
                    controller: _breathingController,
                    isLoading: appState.isLoadingEmergencyCard,
                    onPressed: () async {
                      await HapticFeedback.vibrate();
                      if (context.mounted) {
                        await context
                            .read<SeniSafeAppState>()
                            .triggerEmergencyPacket();
                      }
                    },
                  ),
                  const SizedBox(height: SeniSafeTheme.sectionSpacing),
                  if (appState.emergencyErrorMessage != null)
                    _ErrorNotice(message: appState.emergencyErrorMessage!),
                  if (appState.emergencyErrorMessage != null)
                    const SizedBox(height: SeniSafeTheme.sectionSpacing),
                  if (appState.isLoadingEmergencyCard)
                    const _EmergencyLoadingCard(),
                  if (!appState.isLoadingEmergencyCard && packet != null)
                    _EmergencyCardPanel(packet: packet),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SosHeroButton extends StatelessWidget {
  const _SosHeroButton({
    required this.controller,
    required this.isLoading,
    required this.onPressed,
  });

  final AnimationController controller;
  final bool isLoading;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double size = MediaQuery.sizeOf(context).width * 0.5;

    return Center(
      child: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return Transform.scale(
            scale: controller.value,
            child: child,
          );
        },
        child: GestureDetector(
          onTap: isLoading ? null : onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  Color(0xFFE56756),
                  SeniSafeTheme.emergencyRed,
                ],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Color(0x40B63A2B),
                  blurRadius: 40,
                  spreadRadius: 8,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const SizedBox(
                          width: 56,
                          height: 56,
                          child: CircularProgressIndicator(
                            strokeWidth: 5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '正在呼叫',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'SOS',
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '点按立即展示\n数字急救名片',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.92),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmergencyLoadingCard extends StatelessWidget {
  const _EmergencyLoadingCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Row(
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: SeniSafeTheme.warmApricot.withOpacity(0.32),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: SeniSafeTheme.pineGreen,
                  strokeWidth: 5,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                '正在整理老人头像、血型、过敏史和最近 24 小时服药记录，请稍候。',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: SeniSafeTheme.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyCardPanel extends StatelessWidget {
  const _EmergencyCardPanel({
    required this.packet,
  });

  final EmergencyPacketCard packet;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: packet.hasHighRiskNotice
                    ? SeniSafeTheme.emergencyRed
                    : SeniSafeTheme.pineGreen,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Text(
                packet.riskNotice,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _AvatarBadge(name: packet.patientName),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${packet.patientName}  ${packet.age} 岁',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '血型：${packet.bloodType}',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        packet.summary,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _InfoStrip(
              title: '过敏史',
              content: packet.allergies.isEmpty ? '暂无记录' : packet.allergies.join('、'),
            ),
            const SizedBox(height: 16),
            _InfoStrip(
              title: '慢病信息',
              content: packet.chronicConditions.isEmpty
                  ? '暂无记录'
                  : packet.chronicConditions.join('、'),
            ),
            const SizedBox(height: 16),
            _InfoStrip(
              title: '当前用药',
              content: packet.currentMedicationState.join('、'),
            ),
            const SizedBox(height: 24),
            Text('最近 24 小时服药记录', style: theme.textTheme.labelLarge),
            const SizedBox(height: 14),
            ...packet.recentIntakeRecords.map(
              (EmergencyIntakeRecord record) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: SeniSafeTheme.mistWhite,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(record.medicationName, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text(
                        '${record.dosage}  ·  ${record.confirmedAt.toLocal()}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({
    required this.name,
  });

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[
            SeniSafeTheme.warmApricot,
            SeniSafeTheme.pineGreen,
          ],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1) : '颐',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontSize: 34,
              ),
        ),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SeniSafeTheme.pineGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyLarge?.copyWith(color: SeniSafeTheme.ink),
          children: <InlineSpan>[
            TextSpan(
              text: '$title：',
              style: theme.textTheme.labelLarge?.copyWith(
                color: SeniSafeTheme.pineGreen,
              ),
            ),
            TextSpan(text: content),
          ],
        ),
      ),
    );
  }
}

class _VoiceWakeupCard extends StatelessWidget {
  const _VoiceWakeupCard({
    required this.onSimulateHelp,
  });

  final VoidCallback onSimulateHelp;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('语音唤醒', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '如果长者说出“救命”，系统会自动请求急救名片并弹出展示。',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onSimulateHelp,
              icon: const Icon(Icons.campaign_outlined, size: 32),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('模拟语音“救命”'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkReminderCard extends StatelessWidget {
  const _NetworkReminderCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SeniSafeTheme.warningOrange.withOpacity(0.16),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: SeniSafeTheme.ink,
        ),
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SeniSafeTheme.emergencyRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: SeniSafeTheme.emergencyRed,
        ),
      ),
    );
  }
}
