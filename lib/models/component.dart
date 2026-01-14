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
  
  // MOSFET-specific fields (optional)
  final String? rdsOn;
  final String? vgsMax;
  final String? vgsTh;
  final String? qg;
  final String? ciss;
  final String? switchingType;
  
  // Diode-specific fields (optional)
  final String? vf;
  final String? trr;
  final String? cj;
  final String? diodeType;
  final String? internalConfig;
  
  // Voltage Regulator-specific fields (optional)
  final String? vInMax;
  final String? vOut;
  final String? iOutMax;
  final String? accuracy;
  final String? regType;
  
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
    // MOSFET fields
    this.rdsOn,
    this.vgsMax,
    this.vgsTh,
    this.qg,
    this.ciss,
    this.switchingType,
    // Diode fields
    this.vf,
    this.trr,
    this.cj,
    this.diodeType,
    this.internalConfig,
    // Voltage Regulator fields
    this.vInMax,
    this.vOut,
    this.iOutMax,
    this.accuracy,
    this.regType,
    // Inventory fields
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
      // MOSFET fields
      rdsOn: json['rds_on'] as String?,
      vgsMax: json['vgs_max'] as String?,
      vgsTh: json['vgs_th'] as String?,
      qg: json['qg'] as String?,
      ciss: json['ciss'] as String?,
      switchingType: json['switching_type'] as String?,
      // Diode fields
      vf: json['vf'] as String?,
      trr: json['trr'] as String?,
      cj: json['cj'] as String?,
      diodeType: json['diode_type'] as String?,
      internalConfig: json['internal_config'] as String?,
      // Voltage Regulator fields
      vInMax: json['v_in_max'] as String?,
      vOut: json['v_out'] as String?,
      iOutMax: json['i_out_max'] as String?,
      accuracy: json['accuracy'] as String?,
      regType: json['reg_type'] as String?,
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
      // MOSFET fields
      'rds_on': rdsOn,
      'vgs_max': vgsMax,
      'vgs_th': vgsTh,
      'qg': qg,
      'ciss': ciss,
      'switching_type': switchingType,
      // Diode fields
      'vf': vf,
      'trr': trr,
      'cj': cj,
      'diode_type': diodeType,
      'internal_config': internalConfig,
      // Voltage Regulator fields
      'v_in_max': vInMax,
      'v_out': vOut,
      'i_out_max': iOutMax,
      'accuracy': accuracy,
      'reg_type': regType,
    };
  }
}


