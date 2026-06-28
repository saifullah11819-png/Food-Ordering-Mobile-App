import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/supabase_client.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();

  File? imageFile;
  bool loading = false;

  Future<void> pickImage() async {
    final picker = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picker != null) {
      setState(() {
        imageFile = File(picker.path);
      });
    }
  }

  Future<String> uploadImage(File file) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    await SupabaseService.client.storage
        .from('food-images')
        .upload(fileName, file);
    return SupabaseService.client.storage
        .from('food-images')
        .getPublicUrl(fileName);
  }

  Future<void> addFood() async {
    setState(() => loading = true);

    String imageUrl = '';
    if (imageFile != null) {
      imageUrl = await uploadImage(imageFile!);
    }

    await SupabaseService.client.from('food_items').insert({
      'name': nameController.text,
      'price': double.parse(priceController.text),
      'image_url': imageUrl,
      'is_available': true,
    });

    setState(() => loading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Food")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 150,
                width: 150,
                color: Colors.grey[800],
                child: imageFile == null
                    ? const Icon(Icons.add_a_photo)
                    : Image.file(imageFile!, fit: BoxFit.cover),
              ),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Food Name"),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : addFood,
              child: Text(loading ? "Adding..." : "Add Food"),
            ),
          ],
        ),
      ),
    );
  }
}
