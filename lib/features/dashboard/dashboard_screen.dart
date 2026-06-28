import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/supabase_client.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int users = 0, orders = 0, foods = 0, categories = 0;
  double revenue = 0;
  bool loading = true;
  List recentOrders = [];

  late AnimationController _staggerController;
  late List<Animation<double>> _cardAnims;
  late AnimationController _chartController;
  late Animation<double> _chartAnim;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _cardAnims = List.generate(5, (i) {
      final start = i * 0.15;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, start + 0.4, curve: Curves.easeOut),
        ),
      );
    });
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _chartAnim = CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeOut,
    );
    loadStats();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  Future<void> loadStats() async {
    try {
      final userRes = await SupabaseService.client.from('users').select();
      final orderRes = await SupabaseService.client.from('orders').select();
      final foodRes = await SupabaseService.client.from('food_items').select();
      final catRes = await SupabaseService.client
          .from('menu_categories')
          .select();

      double total = 0;
      for (final o in orderRes) {
        total += (o['total'] ?? 0).toDouble();
      }

      final sorted = List.from(orderRes);
      sorted.sort(
        (a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''),
      );

      setState(() {
        users = userRes.length;
        orders = orderRes.length;
        foods = foodRes.length;
        categories = catRes.length;
        revenue = total;
        recentOrders = sorted.take(5).toList();
        loading = false;
      });

      _staggerController.forward();
      _chartController.forward();
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
      );
    }

    return Container(
      color: const Color(0xFF0F0F1A),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            _GreetingBanner(isMobile: isMobile),
            SizedBox(height: isMobile ? 16 : 28),

            // Stat cards
            isMobile
                ? _MobileStatCards(
                    cardAnims: _cardAnims,
                    revenue: revenue,
                    orders: orders,
                    users: users,
                    foods: foods,
                  )
                : _DesktopStatCards(
                    cardAnims: _cardAnims,
                    revenue: revenue,
                    orders: orders,
                    users: users,
                    foods: foods,
                  ),

            SizedBox(height: isMobile ? 16 : 24),

            // Chart + quick stats
            isMobile
                ? Column(
                    children: [
                      FadeTransition(
                        opacity: _chartAnim,
                        child: _AnimatedBarChart(
                          anim: _chartAnim,
                          isMobile: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeTransition(
                        opacity: _cardAnims[4],
                        child: _QuickStatsPanel(
                          orders: orders,
                          foods: foods,
                          users: users,
                          categories: categories,
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: FadeTransition(
                          opacity: _cardAnims[4],
                          child: _QuickStatsPanel(
                            orders: orders,
                            foods: foods,
                            users: users,
                            categories: categories,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: FadeTransition(
                          opacity: _chartAnim,
                          child: _AnimatedBarChart(
                            anim: _chartAnim,
                            isMobile: false,
                          ),
                        ),
                      ),
                    ],
                  ),

            SizedBox(height: isMobile ? 16 : 24),

            FadeTransition(
              opacity: _chartAnim,
              child: _RecentOrdersTable(
                orders: recentOrders,
                isMobile: isMobile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Greeting Banner ───────────────────────────────────────────
class _GreetingBanner extends StatelessWidget {
  final bool isMobile;
  const _GreetingBanner({required this.isMobile});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, Admin! 👋',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Here's AS Foods today.",
                  style: GoogleFonts.poppins(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Live Dashboard',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()}, Admin! 👋',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Here's what's happening at AS Foods today.",
                      style: GoogleFonts.poppins(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Live Dashboard',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Mobile Stat Cards (2x2 grid) ──────────────────────────────
class _MobileStatCards extends StatelessWidget {
  final List<Animation<double>> cardAnims;
  final double revenue;
  final int orders, users, foods;

  const _MobileStatCards({
    required this.cardAnims,
    required this.revenue,
    required this.orders,
    required this.users,
    required this.foods,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      {
        'title': 'Revenue',
        'value': 'Rs ${revenue.toStringAsFixed(0)}',
        'icon': Icons.attach_money_rounded,
        'gradient': [const Color(0xFFFF6B35), const Color(0xFFFF8C42)],
        'sub': 'All time',
      },
      {
        'title': 'Orders',
        'value': '$orders',
        'icon': Icons.receipt_long_rounded,
        'gradient': [const Color(0xFF6C63FF), const Color(0xFF8B85FF)],
        'sub': 'Total',
      },
      {
        'title': 'Users',
        'value': '$users',
        'icon': Icons.people_alt_rounded,
        'gradient': [const Color(0xFF11998E), const Color(0xFF38EF7D)],
        'sub': 'Registered',
      },
      {
        'title': 'Foods',
        'value': '$foods',
        'icon': Icons.fastfood_rounded,
        'gradient': [const Color(0xFFFC5C7D), const Color(0xFF6A82FB)],
        'sub': 'Menu items',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: cards.length,
      itemBuilder: (context, i) {
        final card = cards[i];
        final gradient = card['gradient'] as List<Color>;
        return FadeTransition(
          opacity: cardAnims[i],
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        card['icon'] as IconData,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card['value'] as String,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      card['title'] as String,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      card['sub'] as String,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Desktop Stat Cards (row) ──────────────────────────────────
class _DesktopStatCards extends StatelessWidget {
  final List<Animation<double>> cardAnims;
  final double revenue;
  final int orders, users, foods;

  const _DesktopStatCards({
    required this.cardAnims,
    required this.revenue,
    required this.orders,
    required this.users,
    required this.foods,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      {
        'title': 'Total Revenue',
        'value': 'Rs ${revenue.toStringAsFixed(0)}',
        'icon': Icons.attach_money_rounded,
        'gradient': [const Color(0xFFFF6B35), const Color(0xFFFF8C42)],
        'sub': 'All time earnings',
        'trend': '+12%',
      },
      {
        'title': 'Total Orders',
        'value': '$orders',
        'icon': Icons.receipt_long_rounded,
        'gradient': [const Color(0xFF6C63FF), const Color(0xFF8B85FF)],
        'sub': 'Lifetime orders',
        'trend': '+8%',
      },
      {
        'title': 'Total Users',
        'value': '$users',
        'icon': Icons.people_alt_rounded,
        'gradient': [const Color(0xFF11998E), const Color(0xFF38EF7D)],
        'sub': 'Registered accounts',
        'trend': '+5%',
      },
      {
        'title': 'Food Items',
        'value': '$foods',
        'icon': Icons.fastfood_rounded,
        'gradient': [const Color(0xFFFC5C7D), const Color(0xFF6A82FB)],
        'sub': 'Active menu items',
        'trend': '$foods items',
      },
    ];

    return Row(
      children: List.generate(cards.length, (i) {
        final card = cards[i];
        final gradient = card['gradient'] as List<Color>;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < cards.length - 1 ? 16 : 0),
            child: FadeTransition(
              opacity: cardAnims[i],
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            card['icon'] as IconData,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            card['trend'] as String,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      card['value'] as String,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      card['title'] as String,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      card['sub'] as String,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Quick Stats Panel ─────────────────────────────────────────
class _QuickStatsPanel extends StatelessWidget {
  final int orders, foods, users, categories;
  const _QuickStatsPanel({
    required this.orders,
    required this.foods,
    required this.users,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Orders', orders, Icons.receipt_long_rounded, const Color(0xFF6C63FF)),
      ('Foods', foods, Icons.fastfood_rounded, const Color(0xFFFF6B35)),
      ('Users', users, Icons.people_alt_rounded, const Color(0xFF11998E)),
      (
        'Categories',
        categories,
        Icons.category_rounded,
        const Color(0xFFFC5C7D),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Overview',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.$4.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.$3, color: item.$4, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${item.$2}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (item.$2 / max(item.$2, 1)).clamp(0.1, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: item.$4,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated Bar Chart ────────────────────────────────────────
class _AnimatedBarChart extends StatelessWidget {
  final Animation<double> anim;
  final bool isMobile;
  const _AnimatedBarChart({required this.anim, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final values = [0.4, 0.65, 0.5, 0.8, 0.7, 1.0, 0.6];
    final colors = [
      const Color(0xFFFF6B35),
      const Color(0xFF6C63FF),
      const Color(0xFF11998E),
      const Color(0xFFFF6B35),
      const Color(0xFFFC5C7D),
      const Color(0xFF6C63FF),
      const Color(0xFF11998E),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Weekly Orders',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'This Week',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFF6B35),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: isMobile ? 120 : 160,
            child: AnimatedBuilder(
              animation: anim,
              builder: (_, __) => Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (i) {
                  final h = values[i] * anim.value * (isMobile ? 90 : 130);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: isMobile ? 24 : 32,
                        height: h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [colors[i], colors[i].withOpacity(0.5)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        days[i],
                        style: GoogleFonts.poppins(
                          color: Colors.white38,
                          fontSize: isMobile ? 9 : 11,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent Orders Table ───────────────────────────────────────
class _RecentOrdersTable extends StatelessWidget {
  final List orders;
  final bool isMobile;
  const _RecentOrdersTable({required this.orders, required this.isMobile});

  Color _statusColor(String? s) {
    switch (s) {
      case 'pending':
        return const Color(0xFFFF6B35);
      case 'confirmed':
        return const Color(0xFF6C63FF);
      case 'preparing':
        return const Color(0xFFFC5C7D);
      case 'delivered':
        return const Color(0xFF11998E);
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Orders',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Last 5',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF6C63FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (orders.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No orders yet',
                  style: GoogleFonts.poppins(color: Colors.white38),
                ),
              ),
            )
          else
            ...orders.map((o) {
              final status = o['status'] ?? 'pending';
              final color = _statusColor(status);
              final orderId =
                  '#${o['id'].toString().substring(0, 8).toUpperCase()}';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                orderId,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: color,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                o['delivery_address'] ?? 'N/A',
                                style: GoogleFonts.poppins(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Rs ${o['total'] ?? 0}',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFFF6B35),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              orderId,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              o['delivery_address'] ?? 'N/A',
                              style: GoogleFonts.poppins(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Rs ${o['total'] ?? 0}',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFFF6B35),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              );
            }),
        ],
      ),
    );
  }
}
