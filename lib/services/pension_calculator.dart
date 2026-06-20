import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/models.dart';

/// 社保退休计算引擎
class PensionCalculator {
  Map<String, ProvinceData>? _provinces;
  bool _loaded = false;

  Future<void> loadData() async {
    if (_loaded) return;
    final jsonStr = await rootBundle.loadString('assets/data/provinces.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final provincesJson = data['provinces'] as Map<String, dynamic>;
    _provinces = provincesJson.map(
      (k, v) => MapEntry(k, ProvinceData.fromJson(k, v as Map<String, dynamic>)),
    );
    _loaded = true;
  }

  List<String> get provinceNames {
    if (_provinces == null) return [];
    return _provinces!.keys.toList()..sort();
  }

  ProvinceData? getProvince(String name) => _provinces?[name];

  // ==========================================
  // 退休年龄计算（2025年渐进式延迟退休）
  // ==========================================

  /// 计算实际退休年龄
  RetirementResult calcRetirement(UserInput input) {
    final originalRetireAge = _originalRetireAge(input.gender, input.workerType);
    final targetRetireAge = _targetRetireAge(input.gender, input.workerType);
    final delayMonthsPerStep =
        _delayMonthsPerStep(input.gender, input.workerType);
    final stepMonths = _stepMonths(input.gender, input.workerType);

    // 计算出生月份对应的延迟月数
    final int delayMonths = _calcDelayMonths(
      input.birthDate,
      originalRetireAge,
      delayMonthsPerStep,
      stepMonths,
      targetRetireAge,
    );

    // 实际退休年龄（月为单位）
    final int retireAgeMonths = originalRetireAge * 12 + delayMonths;
    final int retireAgeYears = retireAgeMonths ~/ 12;
    final int retireAgeRemainderMonths = retireAgeMonths % 12;

    // 退休日期
    final retirementDate = DateTime(
      input.birthDate.year + retireAgeYears,
      input.birthDate.month + retireAgeRemainderMonths,
      input.birthDate.day,
    );

    // 如果退休日跨月调整
    DateTime adjustedDate = retirementDate;
    if (retirementDate.month > 12) {
      adjustedDate = DateTime(
        retirementDate.year + 1,
        retirementDate.month - 12,
        retirementDate.day,
      );
    }

    final now = DateTime.now();
    final totalMonthsUntil =
        (adjustedDate.year - now.year) * 12 + (adjustedDate.month - now.month);

    String policyNote;
    if (delayMonths == 0) {
      policyNote = '按原法定退休年龄$originalRetireAge岁退休（不受延迟退休影响）';
    } else {
      policyNote =
          '根据渐进式延迟退休政策，您的退休年龄从$originalRetireAge岁延迟至${retireAgeYears}岁${retireAgeRemainderMonths > 0 ? '${retireAgeRemainderMonths}个月' : ''}';
    }

    return RetirementResult(
      retirementAgeYears: retireAgeYears,
      retirementAgeMonths: retireAgeRemainderMonths,
      retirementDate: adjustedDate,
      monthsRemaining: totalMonthsUntil > 0 ? totalMonthsUntil : 0,
      policyNote: policyNote,
    );
  }

  /// 原法定退休年龄
  int _originalRetireAge(Gender gender, WorkerType type) {
    if (gender == Gender.male) return 60;
    if (type == WorkerType.worker) return 50;
    return 55; // 女干部/灵活就业
  }

  /// 目标退休年龄
  int _targetRetireAge(Gender gender, WorkerType type) {
    if (gender == Gender.male) return 63;
    if (type == WorkerType.worker) return 55;
    return 58;
  }

  /// 每步延迟月数
  int _delayMonthsPerStep(Gender gender, WorkerType type) {
    if (gender == Gender.male) return 1;
    if (type == WorkerType.worker) return 1;
    return 1;
  }

  /// 每步间隔月数
  int _stepMonths(Gender gender, WorkerType type) {
    if (gender == Gender.male) return 4;
    if (type == WorkerType.worker) return 2;
    return 4;
  }

  /// 计算具体的延迟月数
  int _calcDelayMonths(
    DateTime birthDate,
    int originalAge,
    int delayPerStep,
    int stepMonths,
    int targetAge,
  ) {
    // 延迟退休从2025年1月1日开始
    final policyStart = DateTime(2025, 1, 1);

    // 计算该人如果按原年龄退休，会是什么时候
    final originalRetireDate = DateTime(
      birthDate.year + originalAge,
      birthDate.month,
      birthDate.day,
    );

    // 如果原退休日期在2024年12月31日之前，不受影响
    if (originalRetireDate.isBefore(policyStart)) return 0;

    // 从政策开始日期到原退休日期的月数
    final monthsAfterPolicy = (originalRetireDate.year - 2025) * 12 +
        (originalRetireDate.month - 1);

    if (monthsAfterPolicy <= 0) return 0;

    // 每 stepMonths 个月延迟 delayPerStep 个月
    int delayMonths = 0;
    int accumulated = 0;

    // 模拟逐步延迟
    DateTime current = DateTime(2025, 1, 1);
    final int maxDelayMonths = (targetAge - originalAge) * 12;

    while (accumulated < monthsAfterPolicy && delayMonths < maxDelayMonths) {
      delayMonths += delayPerStep;
      current = DateTime(current.year,
          current.month + stepMonths > 12 ? current.year + 1 : current.year,
          (current.month + stepMonths - 1) % 12 + 1,
          current.day);
      accumulated += stepMonths;

      if (delayMonths >= maxDelayMonths) break;
    }

    // 如果计算出的延迟超过了最大延迟，限制到目标年龄
    if (originalAge * 12 + delayMonths > targetAge * 12) {
      delayMonths = targetAge * 12 - originalAge * 12;
    }

    return delayMonths > 0 ? delayMonths : 0;
  }

  // ==========================================
  // 养老金计算
  // ==========================================

  /// 计算养老金（基础 + 个人账户）
  PensionResult calcPension(UserInput input, RetirementResult retirement) {
    final province = getProvince(input.province);
    if (province == null) throw Exception('省份数据未找到: ${input.province}');

    final pensionBase = province.pensionBase2025;

    // 本人指数化月平均工资 = 计发基数 × 本人平均缴费指数
    // 本人平均缴费指数 = 本人缴费基数 ÷ 当地平均工资
    // 简化：如果工资在 min/max 之间，直接用工资做基数
    double effectiveBase = input.monthlySalary;
    if (effectiveBase < province.minBase2025) effectiveBase = province.minBase2025;
    if (effectiveBase > province.maxBase2025) effectiveBase = province.maxBase2025;

    // 社会平均工资 ≈ 计发基数（各省不同）
    final avgSalary = pensionBase;

    // 本人平均缴费指数
    final avgIndex = (effectiveBase / avgSalary).clamp(0.6, 3.0);

    // 指数化月平均工资
    final indexedSalary = avgSalary * avgIndex;

    // ====================
    // 基础养老金
    // ====================
    // 公式: (计发基数 + 指数化月平均工资) ÷ 2 × 累计缴费年限 × 1%
    final monthsToRetire = retirement.monthsRemaining;
    final additionalYears = monthsToRetire / 12.0;
    final totalYears = input.yearsContributed + additionalYears;

    final basePension =
        (pensionBase + indexedSalary) / 2 * totalYears * 0.01;

    // ====================
    // 个人账户养老金
    // ====================
    // 个人缴费 = 工资 × 8% 进入个人账户
    // 个人账户记账利率 ≈ 3%~5%（取4%）
    final double accountRate = 0.04;
    double accountBalance = input.personalAccountBalance;

    // 模拟未来缴费积累
    if (monthsToRetire > 0) {
      final monthlyContribution = effectiveBase * 0.08;
      // 简化：未来缴费 + 利息
      for (int i = 0; i < monthsToRetire; i++) {
        accountBalance += monthlyContribution;
        if (i % 12 == 0) {
          // 年度计息
          accountBalance *= (1 + accountRate);
        }
      }
    }

    // 计发月数（按退休年龄查表）
    final monthsFactor = _payoutMonths(retirement.retirementAgeYears);

    final personalPension = accountBalance / monthsFactor;

    // ====================
    // 过渡性养老金（"中人"：1996年前参加工作）
    // ====================
    double transitionalPension = 0;
    // 这里简化处理，大多数用户不需要
    // 完整计算需要视同缴费年限等复杂参数

    final totalPension = basePension + personalPension + transitionalPension;

    return PensionResult(
      basePension: double.parse(basePension.toStringAsFixed(2)),
      personalPension: double.parse(personalPension.toStringAsFixed(2)),
      transitionalPension: double.parse(transitionalPension.toStringAsFixed(2)),
      totalMonthlyPension: double.parse(totalPension.toStringAsFixed(2)),
      provinceBase: pensionBase,
      indexedSalary: double.parse(indexedSalary.toStringAsFixed(2)),
      finalYears: double.parse(totalYears.toStringAsFixed(1)),
      finalAccountBalance: double.parse(accountBalance.toStringAsFixed(2)),
    );
  }

  /// 个人账户养老金计发月数表
  int _payoutMonths(int retireAge) {
    const table = {
      40: 233, 41: 230, 42: 226, 43: 223, 44: 220, 45: 216,
      46: 212, 47: 208, 48: 204, 49: 199, 50: 195, 51: 190,
      52: 185, 53: 180, 54: 175, 55: 170, 56: 164, 57: 158,
      58: 152, 59: 145, 60: 139, 61: 132, 62: 125, 63: 117,
      64: 109, 65: 101, 66: 93, 67: 84, 68: 75, 69: 65, 70: 56,
    };
    return table[retireAge] ?? 139;
  }

  // ==========================================
  // 社保月缴费计算
  // ==========================================

  /// 计算每月社保缴费
  SocialInsuranceResult calcSocialInsurance(UserInput input) {
    final province = getProvince(input.province);
    if (province == null) throw Exception('省份数据未找到: ${input.province}');

    final rates = province.rates;
    double base = input.monthlySalary;
    if (base < province.minBase2025) base = province.minBase2025;
    if (base > province.maxBase2025) base = province.maxBase2025;

    final detail = <String, double>{
      '养老保险(个人)': base * rates.pensionPersonal,
      '养老保险(单位)': base * rates.pensionCompany,
      '医疗保险(个人)': base * rates.medicalPersonal,
      '医疗保险(单位)': base * rates.medicalCompany,
      '失业保险(个人)': base * rates.unemploymentPersonal,
      '失业保险(单位)': base * rates.unemploymentCompany,
      '工伤保险(单位)': base * rates.injuryCompany,
      '生育保险(单位)': base * rates.maternityCompany,
    };

    final personalPayment =
        detail.entries.where((e) => e.key.contains('(个人)')).fold(0.0, (s, e) => s + e.value);

    final companyPayment =
        detail.entries.where((e) => e.key.contains('(单位)')).fold(0.0, (s, e) => s + e.value);

    return SocialInsuranceResult(
      personalPayment: double.parse(personalPayment.toStringAsFixed(2)),
      companyPayment: double.parse(companyPayment.toStringAsFixed(2)),
      totalPayment: double.parse((personalPayment + companyPayment).toStringAsFixed(2)),
      detail: detail.map((k, v) => MapEntry(k, double.parse(v.toStringAsFixed(2)))),
    );
  }
}