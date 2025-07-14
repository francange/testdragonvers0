// lib/models/sale.dart
class Sale {
  String productName;
  int quantity;
  double price;

  Sale({
    required this.productName,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;
}
