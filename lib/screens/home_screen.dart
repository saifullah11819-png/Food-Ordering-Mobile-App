import 'package:flutter/material.dart';
import 'food_module/food_list_screen.dart';
import 'order_module/order_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            adminCard("Food Management", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FoodListScreen()),
              );
            }),
            adminCard("Orders", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderListScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget adminCard(String title, VoidCallback onTap) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}
