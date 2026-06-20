# 社保退休计算器

一款跨平台（Android / iOS）的中国社保和退休金计算 APP。

## 功能

- 🎯 **退休年龄计算**：输入出生年月和性别，根据2025年渐进式延迟退休政策计算实际退休时间
- 💰 **养老金估算**：根据缴费基数、缴费年限、所在省份，计算预估月养老金
- 📊 **社保缴费明细**：展示个人和单位各项社保缴费明细
- 🗺️ **覆盖全国**：内置 15+ 省市社保数据和计发基数
- 📱 **跨平台**：Flutter 开发，一份代码同时发布 Android 和 iOS

## 技术栈

- **框架**：Flutter 3.x（Dart）
- **状态管理**：Provider
- **数据存储**：本地 JSON（离线可用）
- **UI**：Material 3 Design

## 快速开始

```bash
# 1. 安装 Flutter SDK（3.2+）
# https://flutter.dev/docs/get-started/install

# 2. 克隆项目
git clone https://github.com/xyf05411/social_pension_app.git
cd social_pension_app

# 3. 安装依赖
flutter pub get

# 4. 运行
flutter run           # 连接设备运行
flutter build apk     # 打包 Android APK
flutter build ios     # 打包 iOS（需 macOS + Xcode）
```

## 项目结构

```
lib/
├── main.dart                 # 入口和导航
├── models/
│   └── models.dart           # 数据模型（ProvinceData, UserInput, 结果模型）
├── services/
│   └── pension_calculator.dart  # 核心计算引擎
├── screens/
│   ├── input_screen.dart     # 输入页面
│   └── result_screen.dart    # 结果展示页面
assets/
└── data/
    └── provinces.json        # 各省社保数据
```

## 计算公式

### 退休年龄
- 男职工：原60岁 → 逐步延至63岁（每4月+1月）
- 女职工(工人)：原50岁 → 逐步延至55岁（每2月+1月）
- 女干部/灵活就业：原55岁 → 逐步延至58岁（每4月+1月）

### 养老金
```
基础养老金 = (全省计发基数 + 本人指数化月平均工资) ÷ 2 × 缴费年限 × 1%
个人账户养老金 = 个人账户储存额 ÷ 计发月数
月养老金 = 基础养老金 + 个人账户养老金
```

## 免责声明

本应用计算结果为估算值，实际退休年龄和养老金以当地社保经办机构核定为准。

## 上架 Google Play

1. 注册 [Google Play Console](https://play.google.com/console/) 开发者账号（$25 一次性）
2. 运行 `flutter build appbundle` 生成 AAB 文件
3. 在 Play Console 创建应用 → 上传 AAB → 填写商店信息 → 提交审核

## 上架 App Store

1. 注册 [Apple Developer Program](https://developer.apple.com/)（$99/年）
2. macOS + Xcode 中打开 `ios/Runner.xcworkspace`
3. 配置签名证书 → Archive → 上传到 App Store Connect
4. 在 App Store Connect 填写元数据和截图 → 提交审核

## 数据更新

`assets/data/provinces.json` 包含各省社保参数。新政策发布后可更新此文件：

- `pension_base_2025`：各省养老金计发基数
- `social_insurance`：各项社保费率
- `min_base_2025` / `max_base_2025`：缴费基数上下限

## License

MIT