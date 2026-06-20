import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/pension_calculator.dart';
import 'result_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();

  // 表单字段
  DateTime _birthDate = DateTime(1990, 1, 1);
  Gender _gender = Gender.male;
  WorkerType _workerType = WorkerType.worker;
  String _province = '';
  final _salaryController = TextEditingController(text: '8000');
  final _yearsController = TextEditingController(text: '0');
  final _balanceController = TextEditingController(text: '0');

  // Province picker state
  List<String> _provinces = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final calculator = context.read<AppState>().calculator;
      setState(() {
        _provinces = calculator.provinceNames;
        if (_provinces.isNotEmpty) _province = _provinces.first;
      });
    });
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _yearsController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final input = UserInput(
      birthDate: _birthDate,
      gender: _gender,
      workerType: _workerType,
      province: _province,
      monthlySalary: double.tryParse(_salaryController.text) ?? 8000,
      yearsContributed: int.tryParse(_yearsController.text) ?? 0,
      personalAccountBalance:
          double.tryParse(_balanceController.text) ?? 0,
    );

    final calculator = context.read<AppState>().calculator;

    try {
      final retirement = calculator.calcRetirement(input);
      final pension = calculator.calcPension(input, retirement);
      final socialInsurance = calculator.calcSocialInsurance(input);

      // 如果结果页已加载则更新数据，否则导航
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultDetailScreen(
            userInput: input,
            retirement: retirement,
            pension: pension,
            socialInsurance: socialInsurance,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('计算错误: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('社保退休计算器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate),
            tooltip: '开始计算',
            onPressed: _calculate,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ============ 基本信息 ============
            _sectionTitle('👤 基本信息'),

            // 出生日期
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('出生日期'),
                subtitle: Text(
                  '${_birthDate.year}年${_birthDate.month}月${_birthDate.day}日',
                ),
                trailing: const Icon(Icons.edit),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 8),

            // 性别
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('性别', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SegmentedButton<Gender>(
                      segments: const [
                        ButtonSegment(value: Gender.male, label: Text('男')),
                        ButtonSegment(value: Gender.female, label: Text('女')),
                      ],
                      selected: {_gender},
                      onSelectionChanged: (v) =>
                          setState(() => _gender = v.first),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 职工类型（仅女性显示）
            if (_gender == Gender.female)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('职工类型（影响退休年龄）',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text('女工人原50岁退 / 女干部和灵活就业女性原55岁退',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      SegmentedButton<WorkerType>(
                        segments: const [
                          ButtonSegment(
                              value: WorkerType.worker, label: Text('工人')),
                          ButtonSegment(
                              value: WorkerType.cadre, label: Text('干部')),
                          ButtonSegment(
                              value: WorkerType.flexible,
                              label: Text('灵活就业')),
                        ],
                        selected: {_workerType},
                        onSelectionChanged: (v) =>
                            setState(() => _workerType = v.first),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),
            _sectionTitle('📍 社保信息'),

            // 省份选择
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('参保省份'),
                subtitle: Text(_province),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: _pickProvince,
              ),
            ),
            const SizedBox(height: 8),

            // 月缴费基数
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('月缴费基数（工资）', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text('一般为上年度月平均工资，需在各地上下限范围内',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _salaryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixText: '¥ ',
                        suffixText: '元/月',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return '请输入缴费基数';
                        final n = double.tryParse(v);
                        if (n == null || n <= 0) return '请输入有效金额';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 已缴费年限
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('已缴费年限', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _yearsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        suffixText: '年',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return '请输入已缴费年限';
                        final n = int.tryParse(v);
                        if (n == null || n < 0 || n > 45) {
                          return '请输入0-45之间的有效年限';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 个人账户余额
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('个人账户余额', style: theme.textTheme.titleSmall),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: '可在支付宝/各地人社APP中查询\n如不清楚可填0',
                          child: Icon(Icons.help_outline, size: 16,
                              color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _balanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixText: '¥ ',
                        suffixText: '元',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return '请输入个人账户余额';
                        final n = double.tryParse(v);
                        if (n == null || n < 0) return '请输入有效金额';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 计算按钮
            FilledButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate, size: 28),
              label: const Text('开始计算', style: TextStyle(fontSize: 18)),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(2010),
      helpText: '选择出生日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  void _pickProvince() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('选择参保省份',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          ..._provinces.map((p) => ListTile(
                title: Text(p),
                selected: p == _province,
                onTap: () {
                  setState(() => _province = p);
                  Navigator.pop(ctx);
                },
              )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}