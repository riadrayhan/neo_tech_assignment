class Chemical {
  final String productName;
  final String casNumber;
  final String manufacturerName;
  final double currentStockQuantity;
  final String unit;
  final String? category;
  final String? storageLocation;
  final String? expiryDate;

  Chemical({
    required this.productName,
    required this.casNumber,
    required this.manufacturerName,
    required this.currentStockQuantity,
    required this.unit,
    this.category,
    this.storageLocation,
    this.expiryDate,
  });

  factory Chemical.fromJson(Map<String, dynamic> json) {
    return Chemical(
      productName: json['product_name'] ?? '',
      casNumber: json['cas_number'] ?? '',
      manufacturerName: json['manufacturer_name'] ?? '',
      currentStockQuantity: (json['current_stock_quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      category: json['category'],
      storageLocation: json['storage_location'],
      expiryDate: json['expiry_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'cas_number': casNumber,
      'manufacturer_name': manufacturerName,
      'current_stock_quantity': currentStockQuantity,
      'unit': unit,
      'category': category,
      'storage_location': storageLocation,
      'expiry_date': expiryDate,
    };
  }
}