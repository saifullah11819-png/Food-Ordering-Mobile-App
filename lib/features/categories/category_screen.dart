import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/supabase_client.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    with TickerProviderStateMixin {
  List categories = [];
  bool loading = true;
  final nameController = TextEditingController();

  late AnimationController _gridController;

  final List<IconData> _catIcons = [
    Icons.local_pizza_rounded,
    Icons.lunch_dining_rounded,
    Icons.ramen_dining_rounded,
    Icons.set_meal_rounded,
    Icons.bakery_dining_rounded,
    Icons.icecream_rounded,
    Icons.local_cafe_rounded,
    Icons.rice_bowl_rounded,
    Icons.soup_kitchen_rounded,
    Icons.fastfood_rounded,
    Icons.kebab_dining_rounded,
    Icons.egg_alt_rounded,
  ];

  final List<List<Color>> _catGradients = [
    [const Color(0xFFFF6B35), const Color(0xFFFF8C42)],
    [const Color(0xFF6C63FF), const Color(0xFF8B85FF)],
    [const Color(0xFF11998E), const Color(0xFF38EF7D)],
    [const Color(0xFFFC5C7D), const Color(0xFF6A82FB)],
    [const Color(0xFFF7971E), const Color(0xFFFFD200)],
    [const Color(0xFF4776E6), const Color(0xFF8E54E9)],
    [const Color(0xFFEB3349), const Color(0xFFF45C43)],
    [const Color(0xFF134E5E), const Color(0xFF71B280)],
    [const Color(0xFFDA22FF), const Color(0xFF9733EE)],
    [const Color(0xFF1FA2FF), const Color(0xFF12D8FA)],
    [const Color(0xFFF953C6), const Color(0xFFB91D73)],
    [const Color(0xFF43C6AC), const Color(0xFF191654)],
  ];

  @override
  void initState() {
    super.initState();
    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    fetchCategories();
  }

  @override
  void dispose() {
    _gridController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> fetchCategories() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      final res = await SupabaseService.client
          .from('menu_categories')
          .select()
          .order('created_at');
      if (!mounted) return;
      setState(() {
        categories = List.from(res);
        loading = false;
      });
      _gridController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _showSnack('Error: $e', Colors.red);
    }
  }

  Future<void> addCategory(String name) async {
    if (name.trim().isEmpty) return;
    try {
      await SupabaseService.client.from('menu_categories').insert({
        'name': name.trim(),
      });
      nameController.clear();
      _showSnack('Category "$name" added!', const Color(0xFF11998E));
      await fetchCategories();
    } catch (e) {
      _showSnack('Error: $e', Colors.red);
    }
  }

  Future<void> deleteCategory(String id, String name) async {
    final confirm = await _confirmDialog(
      'Delete Category',
      'Remove "$name"?',
      Colors.red,
    );
    if (confirm != true) return;
    try {
      await SupabaseService.client
          .from('menu_categories')
          .delete()
          .eq('id', id);
      _showSnack('Category removed', Colors.red);
      await fetchCategories();
    } catch (e) {
      _showSnack('Error: $e', Colors.red);
    }
  }

  Future<void> toggleActive(String id, bool current) async {
    try {
      await SupabaseService.client
          .from('menu_categories')
          .update({'is_active': !current})
          .eq('id', id);
      _showSnack(
        current ? 'Deactivated' : 'Activated',
        current ? Colors.orange : const Color(0xFF11998E),
      );
      await fetchCategories();
    } catch (e) {
      _showSnack('Error: $e', Colors.red);
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

  Future<bool?> _confirmDialog(String title, String msg, Color color) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          msg,
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(bool isMobile) {
    nameController.clear();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 100,
          vertical: isMobile ? 40 : 100,
        ),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 20 : 28),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B35).withOpacity(0.15),
                blurRadius: 40,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.category_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add Category',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Input
              Text(
                'Category Name',
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: nameController,
                  autofocus: true,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Burgers, Pizza, Drinks...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.white24,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.label_rounded,
                      color: Color(0xFFFF6B35),
                      size: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        nameController.clear();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(color: Colors.white38),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                      ),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        Navigator.pop(context);
                        await addCategory(name);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Add Category',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final active = categories.where((c) => c['is_active'] != false).length;
    final inactive = categories.length - active;

    return Container(
      color: const Color(0xFF0F0F1A),
      child: Column(
        children: [
          // ── Toolbar ──────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 14 : 24,
              isMobile ? 12 : 20,
              isMobile ? 14 : 24,
              isMobile ? 10 : 16,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
              ),
            ),
            child: Row(
              children: [
                // Stats
                _StatBadge(
                  label: isMobile ? '' : 'Total',
                  value: '${categories.length}',
                  color: const Color(0xFFFF6B35),
                  icon: Icons.category_rounded,
                  isMobile: isMobile,
                ),
                const SizedBox(width: 8),
                _StatBadge(
                  label: isMobile ? '' : 'Active',
                  value: '$active',
                  color: const Color(0xFF11998E),
                  icon: Icons.check_circle_rounded,
                  isMobile: isMobile,
                ),
                const SizedBox(width: 8),
                _StatBadge(
                  label: isMobile ? '' : 'Inactive',
                  value: '$inactive',
                  color: const Color(0xFFFC5C7D),
                  icon: Icons.cancel_rounded,
                  isMobile: isMobile,
                ),
                const Spacer(),
                // Refresh
                GestureDetector(
                  onTap: fetchCategories,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Add button
                GestureDetector(
                  onTap: () => _showAddDialog(isMobile),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 20,
                      vertical: isMobile ? 8 : 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isMobile ? 'Add' : 'Add Category',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: isMobile ? 12 : 13,
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

          // ── Grid ─────────────────────────────────────────────
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                  )
                : categories.isEmpty
                ? _EmptyState(onAdd: () => _showAddDialog(isMobile))
                : GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 14 : 24,
                      isMobile ? 14 : 24,
                      isMobile ? 14 : 24,
                      isMobile ? 80 : 24,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : 4,
                      childAspectRatio: isMobile ? 1.0 : 1.05,
                      crossAxisSpacing: isMobile ? 12 : 16,
                      mainAxisSpacing: isMobile ? 12 : 16,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isActive = cat['is_active'] != false;
                      final delay = (index % 8) * 0.07;
                      final anim = Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _gridController,
                          curve: Interval(
                            delay.clamp(0.0, 0.8),
                            (delay + 0.35).clamp(0.0, 1.0),
                            curve: Curves.easeOut,
                          ),
                        ),
                      );

                      return _CategoryCard(
                        cat: cat,
                        isActive: isActive,
                        icon: _catIcons[index % _catIcons.length],
                        gradient: _catGradients[index % _catGradients.length],
                        anim: anim,
                        isMobile: isMobile,
                        onDelete: () => deleteCategory(cat['id'], cat['name']),
                        onToggle: () => toggleActive(cat['id'], isActive),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Category Card ─────────────────────────────────────────────
class _CategoryCard extends StatefulWidget {
  final Map cat;
  final bool isActive;
  final IconData icon;
  final List<Color> gradient;
  final Animation<double> anim;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  final bool isMobile;

  const _CategoryCard({
    required this.cat,
    required this.isActive,
    required this.icon,
    required this.gradient,
    required this.anim,
    required this.onDelete,
    required this.onToggle,
    required this.isMobile,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(widget.anim),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()
              ..translate(0.0, _hovered ? -4.0 : 0.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hovered
                    ? widget.gradient[0].withOpacity(0.6)
                    : widget.isActive
                    ? widget.gradient[0].withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                width: 1.5,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: widget.gradient[0].withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: Padding(
              padding: EdgeInsets.all(widget.isMobile ? 12 : 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon + status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: widget.isMobile ? 40 : 52,
                        height: widget.isMobile ? 40 : 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.isActive
                                ? widget.gradient
                                : [Colors.grey.shade700, Colors.grey.shade600],
                          ),
                          borderRadius: BorderRadius.circular(
                            widget.isMobile ? 10 : 14,
                          ),
                          boxShadow: widget.isActive
                              ? [
                                  BoxShadow(
                                    color: widget.gradient[0].withOpacity(0.35),
                                    blurRadius: 10,
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          widget.icon,
                          color: Colors.white,
                          size: widget.isMobile ? 20 : 26,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isActive
                              ? const Color(0xFF11998E).withOpacity(0.15)
                              : Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.isActive
                                ? const Color(0xFF11998E).withOpacity(0.4)
                                : Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          widget.isActive ? '✓' : '✗',
                          style: TextStyle(
                            color: widget.isActive
                                ? const Color(0xFF11998E)
                                : Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Name
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.cat['name'] ?? '',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: widget.isMobile ? 12 : 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onToggle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.isActive
                                  ? Colors.orange.withOpacity(0.12)
                                  : const Color(0xFF11998E).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: widget.isActive
                                    ? Colors.orange.withOpacity(0.3)
                                    : const Color(0xFF11998E).withOpacity(0.3),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                widget.isActive ? '− Off' : '+ On',
                                style: GoogleFonts.poppins(
                                  color: widget.isActive
                                      ? Colors.orange
                                      : const Color(0xFF11998E),
                                  fontSize: widget.isMobile ? 9 : 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: widget.onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stat Badge ────────────────────────────────────────────────
class _StatBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  final bool isMobile;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 14,
        vertical: isMobile ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: isMobile ? 13 : 15),
          const SizedBox(width: 5),
          Text(
            isMobile ? value : '$label: $value',
            style: GoogleFonts.poppins(
              color: color,
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.category_rounded,
              size: 48,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No categories yet',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap Add to create one',
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Add Category',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
