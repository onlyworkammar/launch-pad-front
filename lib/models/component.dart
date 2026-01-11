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
  final String? vMax;
  final String? iMax;
  final String? powerMax;
  final String? gainMin;
  final String? gainMax;
  final double unitPrice;
  final String status;
  final String? notes;
  final Map<String, dynamic>? additionalCharacteristics;
  
  // Inventory fields (included with component response)
  final int quantity;
  final int? minQty;
  final String? location;
  final DateTime? inventoryLastUpdated;
  final double totalValue;

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
    this.quantity = 0,
    this.minQty,
    this.location,
    this.inventoryLastUpdated,
    this.totalValue = 0.0,
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
      vMax: json['v_max'] as String?,
      iMax: json['i_max'] as String?,
      powerMax: json['power_max'] as String?,
      gainMin: json['gain_min'] as String?,
      gainMax: json['gain_max'] as String?,
      unitPrice: (json['unit_price'] as num).toDouble(),
      status: json['status'] as String,
      notes: json['notes'] as String?,
      additionalCharacteristics: json['additional_characteristics'] as Map<String, dynamic>?,
      // Inventory fields
      quantity: json['quantity'] as int? ?? 0,
      minQty: json['min_qty'] as int?,
      location: json['location'] as String?,
      inventoryLastUpdated: json['inventory_last_updated'] != null
          ? DateTime.parse(json['inventory_last_updated'] as String)
          : null,
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0.0,
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


