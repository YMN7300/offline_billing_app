// product.dart (NEW FILE)

class Product {
  final String name;
  final String type;
  final String unit;
  final String category;
  final String brand;
  final double salePrice;
  final double costPrice;
  int stock;
  final int lowStockAlert;
  final String date;

  Product({
    required this.name,
    required this.type,
    required this.unit,
    required this.category,
    required this.brand,
    required this.salePrice,
    required this.costPrice,
    required this.stock,
    required this.lowStockAlert,
    required this.date,
  });
}
