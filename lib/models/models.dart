/// 省份社保数据模型
class ProvinceData {
  final String name;
  final String code;
  final double pensionBase2024;
  final double pensionBase2025;
  final SocialInsuranceRates rates;
  final double minBase2025;
  final double maxBase2025;

  ProvinceData({
    required this.name,
    required this.code,
    required this.pensionBase2024,
    required this.pensionBase2025,
    required this.rates,
    required this.minBase2025,
    required this.maxBase2025,
  });

  factory ProvinceData.fromJson(String name, Map<String, dynamic> json) {
    return ProvinceData(
      name: name,
      code: json['code'] as String,
      pensionBase2024: (json['pension_base_2024'] as num).toDouble(),
      pensionBase2025: (json['pension_base_2025'] as num).toDouble(),
      rates: SocialInsuranceRates.fromJson(
          json['social_insurance'] as Map<String, dynamic>),
      minBase2025: (json['min_base_2025'] as num).toDouble(),
      maxBase2025: (json['max_base_2025'] as num).toDouble(),
    );
  }
}

/// 社保各项费率
class SocialInsuranceRates {
  final double pensionPersonal;
  final double pensionCompany;
  final double medicalPersonal;
  final double medicalCompany;
  final double unemploymentPersonal;
  final double unemploymentCompany;
  final double injuryCompany;
  final double maternityCompany;

  SocialInsuranceRates({
    required this.pensionPersonal,
    required this.pensionCompany,
    required this.medicalPersonal,
    required this.medicalCompany,
    required this.unemploymentPersonal,
    required this.unemploymentCompany,
    required this.injuryCompany,
    required this.maternityCompany,
  });

  factory SocialInsuranceRates.fromJson(Map<String, dynamic> json) {
    return SocialInsuranceRates(
      pensionPersonal: (json['pension_personal'] as num).toDouble(),
      pensionCompany: (json['pension_company'] as num).toDouble(),
      medicalPersonal: (json['medical_personal'] as num).toDouble(),
      medicalCompany: (json['medical_company'] as num).toDouble(),
      unemploymentPersonal: (json['unemployment_personal'] as num).toDouble(),
      unemploymentCompany: (json['unemployment_company'] as num).toDouble(),
      injuryCompany: (json['injury_company'] as num).toDouble(),
      maternityCompany: (json['maternity_company'] as num).toDouble(),
    );
  }

  double get totalPersonal =>
      pensionPersonal + medicalPersonal + unemploymentPersonal;

  double get totalCompany => pensionCompany +
      medicalCompany +
      unemploymentCompany +
      injuryCompany +
      maternityCompany;
}

/// 用户输入参数
class UserInput {
  final DateTime birthDate;
  final Gender gender;
  final WorkerType workerType;
  final String province;
  final double monthlySalary; // 月工资（缴费基数）
  final int yearsContributed; // 已缴费年限
  final double personalAccountBalance; // 个人账户余额
  final double? expectedGrowthRate; // 预计工资增长率

  UserInput({
    required this.birthDate,
    required this.gender,
    required this.workerType,
    required this.province,
    required this.monthlySalary,
    required this.yearsContributed,
    this.personalAccountBalance = 0,
    this.expectedGrowthRate = 0.03,
  });
}

/// 退休计算结果
class RetirementResult {
  final int retirementAgeYears;
  final int retirementAgeMonths;
  final DateTime retirementDate;
  final int monthsRemaining;
  final String policyNote;

  RetirementResult({
    required this.retirementAgeYears,
    required this.retirementAgeMonths,
    required this.retirementDate,
    required this.monthsRemaining,
    required this.policyNote,
  });

  String get retirementAgeDisplay =>
      '$retirementAgeYears岁${retirementAgeMonths > 0 ? '$retirementAgeMonths个月' : ''}';

  String get remainingDisplay {
    final years = monthsRemaining ~/ 12;
    final months = monthsRemaining % 12;
    if (years > 0 && months > 0) return '$years年$months个月';
    if (years > 0) return '$years年';
    if (months > 0) return '$months个月';
    return '已到退休年龄';
  }
}

/// 养老金计算结果
class PensionResult {
  final double basePension; // 基础养老金
  final double personalPension; // 个人账户养老金
  final double transitionalPension; // 过渡性养老金
  final double totalMonthlyPension; // 合计月养老金
  final double provinceBase; // 当地计发基数
  final double indexedSalary; // 本人指数化月平均工资
  final double finalYears; // 最终缴费年限
  final double finalAccountBalance; // 退休时个人账户余额

  PensionResult({
    required this.basePension,
    required this.personalPension,
    required this.transitionalPension,
    required this.totalMonthlyPension,
    required this.provinceBase,
    required this.indexedSalary,
    required this.finalYears,
    required this.finalAccountBalance,
  });

  double get annualPension => totalMonthlyPension * 12;
}

/// 社保月缴费结果
class SocialInsuranceResult {
  final double personalPayment; // 个人缴纳
  final double companyPayment; // 公司缴纳
  final double totalPayment; // 合计
  final Map<String, double> detail; // 各项明细

  SocialInsuranceResult({
    required this.personalPayment,
    required this.companyPayment,
    required this.totalPayment,
    required this.detail,
  });
}

/// 性别
enum Gender { male, female }

/// 职工类型
enum WorkerType { worker, cadre, flexible }
// worker=女工人(原50退), cadre=女干部(原55退), flexible=灵活就业女性(原55退)