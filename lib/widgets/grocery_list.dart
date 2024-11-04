import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
        'shopping-list-database-7e4e2-default-rtdb.firebaseio.com',
        'shopping-list.json');

    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later.';
        });
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
              (catItem) => catItem.value.title == item.value['category'],
            )
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            price: item.value['price'] ?? 0.0,
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong! Please try again later.';
      });
    }
  }

  double _calculateTotalAmount() {
    double total = 0.0;
    for (var item in _groceryItems) {
      total += item.quantity * item.price;
    }
    return total;
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
        'shopping-list-database-7e4e2-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  // Method to group items by category
  Map<String, List<GroceryItem>> _groupItemsByCategory() {
    final Map<String, List<GroceryItem>> groupedItems = {};

    for (final item in _groceryItems) {
      if (!groupedItems.containsKey(item.category.title)) {
        groupedItems[item.category.title] = [];
      }
      groupedItems[item.category.title]!.add(item);
    }

    return groupedItems;
  }

  @override
  Widget build(BuildContext context) {
    Widget totalAmountWidget = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        'Total Amount: \$${_calculateTotalAmount().toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    Widget content = Column(
      children: [
        totalAmountWidget,
        Expanded(
          child: _groceryItems.isEmpty
              ? const Center(child: Text('No items added yet.'))
              : ListView(
                  children: _groupItemsByCategory().entries.map((entry) {
                    final categoryTitle = entry.key; // Category name
                    final items = entry.value; // Items in that category

                    // Get the color of the first item in this category group
                    final categoryColor = items.first.category.color;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Displays category name as a header with dynamic color
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          child: Text(
                            categoryTitle,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: categoryColor, // Dynamic color
                            ),
                          ),
                        ),
                        // Displays each item under the category
                        ...items.map((item) => Dismissible(
                              key: ValueKey(item.id),
                              onDismissed: (direction) {
                                _removeItem(item);
                              },
                              child: ListTile(
                                title: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                
                                subtitle: Text(
                                    'Price: \$${item.price.toStringAsFixed(2)}'),
                                trailing: Text(
                                  item.quantity.toString(),
                                ),
                              ),
                            )),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      content = Center(child: Text(_error!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
