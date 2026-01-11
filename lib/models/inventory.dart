class InventoryInfo {
  final int componentId;
  final int quantity;
  final int minQty;
  final String? location;
  final DateTime? lastUpdated;
  final double unitPrice;
  final double totalValue;

  InventoryInfo({
    required this.componentId,
    required this.quantity,
    required this.minQty,
    this.location,
    this.lastUpdated,
    required this.unitPrice,
    required this.totalValue,
  });

  factory InventoryInfo.fromJson(Map<String, dynamic> json) {
    return InventoryInfo(
      componentId: json['component_id'] as int,
      quantity: json['quantity'] as int,
      minQty: json['min_qty'] as int,
      location: json['location'] as String?,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalValue: (json['total_value'] as num).toDouble(),
    );
  }
}

class InventoryItem {
  final int componentId;
  final String partNumber;
  final String componentName;
  final String categoryName;
  final int quantity;
  final int minQty;
  final String? location;
  final DateTime? lastUpdated;
  final double unitPrice;
  final double totalValue;

  InventoryItem({
    required this.componentId,
    required this.partNumber,
    required this.componentName,
    required this.categoryName,
    required this.quantity,
    required this.minQty,
    this.location,
    this.lastUpdated,
    required this.unitPrice,
    required this.totalValue,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      componentId: json['component_id'] as int,
      partNumber: json['part_number'] as String,
      componentName: json['component_name'] as String,
      categoryName: (json['category_name']??"None") as String,
      quantity: json['quantity'] as int,
      minQty: json['min_qty'] as int,
      location: json['location'] as String?,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalValue: (json['total_value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'component_id': componentId,
      'quantity': quantity,
      'min_qty': minQty,
      'location': location,
    };
  }
}

class InventoryCostSummary {
  final int totalComponents;
  final int totalQuantity;
  final double totalValue;
  final String currency;
  final Map<String, CategoryBreakdown> breakdownByCategory;
  final List<LowStockItem> lowStockItems;

  InventoryCostSummary({
    required this.totalComponents,
    required this.totalQuantity,
    required this.totalValue,
    required this.currency,
    required this.breakdownByCategory,
    required this.lowStockItems,
  });

  factory InventoryCostSummary.fromJson(Map<String, dynamic> json) {
    final breakdown = <String, CategoryBreakdown>{};
    if (json['breakdown_by_category'] != null) {
      (json['breakdown_by_category'] as Map<String, dynamic>).forEach((key, value) {
        breakdown[key] = CategoryBreakdown.fromJson(value as Map<String, dynamic>);
      });
    }

    final lowStock = <LowStockItem>[];
    if (json['low_stock_items'] != null) {
      for (var item in json['low_stock_items'] as List) {
        lowStock.add(LowStockItem.fromJson(item as Map<String, dynamic>));
      }
    }

    return InventoryCostSummary(
      totalComponents: json['total_components'] as int,
      totalQuantity: json['total_quantity'] as int,
      totalValue: (json['total_value'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      breakdownByCategory: breakdown,
      lowStockItems: lowStock,
    );
  }
}

class CategoryBreakdown {
  final int componentCount;
  final int totalQuantity;
  final double totalValue;

  CategoryBreakdown({
    required this.componentCount,
    required this.totalQuantity,
    required this.totalValue,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      componentCount: json['component_count'] as int,
      totalQuantity: json['total_quantity'] as int,
      totalValue: (json['total_value'] as num).toDouble(),
    );
  }
}

class LowStockItem {
  final int componentId;
  final String partNumber;
  final String categoryName;
  final int quantity;
  final int minQty;
  final double unitPrice;
  final double totalValue;
  final int shortage;

  LowStockItem({
    required this.componentId,
    required this.partNumber,
    required this.categoryName,
    required this.quantity,
    required this.minQty,
    required this.unitPrice,
    required this.totalValue,
    required this.shortage,
  });

  factory LowStockItem.fromJson(Map<String, dynamic> json) {
    return LowStockItem(
      componentId: json['component_id'] as int,
      partNumber: json['part_number'] as String,
      categoryName: json['category_name'] as String,
      quantity: json['quantity'] as int,
      minQty: json['min_qty'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalValue: (json['total_value'] as num).toDouble(),
      shortage: json['shortage'] as int,
    );
  }
}

