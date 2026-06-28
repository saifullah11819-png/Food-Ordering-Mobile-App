import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/supabase_client.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen>
    with SingleTickerProviderStateMixin {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final discountController = TextEditingController();
  final descController = TextEditingController();

  File? imageFile;
  bool loading = false;
  bool isAvailable = true;
  String? selectedCategory;
  List categories = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    fetchCategories();
  }

  @override
  void dispose() {
    _animController.dispose();
    nameController.dispose();
    priceController.dispose();
    discountController.dispose();
    descController.dispose();
    super.dispose();
  }

  Future<void> fetchCategories() async {
    try {
      // ── CHANGED: 'categories' → 'menu_categories' ────────────
      final res = await SupabaseService.client.from('menu_categories').select();
      if (mounted) setState(() => categories = List.from(res));
    } catch (_) {}
  }

  Future<void> pickImage() async {
    final picker = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picker != null && mounted) {
      setState(() => imageFile = File(picker.path));
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
    if (nameController.text.trim().isEmpty) {
      _showSnack('Food name is required', Colors.orange);
      return;
    }
    if (priceController.text.trim().isEmpty) {
      _showSnack('Price is required', Colors.orange);
      return;
    }
    final price = double.tryParse(priceController.text.trim());
    if (price == null) {
      _showSnack('Enter a valid price number', Colors.orange);
      return;
    }

    setState(() => loading = true);
    try {
      String imageUrl = '';
      if (imageFile != null) imageUrl = await uploadImage(imageFile!);

      final insertData = <String, dynamic>{
        'name': nameController.text.trim(),
        'price': price,
        'image_url': imageUrl,
        'is_available': isAvailable,
      };

      if (discountController.text.trim().isNotEmpty) {
        final disc = double.tryParse(discountController.text.trim());
        if (disc != null) insertData['discounted_price'] = disc;
      }
      if (descController.text.trim().isNotEmpty) {
        insertData['description'] = descController.text.trim();
      }
      if (selectedCategory != null) {
        // ── CHANGED: field name also matches menu_categories id ─
        insertData['category_id'] = selectedCategory;
      }

      await SupabaseService.client.from('food_items').insert(insertData);

      if (!mounted) return;
      _showSnack('Food item added successfully!', const Color(0xFF11998E));
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        _showSnack('Error adding food: $e', Colors.red);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add New Food Item',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withOpacity(0.06)),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: Image + availability ───────────────────
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Food Image',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: pickImage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 280,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: imageFile != null
                                  ? const Color(0xFFFF6B35)
                                  : Colors.white.withOpacity(0.1),
                              width: 2,
                            ),
                          ),
                          child: imageFile == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFFF6B35,
                                        ).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add_photo_alternate_rounded,
                                        size: 40,
                                        color: Color(0xFFFF6B35),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'Click to upload image',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white54,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'PNG, JPG up to 10MB',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white24,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.file(
                                    imageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                      ),
                      if (imageFile != null) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: pickImage,
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Color(0xFFFF6B35),
                              size: 16,
                            ),
                            label: Text(
                              'Change Image',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFFF6B35),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? const Color(0xFF11998E).withOpacity(0.15)
                                    : Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isAvailable
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                color: isAvailable
                                    ? const Color(0xFF11998E)
                                    : Colors.red,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Availability',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    isAvailable
                                        ? 'Visible on menu'
                                        : 'Hidden from menu',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isAvailable,
                              activeColor: const Color(0xFF11998E),
                              onChanged: (v) => setState(() => isAvailable = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Right: Form ──────────────────────────────────
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(0, 28, 28, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Food Details',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fill in the information below',
                        style: GoogleFonts.poppins(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _FormField(
                        controller: nameController,
                        label: 'Food Name',
                        hint: 'e.g. Chicken Biryani',
                        icon: Icons.fastfood_rounded,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _FormField(
                              controller: priceController,
                              label: 'Price (Rs)',
                              hint: 'e.g. 350',
                              icon: Icons.attach_money_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _FormField(
                              controller: discountController,
                              label: 'Discounted Price (optional)',
                              hint: 'e.g. 280',
                              icon: Icons.local_offer_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _FormField(
                        controller: descController,
                        label: 'Description (optional)',
                        hint: 'Describe the food item...',
                        icon: Icons.notes_rounded,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Category dropdown — loads from menu_categories
                      if (categories.isNotEmpty) ...[
                        Text(
                          'Category',
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              hint: Text(
                                'Select category',
                                style: GoogleFonts.poppins(
                                  color: Colors.white30,
                                  fontSize: 13,
                                ),
                              ),
                              dropdownColor: const Color(0xFF1A1A2E),
                              isExpanded: true,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFFFF6B35),
                              ),
                              items: categories
                                  .map<DropdownMenuItem<String>>(
                                    (c) => DropdownMenuItem(
                                      value: c['id'].toString(),
                                      child: Text(c['name'] ?? ''),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => selectedCategory = v),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: const Color(
                              0xFFFF6B35,
                            ).withOpacity(0.4),
                          ),
                          onPressed: loading ? null : addFood,
                          child: loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add_circle_rounded,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Add Food Item',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable form field ───────────────────────────────────────
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: Colors.white24,
                fontSize: 13,
              ),
              prefixIcon: Icon(icon, color: const Color(0xFFFF6B35), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
