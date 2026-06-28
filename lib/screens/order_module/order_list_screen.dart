import 'package:flutter/material.dart';
import '../../core/supabase_client.dart';

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});

  Future<List> getOrders() async {
    return await SupabaseService.client
        .from('orders')
        .select()
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Orders")),
      body: FutureBuilder(
        future: getOrders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final order = orders[i];
              return Card(
                child: ListTile(
                  title: Text("Order: ${order['id']}"),
                  subtitle: Text("Status: ${order['status']}"),
                  trailing: DropdownButton(
                    value: order['status'],
                    items: ["pending", "confirmed", "preparing", "delivered"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) async {
                      await SupabaseService.client
                          .from('orders')
                          .update({'status': value})
                          .eq('id', order['id']);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
