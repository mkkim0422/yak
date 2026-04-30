class HealthCheckup {
  final DateTime checkupDate;
  final double? cholesterolTotal;
  final double? cholesterolLdl;
  final double? cholesterolHdl;
  final double? bloodSugar;
  final double? hemoglobin;
  final double? alt;
  final double? ast;
  final double? vitaminD;
  final double? bloodPressureSystolic;
  final double? bloodPressureDiastolic;

  const HealthCheckup({
    required this.checkupDate,
    this.cholesterolTotal,
    this.cholesterolLdl,
    this.cholesterolHdl,
    this.bloodSugar,
    this.hemoglobin,
    this.alt,
    this.ast,
    this.vitaminD,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
  });

  Map<String, dynamic> toJson() => {
        'checkup_date': checkupDate.toIso8601String(),
        'cholesterol_total': cholesterolTotal,
        'cholesterol_ldl': cholesterolLdl,
        'cholesterol_hdl': cholesterolHdl,
        'blood_sugar': bloodSugar,
        'hemoglobin': hemoglobin,
        'alt': alt,
        'ast': ast,
        'vitamin_d': vitaminD,
        'bp_systolic': bloodPressureSystolic,
        'bp_diastolic': bloodPressureDiastolic,
      };

  factory HealthCheckup.fromJson(Map<String, dynamic> json) => HealthCheckup(
        checkupDate: DateTime.parse(json['checkup_date'] as String),
        cholesterolTotal: (json['cholesterol_total'] as num?)?.toDouble(),
        cholesterolLdl: (json['cholesterol_ldl'] as num?)?.toDouble(),
        cholesterolHdl: (json['cholesterol_hdl'] as num?)?.toDouble(),
        bloodSugar: (json['blood_sugar'] as num?)?.toDouble(),
        hemoglobin: (json['hemoglobin'] as num?)?.toDouble(),
        alt: (json['alt'] as num?)?.toDouble(),
        ast: (json['ast'] as num?)?.toDouble(),
        vitaminD: (json['vitamin_d'] as num?)?.toDouble(),
        bloodPressureSystolic: (json['bp_systolic'] as num?)?.toDouble(),
        bloodPressureDiastolic: (json['bp_diastolic'] as num?)?.toDouble(),
      );
}
