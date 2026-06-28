import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  final order;

  OrderDetailScreen(this.order);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Order Details")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Order ID: ${order['id']}"),
            Text("Status: ${order['status']}"),

            SizedBox(height: 20),

            Text("Customer Info"),
            Text(order['customer_id'].toString()),
          ],
        ),
      ),
    );
  }
}
