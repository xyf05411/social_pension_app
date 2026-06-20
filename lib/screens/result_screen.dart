import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class ResultDetailScreen extends StatelessWidget {
  final UserInput userInput;
  final RetirementResult retirement;
  final PensionResult pension;
  final SocialInsuranceResult socialInsurance;

  const ResultDetailScreen({
    super.key,
    required this.userInput,
    required this.retirement,
    required this.pension,
    required this.socialInsurance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(
        title: const Text('计算结果'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ============ 退休信息卡片 ============
          _sectionTitle('🎯 退休时间'),
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 退休年龄大数字
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('${retirement.retirementAgeYears}',
                          style: theme.textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer)),
                      Text('岁',
                          style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer)),
                      if (retirement.retirementAgeMonths > 0) ...[
                        const SizedBox(width: 4),
                        Text('${retirement.retirementAgeMonths}个月',
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('预计退休日期',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onPrimaryContainer.withAlpha(180))),
                  Text(
                    DateFormat('yyyy年MM月dd日').format(retirement.retirementDate),
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (retirement.monthsRemaining > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '还要工作 ${retirement.remainingDisplay}',
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('🎉 已到退休年龄！',
                          style: TextStyle(color: Colors.green)),
                    ),
                ],
              ),
            ),
          ),

          // 政策说明
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(retirement.policyNote,
                        style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ============ 养老金卡片 ============
          _sectionTitle('💰 预估月养老金'),
          Card(
            color: theme.colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(fmt.format(pension.totalMonthlyPension),
                          style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  theme.colorScheme.onTertiaryContainer)),
                      Text(' 元/月',
                          style: theme.textTheme.titleLarge?.copyWith(
                              color:
                                  theme.colorScheme.onTertiaryContainer)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('约 ${fmt.format(pension.annualPension)} 元/年',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer
                              .withAlpha(180))),
                  const Divider(height: 24),

                  // 养老金构成
                  _pensionRow(context, '基础养老金', pension.basePension, '占比约${(pension.basePension / pension.totalMonthlyPension * 100).toStringAsFixed(0)}%', fmt),
                  _pensionRow(context, '个人账户养老金', pension.personalPension, '个人账户÷计发月数', fmt),
                  const SizedBox(height: 12),

                  // 关键参数
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withAlpha(100),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _paramRow(context, '当地计发基数',
                            '${fmt.format(pension.provinceBase)} 元'),
                        _paramRow(context, '指数化月平均工资',
                            '${fmt.format(pension.indexedSalary)} 元'),
                        _paramRow(context, '最终缴费年限',
                            '${pension.finalYears} 年'),
                        _paramRow(context, '退休时个人账户余额',
                            '${fmt.format(pension.finalAccountBalance)} 元'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ============ 社保月缴费 ============
          _sectionTitle('📊 当前每月社保缴费'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _insuranceRow(
                      context, '个人缴纳', socialInsurance.personalPayment,
                      Colors.red),
                  const SizedBox(height: 4),
                  _insuranceRow(
                      context, '单位缴纳', socialInsurance.companyPayment,
                      Colors.blue),
                  const Divider(),
                  _insuranceRow(
                      context, '合计', socialInsurance.totalPayment,
                      Colors.green, bold: true),
                  const SizedBox(height: 12),

                  // 明细
                  ...socialInsurance.detail.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key,
                                style: theme.textTheme.bodySmall),
                            Text(fmt.format(e.value),
                                style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 免责声明
          Card(
            color: theme.colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined, size: 18,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('以上为估算结果，实际以当地社保经办机构核定为准',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _pensionRow(BuildContext context, String label, double amount,
      String sub, NumberFormat fmt) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              Text(sub, style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          Text('${fmt.format(amount)} 元',
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _insuranceRow(BuildContext context, String label, double amount,
      Color color,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text('${NumberFormat('#,##0.00').format(amount)} 元/月',
            style: TextStyle(fontSize: bold ? 18 : 15,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                color: color)),
      ],
    );
  }

  Widget _paramRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodySmall),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w500)),
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