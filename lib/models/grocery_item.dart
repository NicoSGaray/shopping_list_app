import 'package:shopping_list_app/models/category.dart';

class GroceryItem {
  const GroceryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.category,
    required this.price, // price per item
  });

  final String id;
  final String name;
  final int quantity;
  final Category category;
  final double price; // stores price per item
}
