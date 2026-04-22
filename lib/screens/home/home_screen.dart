import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/medication.dart';
import '../../state/senisafe_app_state.dart';
import '../../theme/senisafe_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SeniSafeAppState appState = context.watch<SeniSafeAppState>();

    return SafeArea(
      child: Stack(
        children: <Widget>[
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 220),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('您好，${appState.currentUser.name}', style: theme.textTheme.displayMedium),
                const SizedBox(height: 12),
                Text(
                  '今天也由颐安陪您稳稳当当过一天。',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: SeniSafeTheme.sectionSpacing),
                const _HealthStatusCard(),
                const SizedBox(height: SeniSafeTheme.sectionSpacing),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        AppStrings.todayMedicationTitle,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: SeniSafeTheme.warmApricot,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        AppStrings.pendingMedicationCount(
                          appState.pendingMedicationCount,
                        ),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: SeniSafeTheme.pineGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...appState.todayMedications.map(
                  (Medication medication) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _MedicationCard(medication: medication),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: _VoiceAssistantBall(),
          ),
        ],
      ),
    );
  }
}

class _HealthStatusCard extends StatelessWidget {
  const _HealthStatusCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            SeniSafeTheme.pineGreen,
            SeniSafeTheme.pineGreenDeep,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(SeniSafeTheme.largeRadius),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1A2D5A27),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              AppStrings.healthStatusTitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.healthStatusStable,
              style: theme.textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontSize: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.healthStatusDetail,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.92),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const <Widget>[
                _MetricBadge(label: '血压 128/78', icon: Icons.favorite_outline),
                _MetricBadge(label: '血氧 98%', icon: Icons.monitor_heart_outlined),
                _MetricBadge(label: '步态稳定', icon: Icons.accessibility_new_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: SeniSafeTheme.warmApricot, size: 24),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.medication,
  });

  final Medication medication;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SeniSafeAppState appState = context.read<SeniSafeAppState>();
    final bool isConfirmed =
        medication.intakeState == MedicationIntakeState.confirmed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(medication.name, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 10),
                      Text(medication.dosage, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.medicationSchedule(medication.scheduleLabel),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isConfirmed
                        ? SeniSafeTheme.pineGreen.withOpacity(0.12)
                        : SeniSafeTheme.warmApricot.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isConfirmed ? '已确认' : '待服药',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: SeniSafeTheme.pineGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(medication.instructions, style: theme.textTheme.bodyMedium),
            if (medication.conflict != null) ...<Widget>[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: SeniSafeTheme.warningOrange.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      medication.conflict!.summary,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: SeniSafeTheme.warningOrange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      medication.conflict!.detail,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: SeniSafeTheme.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            GestureDetector(
              onLongPress: isConfirmed
                  ? null
                  : () async {
                      // 长按确认可以减少误触，适合手部稳定性较弱的长者。
                      await appState.confirmMedicationByFace(medication.id);
                    },
              onTap: isConfirmed
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('请长按按钮进行扫脸确认，避免误触。'),
                        ),
                      );
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: double.infinity,
                height: SeniSafeTheme.interactiveMinHeight + 8,
                decoration: BoxDecoration(
                  color: isConfirmed
                      ? SeniSafeTheme.pineGreen.withOpacity(0.18)
                      : SeniSafeTheme.pineGreen,
                  borderRadius:
                      BorderRadius.circular(SeniSafeTheme.largeRadius),
                  boxShadow: isConfirmed
                      ? const <BoxShadow>[]
                      : const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x262D5A27),
                            blurRadius: 18,
                            offset: Offset(0, 10),
                          ),
                        ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.face_retouching_natural,
                        size: 32,
                        color: isConfirmed
                            ? SeniSafeTheme.pineGreen
                            : Colors.white,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        isConfirmed ? '本次服药已确认' : AppStrings.faceScanAction,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isConfirmed
                              ? SeniSafeTheme.pineGreen
                              : Colors.white,
                        ),
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

class _VoiceAssistantBall extends StatelessWidget {
  const _VoiceAssistantBall();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SeniSafeAppState appState = context.watch<SeniSafeAppState>();

    return GestureDetector(
      onTap: () async {
        await context.read<SeniSafeAppState>().toggleVoiceAssistant();
      },
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 28,
              offset: Offset(0, 16),
            ),
          ],
          border: Border.all(
            color: SeniSafeTheme.pineGreen.withOpacity(0.08),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: appState.isVoiceAssistantActive
                      ? const <Color>[
                          SeniSafeTheme.warmApricot,
                          SeniSafeTheme.pineGreen,
                        ]
                      : const <Color>[
                          Color(0xFFE9F1E7),
                          Color(0xFFC7D8C3),
                        ],
                ),
              ),
              child: const Icon(
                Icons.graphic_eq_rounded,
                size: 42,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppStrings.voiceBallHint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: SeniSafeTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appState.isVoiceAssistantActive
                        ? '正在聆听中，请直接说出身体感受或需求。'
                        : AppStrings.voiceBallFootnote,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
