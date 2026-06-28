import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/supabase_client.dart';
import 'add_food_screen.dart';

class FoodListScreen extends StatefulWidget {
  const FoodListScreen({super.key});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen>
    with TickerProviderStateMixin {
  List foods = [];
  List filtered = [];
  bool loading = true;
  String searchQuery = '';
  String selectedFilter = 'All';

  late AnimationController _gridController;

  final filters = ['All', 'Available', 'Unavailable'];

  final List<String> fallbackImages = [
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&q=80',
    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&q=80',
    'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400&q=80',
    'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400&q=80',
    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&q=80',
    'https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=400&q=80',
    'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=400&q=80',
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&q=80',
    'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=400&q=80',
    'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=400&q=80',
    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&q=80',
    'https://images.unsplash.com/photo-1529042410759-befb1204b468?w=400&q=80',
    'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=400&q=80',
    'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400&q=80',
    'https://images.unsplash.com/photo-1559847844-5315695dadae?w=400&q=80',
    'https://images.unsplash.com/photo-1606755962773-d324e0a13086?w=400&q=80',
    'https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=400&q=80',
    'https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?w=400&q=80',
    'https://images.unsplash.com/photo-1585325701956-60dd9c8553bc?w=400&q=80',
    'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400&q=80',
    'https://images.unsplash.com/photo-1550317138-10000687a72b?w=400&q=80',
    'https://images.unsplash.com/photo-1432139509613-5c4255815697?w=400&q=80',
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80',
    'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    fetchFoods();
  }

  @override
  void dispose() {
    _gridController.dispose();
    super.dispose();
  }

  Future<void> fetchFoods() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      final res = await SupabaseService.client
          .from('food_items')
          .select()
          .order('created_at');
      if (!mounted) return;
      setState(() {
        foods = List.from(res);
        loading = false;
        _applyFilter();
      });
      _gridController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _showSnack('Error loading foods: $e', Colors.red);
    }
  }

  void _applyFilter() {
    List temp = List.from(foods);
    if (selectedFilter == 'Available') {
      temp = temp.where((f) => f['is_available'] == true).toList();
    } else if (selectedFilter == 'Unavailable') {
      temp = temp.where((f) => f['is_available'] == false).toList();
    }
    if (searchQuery.isNotEmpty) {
      temp = temp
          .where(
            (f) => (f['name'] ?? '').toString().toLowerCase().contains(
              searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }
    filtered = temp;
  }

  Future<void> toggleAvailability(String id, bool currentValue) async {
    try {
      await SupabaseService.client
          .from('food_items')
          .update({'is_available': !currentValue})
          .eq('id', id);
      _showSnack(
        currentValue ? 'Marked as Unavailable' : 'Marked as Available',
        currentValue ? Colors.orange : const Color(0xFF11998E),
      );
      await fetchFoods();
    } catch (e) {
      _showSnack('Update failed: $e', Colors.red);
    }
  }

  Future<void> deleteFood(String id) async {
    final confirm = await _confirmDialog(
      'Delete Food',
      'Are you sure you want to remove this food item?',
      Colors.red,
    );
    if (confirm != true) return;
    try {
      await SupabaseService.client.from('food_items').delete().eq('id', id);
      _showSnack('Food item removed', Colors.red);
      await fetchFoods();
    } catch (e) {
      _showSnack('Delete failed: $e', Colors.red);
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
              'Confirm',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

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
            child: isMobile
                ? Column(
                    children: [
                      // Search
                      Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: TextField(
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search food...',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.white30,
                              fontSize: 12,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFFFF6B35),
                              size: 18,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                          onChanged: (v) => setState(() {
                            searchQuery = v;
                            _applyFilter();
                          }),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Filters + Add button row
                      Row(
                        children: [
                          ...filters.map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  selectedFilter = f;
                                  _applyFilter();
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selectedFilter == f
                                        ? const Color(0xFFFF6B35)
                                        : Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    f,
                                    style: GoogleFonts.poppins(
                                      color: selectedFilter == f
                                          ? Colors.white
                                          : Colors.white38,
                                      fontSize: 10,
                                      fontWeight: selectedFilter == f
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Refresh
                          GestureDetector(
                            onTap: fetchFoods,
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
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddFoodScreen(),
                                ),
                              );
                              await fetchFoods();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF6B35),
                                    Color(0xFFFF8C42),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF6B35,
                                    ).withOpacity(0.3),
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
                                  const SizedBox(width: 4),
                                  Text(
                                    'Add',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: TextField(
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search food items...',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.white30,
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFFFF6B35),
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            onChanged: (v) => setState(() {
                              searchQuery = v;
                              _applyFilter();
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ...filters.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() {
                              selectedFilter = f;
                              _applyFilter();
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selectedFilter == f
                                    ? const Color(0xFFFF6B35)
                                    : Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                f,
                                style: GoogleFonts.poppins(
                                  color: selectedFilter == f
                                      ? Colors.white
                                      : Colors.white38,
                                  fontSize: 12,
                                  fontWeight: selectedFilter == f
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: fetchFoods,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 6,
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddFoodScreen(),
                            ),
                          );
                          await fetchFoods();
                        },
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text(
                          'Add Food',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // ── Stats row ────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 14 : 24,
              12,
              isMobile ? 14 : 24,
              0,
            ),
            child: Row(
              children: [
                _MiniStat(
                  label: 'Total',
                  value: '${foods.length}',
                  color: const Color(0xFFFF6B35),
                  icon: Icons.fastfood_rounded,
                  isMobile: isMobile,
                ),
                const SizedBox(width: 8),
                _MiniStat(
                  label: 'Available',
                  value:
                      '${foods.where((f) => f['is_available'] == true).length}',
                  color: const Color(0xFF11998E),
                  icon: Icons.check_circle_rounded,
                  isMobile: isMobile,
                ),
                const SizedBox(width: 8),
                _MiniStat(
                  label: 'Unavailable',
                  value:
                      '${foods.where((f) => f['is_available'] == false).length}',
                  color: const Color(0xFFFC5C7D),
                  icon: Icons.cancel_rounded,
                  isMobile: isMobile,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Grid ─────────────────────────────────────────────
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                  )
                : filtered.isEmpty
                ? _EmptyState()
                : GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 14 : 24,
                      8,
                      isMobile ? 14 : 24,
                      isMobile ? 80 : 24,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : 4,
                      childAspectRatio: isMobile ? 0.68 : 0.72,
                      crossAxisSpacing: isMobile ? 12 : 16,
                      mainAxisSpacing: isMobile ? 12 : 16,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final food = filtered[index];
                      final delay = (index % 8) * 0.06;
                      final anim = Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _gridController,
                          curve: Interval(
                            delay.clamp(0.0, 0.8),
                            (delay + 0.3).clamp(0.0, 1.0),
                            curve: Curves.easeOut,
                          ),
                        ),
                      );
                      final imgUrl =
                          (food['image_url'] != null &&
                              food['image_url'].toString().isNotEmpty)
                          ? food['image_url']
                          : fallbackImages[index % fallbackImages.length];

                      return _FoodCard(
                        food: food,
                        imageUrl: imgUrl,
                        anim: anim,
                        isMobile: isMobile,
                        onDelete: () => deleteFood(food['id']),
                        onToggle: () => toggleAvailability(
                          food['id'],
                          food['is_available'] ?? true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Mini Stat ─────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  final bool isMobile;

  const _MiniStat({
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
        horizontal: isMobile ? 10 : 14,
        vertical: isMobile ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: isMobile ? 13 : 16),
          SizedBox(width: isMobile ? 5 : 8),
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

// ── Food Card ─────────────────────────────────────────────────
class _FoodCard extends StatefulWidget {
  final Map food;
  final String imageUrl;
  final Animation<double> anim;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  final bool isMobile;

  const _FoodCard({
    required this.food,
    required this.imageUrl,
    required this.anim,
    required this.onDelete,
    required this.onToggle,
    required this.isMobile,
  });

  @override
  State<_FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<_FoodCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isAvailable = widget.food['is_available'] == true;
    final name = widget.food['name'] ?? '';
    final price = widget.food['price'] ?? 0;

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
            duration: const Duration(milliseconds: 220),
            transform: Matrix4.identity()
              ..translate(0.0, _hovered ? -4.0 : 0.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hovered
                    ? const Color(0xFFFF6B35).withOpacity(0.5)
                    : Colors.white.withOpacity(0.06),
                width: 1.5,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        widget.imageUrl,
                        height: widget.isMobile ? 110 : 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : Container(
                                height: widget.isMobile ? 110 : 140,
                                color: Colors.white.withOpacity(0.05),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFFF6B35),
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                        errorBuilder: (_, __, ___) => Container(
                          height: widget.isMobile ? 110 : 140,
                          color: Colors.white.withOpacity(0.05),
                          child: const Icon(
                            Icons.fastfood_rounded,
                            size: 40,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                      ),
                    ),
                    // Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? const Color(0xFF11998E)
                              : Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAvailable ? '✓' : '✗',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Info
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(widget.isMobile ? 8 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: widget.isMobile ? 11 : 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rs $price',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFFF6B35),
                            fontSize: widget.isMobile ? 11 : 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: widget.onToggle,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAvailable
                                        ? const Color(
                                            0xFF11998E,
                                          ).withOpacity(0.15)
                                        : const Color(
                                            0xFFFF6B35,
                                          ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isAvailable
                                          ? const Color(
                                              0xFF11998E,
                                            ).withOpacity(0.4)
                                          : const Color(
                                              0xFFFF6B35,
                                            ).withOpacity(0.4),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isAvailable ? '− Remove' : '+ Add',
                                      style: GoogleFonts.poppins(
                                        color: isAvailable
                                            ? const Color(0xFF11998E)
                                            : const Color(0xFFFF6B35),
                                        fontSize: 9,
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
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                  size: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
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
              Icons.fastfood_rounded,
              size: 48,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No food items found',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + Add to create one',
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
