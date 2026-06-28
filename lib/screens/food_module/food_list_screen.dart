import 'package:flutter/material.dart';
import '../../core/supabase_client.dart';
import 'add_food_screen.dart';

class FoodListScreen extends StatelessWidget {
  const FoodListScreen({super.key});

  Future<List> getFoods() async {
    return await SupabaseService.client.from('food_items').select();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Food Items")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddFoodScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder(
        future: getFoods(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final foods = snapshot.data!;

          return ListView.builder(
            itemCount: foods.length,
            itemBuilder: (context, i) {
              final food = foods[i];
              return ListTile(
                title: Text(food['name']),
                subtitle: Text("Rs ${food['price']}"),
              );
            },
          );
        },
      ),
    );
  }
}
