class Component {
  final int id;
  final String partNumber;
  final String? marking;
  final int categoryId;
  final String? categoryName;
  final String? technology;
  final String? polarity;
  final String? channel;
  final String? package;
  final double? vMax;
  final double? iMax;
  final double? powerMax;
  final double? gainMin;
  final double? gainMax;
  final double unitPrice;
  final String status;
  final String? notes;
  final Map<String, dynamic>? additionalCharacteristics;

  Component({
    required this.id,
    required this.partNumber,
    this.marking,
    required this.categoryId,
    this.categoryName,
    this.technology,
    this.polarity,
    this.channel,
    this.package,
    this.vMax,
    this.iMax,
    this.powerMax,
    this.gainMin,
    this.gainMax,
    required this.unitPrice,
    required this.status,
    this.notes,
    this.additionalCharacteristics,
  });

  factory Component.fromJson(Map<String, dynamic> json) {
    return Component(
      id: json['id'] as int,
      partNumber: json['part_number'] as String,
      marking: json['marking'] as String?,
      categoryId: json['category_id'] as int,
      categoryName: json['category_name'] as String?,
      technology: json['technology'] as String?,
      polarity: json['polarity'] as String?,
      channel: json['channel'] as String?,
      package: json['package'] as String?,
      vMax: json['v_max'] as double?,
      iMax: json['i_max'] as double?,
      powerMax: json['power_max'] as double?,
      gainMin: json['gain_min'] as double?,
      gainMax: json['gain_max'] as double?,
      unitPrice: (json['unit_price'] as num).toDouble(),
      status: json['status'] as String,
      notes: json['notes'] as String?,
      additionalCharacteristics: json['additional_characteristics'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'part_number': partNumber,
      'marking': marking,
      'category_id': categoryId,
      'technology': technology,
      'polarity': polarity,
      'channel': channel,
      'package': package,
      'v_max': vMax,
      'i_max': iMax,
      'power_max': powerMax,
      'gain_min': gainMin,
      'gain_max': gainMax,
      'unit_price': unitPrice,
      'status': status,
      'notes': notes,
      'additional_characteristics': additionalCharacteristics,
    };
  }
}

