# <div align="center">🪴 Project Logo Placeholder</div>

<div align="center">

# 颐安 · SeniSafe

### 用科技的精度，守住老龄化社会里最柔软的日常

**一个融合“智能服药管理”与“AI 智慧急救”的适老化健康守护系统**  
**A warm digital care solution for medication safety, emergency response, and dignified aging**

</div>

---

## ✨ 项目简介

在独居老人真实生活场景中，风险往往不是来自某一个“重大疾病瞬间”，而是来自很多看似普通的小问题叠加：

- 药盒字体太小，看不清药名和剂量
- 普通话提醒听不太懂，方言交流却更自然
- 临时身体不适时，说不清自己刚吃过什么药
- 急救人员到场后，第一时间拿不到完整、可信、可操作的健康信息

**颐安（SeniSafe）** 的设计目标，不是再做一个功能堆叠的养老 App，而是建立一个真正围绕老人生活节奏运行的 **“预防 - 识别 - 响应 - 共享”数据闭环**。

它把两件最关键的事无缝连接起来：

- **日常服药管理**
- **突发急救协同**

让“平时的每一次服药记录”，都在关键时刻变成可被急救直接消费的生命信息。

---

## ❤️ 我们在解决什么问题？

### 1. 看不清
老人面对药盒、说明书和复杂剂量信息时，极易误服、漏服、重复服药。

### 2. 听不懂
很多长者更习惯粤语、川话等方言，标准普通话提醒未必是最有效的沟通方式。

### 3. 来不及说
一旦出现头晕、跌倒、胸闷等急症，老人往往没有能力完整表达“自己是谁、吃了什么药、什么药不能碰”。

### 4. 信息断层
传统养老 App 往往只做提醒、只做记录、或只做呼救，**服药数据与急救数据彼此割裂**，无法形成真正有价值的医疗协同。

---

## 🚀 核心亮点

### 🛡️ 智慧预防

- **OCR 药盒识别**：拍摄药盒，自动识别药品名称、剂量与用法用量
- **药物冲突预警**：例如识别出 `阿司匹林 + 华法林` 的高风险组合，及时触发深橙色警告卡片与震动提醒
- **方言语音助手**：预留 **Fun-ASR 1.5** WebSocket 流式接口，支持将粤语、川话等方言语句解析为系统指令
- **适老化交互**：大字号、大点击区、长按防误触、强触觉反馈

### 🚨 瞬间响应

- **一键 / 语音 SOS**：点按 SOS 或直接说“救命”，立即触发应急流程
- **数字化急救名片**：自动聚合最近 24 小时服药记录、血型、过敏史、慢病信息
- **高风险药物提示**：若存在抗凝药、冲突药物等风险信息，急救页顶部直接高亮提醒
- **AR 急救指导预留**：基于 **MediaPipe** 的 CPR 姿态检测与动作纠偏接口已纳入架构规划

### 🎨 视觉哲学

- **新中式极简（Premium Senior-Care）**
- 主色采用 `长寿松青 #2D5A27`
- 背景采用 `柔光灰白 #F5F5F5`
- 避免“廉价大字版”，强调高级感、留白感与弱视友好对比度

---

## 🧠 为什么选择颐安？

| 对比维度 | 传统养老 App | 颐安 SeniSafe |
| --- | --- | --- |
| 功能组织方式 | 服药、呼救、健康档案相互割裂 | 以“服药到急救”的完整数据闭环为核心 |
| 服药录入 | 以手动录入为主，门槛高 | OCR 药盒识别 + 风险校验，降低录入负担 |
| 冲突风险感知 | 多数没有即时药物冲突检查 | 内置 DDI 风险规则，可即时提示高风险组合 |
| 语音能力 | 普通话口令为主 | 支持方言语义入口，预留 Fun-ASR 1.5 WebSocket 流式接入 |
| 急救协同 | 仅有 SOS 按钮，信息不足 | 自动生成“数字化急救名片”，打包 24h 服药史 |
| 医疗上下文 | 急救时信息不连续 | 从日常用药直接衔接到应急共享 |
| 适老化设计 | 常见按钮偏小、反馈弱 | 80dp+ 点击区域、长按防误触、触觉反馈、阶梯式大字号 |
| 产品价值 | 工具型提醒 | 面向老龄社会的数字化温情方案 |

---

## 🖼️ 核心功能演示

### 1. 药盒助手：从“看不清”到“看得懂”

- 打开药盒助手
- 调用摄像头拍摄药盒
- 展示新中式扫描框
- 上传识别结果并返回药品信息
- 若发现冲突风险，立即弹出高对比度预警卡片并播报提醒

### 2. 方言语音助手：从“听不懂”到“能沟通”

示例：

- “这个药咋个吃”
- “帮我录入新药”
- “救命”

系统会将方言文本经由 **DialectIntentParser** 映射为结构化意图，并驱动对应 UI 行为。

### 3. 智慧急救：从“喊人”到“给信息”

- 触发 SOS
- 请求急救数据包
- 展示数字化急救名片
- 顶部优先展示高风险药物提示
- 输出血型、过敏史、慢病信息、最近 24 小时服药记录

---

## 🏗️ 技术架构

### 前端

- **Flutter**
- **Provider** 进行全局状态管理
- **camera** 用于药盒拍摄与实时预览
- **http** 用于与 FastAPI 通信

### 后端

- **FastAPI**
- **Pydantic**
- **Uvicorn**
- JSON 持久化存储（当前开发阶段）

### 语音层

- **Fun-ASR 1.5**
- 预留 **WebSocket** 流式连接池
- 方言文本转意图解析器 `DialectIntentParser`

### 视觉 / 感知层

- OCR 药盒识别逻辑骨架
- **MediaPipe** 姿态检测接口预留，用于 CPR / AR 急救指导

---

## 📦 当前项目结构

```text
Senisafe/
├─ lib/
│  ├─ models/
│  ├─ screens/
│  ├─ services/
│  ├─ state/
│  └─ theme/
├─ backend/
│  ├─ app/
│  │  ├─ models/
│  │  ├─ routers/
│  │  └─ services/
│  ├─ data/
│  └─ requirements.txt
├─ pubspec.yaml
└─ README.md
```

---

## ⚡ 快速启动

### 1. 启动后端

```bash
cd backend
python -m venv .venv
```

Windows:

```bash
.venv\Scripts\activate
```

macOS / Linux:

```bash
source .venv/bin/activate
```

安装依赖：

```bash
pip install -r requirements.txt
```

启动服务：

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 2. 启动前端

```bash
flutter pub get
flutter run
```

---

## 🧪 开发者指南

### 后端镜像源配置

如果你的网络环境下载 PyPI 较慢，可使用国内镜像源：

临时使用：

```bash
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple -r requirements.txt
```

永久配置：

Windows:

```bash
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
```

macOS / Linux:

```bash
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
```

### 前端环境配置

请先确保本地具备以下环境：

- Flutter SDK
- Dart SDK
- Android Studio / Android SDK
- 至少一个 Android 模拟器或真机

建议先执行：

```bash
flutter doctor
flutter pub get
flutter analyze
```

### API 地址说明

当前 Flutter 默认后端地址为：

```text
http://10.0.2.2:8000
```

这是 Android 模拟器访问本机服务的回环地址。  
如果你使用：

- Windows 桌面端
- iOS 模拟器
- 真机调试

请将前端 API Base URL 改为你电脑的局域网 IP。

---

## 🧭 已实现能力

### 前端

- 全局主题与适老化设计系统
- 守护中心首页骨架
- 药盒助手扫描流程 Mock
- 药物冲突预警 UI
- SOS 急救页与数字化急救名片展示

### 后端

- `POST /medication/recognize`
- `POST /medication/confirm`
- `POST /emergency/prepare_packet`
- `GET /emergency/packet/{user_id}`
- JSON 持久化用户画像与服药记录

---

## 🛣️ 未来路线图

### Phase 1. 真实识别能力

- 将 Mock OCR 升级为真实图像识别链路
- 将药盒识别从 Base64 迁移为 `UploadFile` 文件上传
- 增加药品数据库匹配与标准化字段映射

### Phase 2. 方言与语音闭环

- 接入 **Fun-ASR 1.5** 实时流式识别
- 建立多方言词典与意图映射规则
- 增加温暖型语音播报模板与家庭成员通知机制

### Phase 3. 急救增强

- 接入 **MediaPipe** CPR / 姿态指导
- 增加跌倒检测与异常姿态识别
- 支持一键共享给社区医生、急救中心、家属联系人

### Phase 4. 数据可信与产品化

- 引入数据库持久化与权限控制
- 完善日志、审计、监控和告警
- 支持医院 / 养老机构场景下的多角色协同

---

## 🌏 产品愿景

我们相信，真正面向老龄化社会的数字产品，不应该只是“把按钮做大一点”。

它应该：

- 理解老人真实的语言习惯
- 尊重老人使用手机时的身体条件
- 在平时积累有价值的数据
- 在关键时刻把这些数据变成能救命的信息

**颐安（SeniSafe）** 想做的，正是这样一套有技术深度、也有情感温度的数字照护方案。

---

## 🤝 致开发者

如果你关注：

- Aging Tech
- Digital Health
- AI for Care
- Human-Centered Design

欢迎一起把这个项目打磨成真正能落地的解决方案。

> 老龄化不是未来的问题，它已经是现在的命题。  
> 我们希望，技术在这里不是冰冷的效率工具，而是一种更体面的陪伴。

