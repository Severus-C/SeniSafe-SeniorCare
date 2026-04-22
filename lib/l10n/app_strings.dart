class AppStrings {
  static const appTitle = '颐安 SeniSafe';

  static const homeTab = '守护中心';
  static const medicationTab = '药盒助手';
  static const emergencyTab = '智慧急救';

  static const healthStatusTitle = '当前健康状态';
  static const healthStatusStable = '状态平稳，可安心安排今日服药';
  static const healthStatusDetail = '心率、血氧与服药提醒均在正常范围内。';
  static const todayMedicationTitle = '今日服药列表';
  static const faceScanAction = '长按扫脸确认服药';
  static const voiceBallHint = '您可以对我说：\n“我脚麻了” 或 “帮我录入新药”';
  static const voiceBallFootnote = '支持粤语、川话等方言流式识别';

  static const medicationCaptureTitle = '拍药盒';
  static const medicationCaptureSubtitle = '对准药盒正面，系统将自动识别药品信息';
  static const ocrResultTitle = 'OCR 识别结果预留区';
  static const warningBlockTitle = '禁忌症预警';

  static const emergencyTitle = '长按 SOS';
  static const emergencySubtitle = '触发震动反馈，并预备进入 AR 指导模式';
  static const emergencyFootnote = '已预留 MediaPipe 姿态检测与健康档案打包接口';

  static String pendingMedicationCount(int count) => '待确认 $count 项';
  static String medicationSchedule(String schedule) => '服药时间：$schedule';
}
