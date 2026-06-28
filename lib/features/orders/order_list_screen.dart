import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/supabase_client.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen>
    with TickerProviderStateMixin {
  List orders = [];
  List filtered = [];
  bool loading = true;
  String selectedStatus = 'all';
  String searchQuery = '';

  late AnimationController _listController;

  final List<String> statuses = [
    'all',
    'pending',
    'confirmed',
    'preparing',
    'delivered',
    'cancelled',
  ];

  final Map<String, Map<String, dynamic>> _statusMeta = {
    'all': {
      'label': 'All',
      'icon': Icons.receipt_long_rounded,
      'color': const Color(0xFFFF6B35),
    },
    'pending': {
      'label': 'Pending',
      'icon': Icons.hourglass_empty_rounded,
      'color': const Color(0xFFF7971E),
    },
    'confirmed': {
      'label': 'Confirmed',
      'icon': Icons.check_circle_rounded,
      'color': const Color(0xFF6C63FF),
    },
    'preparing': {
      'label': 'Preparing',
      'icon': Icons.restaurant_rounded,
      'color': const Color(0xFFFC5C7D),
    },
    'delivered': {
      'label': 'Delivered',
      'icon': Icons.delivery_dining_rounded,
      'color': const Color(0xFF11998E),
    },
    'cancelled': {
      'label': 'Cancelled',
      'icon': Icons.cancel_rounded,
      'color': Colors.red,
    },
  };

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    fetchOrders();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> fetchOrders() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      final res = await SupabaseService.client
          .from('orders')
          .select()
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        orders = List.from(res);
        _applyFilter();
        loading = false;
      });
      _listController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  void _applyFilter() {
    List temp = List.from(orders);
    if (selectedStatus != 'all') {
      temp = temp.where((o) => o['status'] == selectedStatus).toList();
    }
    if (searchQuery.isNotEmpty) {
      temp = temp.where((o) {
        final id = (o['id'] ?? '').toString().toLowerCase();
        final addr = (o['delivery_address'] ?? '').toString().toLowerCase();
        final q = searchQuery.toLowerCase();
        return id.contains(q) || addr.contains(q);
      }).toList();
    }
    filtered = temp;
  }

  Future<void> updateStatus(String id, String newStatus) async {
    await SupabaseService.client
        .from('orders')
        .update({'status': newStatus})
        .eq('id', id);
    fetchOrders();
    _showSnack(
      'Updated to ${newStatus.toUpperCase()}',
      _statusMeta[newStatus]!['color'] as Color,
    );
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

  int _countStatus(String s) =>
      s == 'all' ? orders.length : orders.where((o) => o['status'] == s).length;

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
              isMobile ? 12 : 16,
              isMobile ? 14 : 24,
              isMobile ? 10 : 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
              ),
            ),
            child: Column(
              children: [
                // Search + refresh row
                Row(
                  children: [
                    Expanded(
                      child: Container(
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
                            hintText: isMobile
                                ? 'Search orders...'
                                : 'Search by order ID or address...',
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
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: fetchOrders,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white54,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${filtered.length}',
                      style: GoogleFonts.poppins(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Status filter tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: statuses.map((s) {
                      final meta = _statusMeta[s]!;
                      final selected = selectedStatus == s;
                      final count = _countStatus(s);
                      final color = meta['color'] as Color;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            selectedStatus = s;
                            _applyFilter();
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 10 : 14,
                              vertical: isMobile ? 6 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? color : color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? color
                                    : color.withOpacity(0.2),
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.3),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  meta['icon'] as IconData,
                                  size: isMobile ? 12 : 14,
                                  color: selected ? Colors.white : color,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  meta['label'] as String,
                                  style: GoogleFonts.poppins(
                                    color: selected ? Colors.white : color,
                                    fontSize: isMobile ? 10 : 12,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? Colors.white.withOpacity(0.25)
                                        : color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: GoogleFonts.poppins(
                                      color: selected ? Colors.white : color,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Orders list ──────────────────────────────────────
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                  )
                : filtered.isEmpty
                ? _EmptyOrders(status: selectedStatus)
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 14 : 20,
                      isMobile ? 12 : 20,
                      isMobile ? 14 : 20,
                      isMobile ? 80 : 20,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      final delay = (index % 10) * 0.06;
                      final anim = Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _listController,
                          curve: Interval(
                            delay.clamp(0.0, 0.8),
                            (delay + 0.3).clamp(0.0, 1.0),
                            curve: Curves.easeOut,
                          ),
                        ),
                      );
                      return _OrderCard(
                        order: order,
                        anim: anim,
                        isMobile: isMobile,
                        statusMeta: _statusMeta,
                        onUpdateStatus: updateStatus,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Order Card ────────────────────────────────────────────────
class _OrderCard extends StatefulWidget {
  final Map order;
  final Animation<double> anim;
  final bool isMobile;
  final Map<String, Map<String, dynamic>> statusMeta;
  final Function(String id, String status) onUpdateStatus;

  const _OrderCard({
    required this.order,
    required this.anim,
    required this.isMobile,
    required this.statusMeta,
    required this.onUpdateStatus,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = order['status'] ?? 'pending';
    final meta = widget.statusMeta[status] ?? widget.statusMeta['pending']!;
    final color = meta['color'] as Color;
    final orderId = '#${order['id'].toString().substring(0, 8).toUpperCase()}';

    final nextStatuses = {
      'pending': ['confirmed', 'cancelled'],
      'confirmed': ['preparing', 'cancelled'],
      'preparing': ['delivered', 'cancelled'],
      'delivered': <String>[],
      'cancelled': <String>[],
    };
    final actions = nextStatuses[status] ?? [];

    return FadeTransition(
      opacity: widget.anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(widget.anim),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // ── Main row ────────────────────────────────────
              Padding(
                padding: EdgeInsets.all(widget.isMobile ? 12 : 18),
                child: Row(
                  children: [
                    // Status icon
                    Container(
                      width: widget.isMobile ? 38 : 46,
                      height: widget.isMobile ? 38 : 46,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(
                          widget.isMobile ? 10 : 13,
                        ),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Icon(
                        meta['icon'] as IconData,
                        color: color,
                        size: widget.isMobile ? 18 : 22,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orderId,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: widget.isMobile ? 13 : 15,
                            ),
                          ),
                          if (order['delivery_address'] != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 11,
                                  color: Color(0xFFFF6B35),
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    order['delivery_address'],
                                    style: GoogleFonts.poppins(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Price + status
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rs ${order['total'] ?? 0}',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFFF6B35),
                            fontWeight: FontWeight.w800,
                            fontSize: widget.isMobile ? 13 : 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withOpacity(0.35)),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: color,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 8),

                    // Expand button
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white38,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Expanded panel ───────────────────────────────
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  margin: EdgeInsets.fromLTRB(
                    widget.isMobile ? 12 : 18,
                    0,
                    widget.isMobile ? 12 : 18,
                    widget.isMobile ? 12 : 18,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price breakdown
                      _PriceLine(
                        'Subtotal',
                        'Rs ${order['subtotal'] ?? 0}',
                        Colors.white54,
                      ),
                      _PriceLine(
                        'Delivery Fee',
                        'Rs ${order['delivery_fee'] ?? 0}',
                        Colors.white54,
                      ),
                      const Divider(color: Colors.white10, height: 14),
                      _PriceLine(
                        'Total',
                        'Rs ${order['total'] ?? 0}',
                        const Color(0xFFFF6B35),
                        bold: true,
                      ),

                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Update Status',
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: actions.map((s) {
                            final m = widget.statusMeta[s]!;
                            final c = m['color'] as Color;
                            return GestureDetector(
                              onTap: () =>
                                  widget.onUpdateStatus(order['id'], s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: c.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: c.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      m['icon'] as IconData,
                                      size: 14,
                                      color: c,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      m['label'] as String,
                                      style: GoogleFonts.poppins(
                                        color: c,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ] else
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                meta['icon'] as IconData,
                                size: 13,
                                color: color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${status.toUpperCase()} — no further actions',
                                style: GoogleFonts.poppins(
                                  color: color,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Price Line ────────────────────────────────────────────────
class _PriceLine extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool bold;

  const _PriceLine(this.label, this.value, this.color, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: bold ? 13 : 11,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty Orders ──────────────────────────────────────────────
class _EmptyOrders extends StatelessWidget {
  final String status;
  const _EmptyOrders({required this.status});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            status == 'all'
                ? 'No orders yet'
                : 'No ${status.toUpperCase()} orders',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Orders will appear here',
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
