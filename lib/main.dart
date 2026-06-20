import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/pension_calculator.dart';
import 'screens/input_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const PensionApp(),
    ),
  );
}

class AppState extends ChangeNotifier {
  final PensionCalculator calculator = PensionCalculator();
  bool _loading = true;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;
  bool get ready => !_loading && _error == null;

  Future<void> init() async {
    try {
      await calculator.loadData();
      _loading = false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
    }
    notifyListeners();
  }
}

class PensionApp extends StatelessWidget {
  const PensionApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化数据
    final appState = context.read<AppState>();
    if (appState.loading && !appState.ready) {
      appState.init();
    }

    return MaterialApp(
      title: '社保退休计算器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'PingFang SC',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (appState.loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('加载各省社保数据...',
                  style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    if (appState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('数据加载失败', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(appState.error!, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => appState.init(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    final screens = [
      const InputScreen(),
      const ResultScreen(),
      const InfoScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: '计算',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: '结果',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: '说明',
          ),
        ],
      ),
    );
  }
}

// 占位 Screen（结果页和说明页实际在 InputScreen 完成后才显示）
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('计算结果')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 64,
                color: Theme.of(context).colorScheme.primary.withAlpha(100)),
            const SizedBox(height: 16),
            Text('请先在「计算」页面填写信息',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('输入完成后点击「开始计算」按钮',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('计算说明')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(context, '📋 退休年龄计算',
                '根据2025年1月1日起施行的渐进式延迟退休政策：\n'
                    '• 男职工：原60岁 → 逐步延迟至63岁（每4个月延迟1个月）\n'
                    '• 女职工(工人)：原50岁 → 逐步延迟至55岁（每2个月延迟1个月）\n'
                    '• 女干部/灵活就业女性：原55岁 → 逐步延迟至58岁（每4个月延迟1个月）'),
            const SizedBox(height: 12),
            _buildSection(context, '💰 养老金计算',
                '基础养老金 = (全省计发基数 + 本人指数化月平均工资) ÷ 2 × 缴费年限 × 1%\n\n'
                    '个人账户养老金 = 个人账户储存额 ÷ 计发月数\n\n'
                    '月养老金 = 基础养老金 + 个人账户养老金'),
            const SizedBox(height: 12),
            _buildSection(context, '📊 数据来源',
                '• 各省计发基数来自各省人社厅公开数据\n'
                    '• 社保费率依据各省现行规定\n'
                    '• 计发月数表依据国发〔2005〕38号文件\n'
                    '• 计算结果仅供参考，实际以当地社保经办机构核定为准'),
            const SizedBox(height: 12),
            _buildSection(context, '⚠️ 免责声明',
                '本应用提供的所有计算结果均为估算值，不构成任何法律承诺。'
                    '实际退休年龄和养老金金额以当地人力资源和社会保障部门的最终核定为准。'),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(content, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}