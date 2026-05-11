import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bool kScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');
const String _storageKey = 'morgant_thierry_operations_v1';

void main() {
  runApp(const MorgantThierryApp());
}

class MorgantThierryApp extends StatelessWidget {
  const MorgantThierryApp({super.key});

  @override
  Widget build(BuildContext context) {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.aqua,
      onSecondary: AppColors.navy,
      error: AppColors.alert,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
    );

    return MaterialApp(
      title: 'MORGANT THIERRY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.ink,
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.line),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.aqua.withValues(alpha: .16),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
      home: const OperationsHome(),
    );
  }
}

class AppColors {
  static const Color navy = Color(0xFF051743);
  static const Color primary = Color(0xFF086BE8);
  static const Color aqua = Color(0xFF15CAD0);
  static const Color ink = Color(0xFF132238);
  static const Color muted = Color(0xFF5B6B82);
  static const Color background = Color(0xFFF3F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFD9E5F0);
  static const Color success = Color(0xFF0A8F6A);
  static const Color warning = Color(0xFFE18A00);
  static const Color alert = Color(0xFFCB3A31);
}

class OperationsHome extends StatefulWidget {
  const OperationsHome({super.key});

  @override
  State<OperationsHome> createState() => _OperationsHomeState();
}

class _OperationsHomeState extends State<OperationsHome> {
  OperationsData _data = OperationsData.empty();
  int _index = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (kScreenshotMode) {
      setState(() {
        _data = OperationsData.seeded();
        _loaded = true;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (!mounted) {
      return;
    }

    setState(() {
      if (raw == null) {
        _data = OperationsData.seeded();
      } else {
        _data = OperationsData.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
      _loaded = true;
    });
  }

  Future<void> _persist(OperationsData next) async {
    setState(() => _data = next);
    if (kScreenshotMode) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(next.toJson()));
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          data: _data,
          onClear: () => _persist(OperationsData.empty()),
        ),
      ),
    );
  }

  Future<void> _showActionSheet() async {
    switch (_index) {
      case 1:
        return _showInventorySheet();
      case 2:
        return _showOrderSheet();
      case 3:
        return _showReservationSheet();
      case 4:
        return _showReportSheet();
      default:
        setState(() => _index = 1);
        return _showInventorySheet();
    }
  }

  Future<void> _showInventorySheet() async {
    final item = await showModalBottomSheet<InventoryItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const InventoryFormSheet(),
    );
    if (item == null) {
      return;
    }
    await _persist(_data.copyWith(inventory: [item, ..._data.inventory]));
  }

  Future<void> _showOrderSheet() async {
    final order = await showModalBottomSheet<SupplyOrder>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const OrderFormSheet(),
    );
    if (order == null) {
      return;
    }
    await _persist(_data.copyWith(orders: [order, ..._data.orders]));
  }

  Future<void> _showReservationSheet() async {
    final reservation = await showModalBottomSheet<Reservation>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const ReservationFormSheet(),
    );
    if (reservation == null) {
      return;
    }
    await _persist(
      _data.copyWith(reservations: [reservation, ..._data.reservations]),
    );
  }

  Future<void> _showReportSheet() async {
    final report = await showModalBottomSheet<ComplianceReport>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const ReportFormSheet(),
    );
    if (report == null) {
      return;
    }
    await _persist(_data.copyWith(reports: [report, ..._data.reports]));
  }

  void _updateInventory(InventoryItem updated) {
    final next = _data.inventory
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
    _persist(_data.copyWith(inventory: next));
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        data: _data,
        onSelectInventory: () => setState(() => _index = 1),
        onSelectOrders: () => setState(() => _index = 2),
        onSelectReports: () => setState(() => _index = 4),
      ),
      InventoryScreen(data: _data.inventory, onUpdate: _updateInventory),
      OrdersScreen(orders: _data.orders),
      ReservationsScreen(reservations: _data.reservations),
      ComplianceScreen(reports: _data.reports),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MORGANT THIERRY',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .4),
            ),
            SizedBox(height: 2),
            Text(
              'Operations control',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Tooltip(
              message: 'Local mode',
              child: Chip(
                avatar: const Icon(Icons.offline_pin_outlined, size: 16),
                label: const Text('Offline'),
                visualDensity: VisualDensity.compact,
                side: const BorderSide(color: AppColors.line),
                backgroundColor: Colors.white,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Settings and privacy',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _loaded
            ? screens[_index]
            : const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: _loaded
          ? FloatingActionButton.extended(
              onPressed: _showActionSheet,
              icon: Icon(_actionIcon),
              label: Text(_actionLabel),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Command',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'Books',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  IconData get _actionIcon {
    switch (_index) {
      case 2:
        return Icons.add_shopping_cart_outlined;
      case 3:
        return Icons.event_note_outlined;
      case 4:
        return Icons.fact_check_outlined;
      default:
        return Icons.add_box_outlined;
    }
  }

  String get _actionLabel {
    switch (_index) {
      case 2:
        return 'New order';
      case 3:
        return 'Reserve';
      case 4:
        return 'New report';
      default:
        return 'Add item';
    }
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.data,
    required this.onSelectInventory,
    required this.onSelectOrders,
    required this.onSelectReports,
    super.key,
  });

  final OperationsData data;
  final VoidCallback onSelectInventory;
  final VoidCallback onSelectOrders;
  final VoidCallback onSelectReports;

  @override
  Widget build(BuildContext context) {
    final atRisk = data.inventory.where((item) => item.isAtRisk).length;
    final pendingOrders = data.orders
        .where((order) => order.status != OrderStatus.received)
        .length;
    final reservationsToday = data.reservations
        .where((reservation) => isSameDay(reservation.time, DateTime.now()))
        .length;
    final dueReports = data.reports
        .where((report) => report.status != ReportStatus.filed)
        .length;

    return ListView(
      key: const ValueKey('dashboard'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(8),
            image: const DecorationImage(
              image: AssetImage('docs/featured.png'),
              alignment: Alignment.centerRight,
              fit: BoxFit.cover,
              opacity: .18,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('docs/icon.png', width: 48, height: 48),
              const SizedBox(height: 18),
              const Text(
                'Daily operations board',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Inventory, orders, reservations, and compliance stay together in local device storage.',
                style: TextStyle(
                  color: Color(0xFFD9F9FF),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  StatusPill(
                    icon: Icons.shield_outlined,
                    label: 'No cloud sync',
                    dark: true,
                  ),
                  StatusPill(
                    icon: Icons.update,
                    label: 'Live local board',
                    dark: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 720 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.16,
          children: [
            MetricCard(
              icon: Icons.warning_amber_outlined,
              label: 'Stock risks',
              value: '$atRisk',
              color: atRisk == 0 ? AppColors.success : AppColors.warning,
              onTap: onSelectInventory,
            ),
            MetricCard(
              icon: Icons.local_shipping_outlined,
              label: 'Orders open',
              value: '$pendingOrders',
              color: AppColors.primary,
              onTap: onSelectOrders,
            ),
            MetricCard(
              icon: Icons.event_available_outlined,
              label: 'Today booked',
              value: '$reservationsToday',
              color: AppColors.aqua,
            ),
            MetricCard(
              icon: Icons.fact_check_outlined,
              label: 'Reports due',
              value: '$dueReports',
              color: dueReports == 0 ? AppColors.success : AppColors.alert,
              onTap: onSelectReports,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Priority queue',
          action: TextButton.icon(
            onPressed: onSelectInventory,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Review stock'),
          ),
          child: Column(
            children: [
              for (final item in data.priorityItems.take(4))
                PriorityRow(
                  icon: item.icon,
                  title: item.title,
                  subtitle: item.subtitle,
                  status: item.status,
                  color: item.color,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Reservation timeline',
          child: Column(
            children: [
              for (final reservation in data.reservations.take(3))
                TimelineRow(
                  time: formatTime(reservation.time),
                  title: reservation.client,
                  subtitle:
                      '${reservation.area} - ${reservation.partySize} guests',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({
    required this.data,
    required this.onUpdate,
    super.key,
  });

  final List<InventoryItem> data;
  final ValueChanged<InventoryItem> onUpdate;

  @override
  Widget build(BuildContext context) {
    final total = data.fold<int>(0, (sum, item) => sum + item.quantity);
    final atRisk = data.where((item) => item.isAtRisk).length;

    return ListView(
      key: const ValueKey('inventory'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        ScreenHeader(
          icon: Icons.inventory_2_outlined,
          title: 'Inventory tracking',
          subtitle:
              '$total units tracked across ${data.length} item groups. $atRisk require action.',
        ),
        const SizedBox(height: 12),
        for (final item in data)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InventoryCard(
              item: item,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      InventoryDetailScreen(item: item, onUpdate: onUpdate),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class InventoryCard extends StatelessWidget {
  const InventoryCard({required this.item, required this.onTap, super.key});

  final InventoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = (item.quantity / item.targetQuantity).clamp(0, 1).toDouble();

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    item.isAtRisk
                        ? Icons.warning_amber_outlined
                        : Icons.check_circle_outline,
                    color: item.isAtRisk
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  StatusPill(
                    label: item.isAtRisk ? 'Reorder' : 'Covered',
                    icon: item.isAtRisk
                        ? Icons.priority_high
                        : Icons.done_all_outlined,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 9,
                  backgroundColor: AppColors.line,
                  color: item.isAtRisk ? AppColors.warning : AppColors.aqua,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${item.quantity} in stock - target ${item.targetQuantity} - ${item.location}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.note,
                style: const TextStyle(color: AppColors.ink, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InventoryDetailScreen extends StatelessWidget {
  const InventoryDetailScreen({
    required this.item,
    required this.onUpdate,
    super.key,
  });

  final InventoryItem item;
  final ValueChanged<InventoryItem> onUpdate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory detail')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SectionCard(
            title: item.name,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DetailTile(
                        label: 'Current stock',
                        value: '${item.quantity}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DetailTile(
                        label: 'Target level',
                        value: '${item.targetQuantity}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DetailTile(label: 'Storage location', value: item.location),
                const SizedBox(height: 12),
                DetailTile(
                  label: 'Last count',
                  value: formatDate(item.updatedAt),
                ),
                const SizedBox(height: 16),
                Text(item.note, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              onUpdate(
                item.copyWith(
                  quantity: item.targetQuantity,
                  updatedAt: DateTime.now(),
                  note: 'Count completed and target quantity confirmed.',
                ),
              );
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.done_all_outlined),
            label: const Text('Mark counted'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              onUpdate(
                item.copyWith(
                  quantity: item.minimumQuantity,
                  updatedAt: DateTime.now(),
                  note: 'Reorder check flagged for the next supply run.',
                ),
              );
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Flag reorder'),
          ),
        ],
      ),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({required this.orders, super.key});

  final List<SupplyOrder> orders;

  @override
  Widget build(BuildContext context) {
    final received = orders.where(
      (order) => order.status == OrderStatus.received,
    );
    final value = orders.fold<double>(
      0,
      (sum, order) => sum + order.estimatedCost,
    );

    return ListView(
      key: const ValueKey('orders'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        ScreenHeader(
          icon: Icons.local_shipping_outlined,
          title: 'Supply ordering',
          subtitle:
              '${orders.length} orders planned, ${received.length} received, ${currency(value)} estimated.',
        ),
        const SizedBox(height: 12),
        for (final order in orders)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SectionCard(
              title: order.itemName,
              action: StatusPill(
                label: order.status.label,
                icon: order.status.icon,
                compact: true,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoLine(icon: Icons.store_outlined, text: order.vendor),
                  InfoLine(
                    icon: Icons.inventory_outlined,
                    text: '${order.quantity} units requested',
                  ),
                  InfoLine(
                    icon: Icons.calendar_today_outlined,
                    text: 'Needed by ${formatDate(order.neededBy)}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.note,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({required this.reservations, super.key});

  final List<Reservation> reservations;

  @override
  Widget build(BuildContext context) {
    final guests = reservations.fold<int>(
      0,
      (sum, reservation) => sum + reservation.partySize,
    );

    return ListView(
      key: const ValueKey('reservations'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        ScreenHeader(
          icon: Icons.event_available_outlined,
          title: 'Reservation management',
          subtitle:
              '${reservations.length} bookings on the board with $guests expected guests.',
        ),
        const SizedBox(height: 12),
        for (final reservation in reservations)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 68,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            formatDay(reservation.time),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            formatTime(reservation.time),
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reservation.client,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${reservation.area} - ${reservation.partySize} guests',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(reservation.note),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ComplianceScreen extends StatelessWidget {
  const ComplianceScreen({required this.reports, super.key});

  final List<ComplianceReport> reports;

  @override
  Widget build(BuildContext context) {
    final open = reports.where((report) => report.status != ReportStatus.filed);

    return ListView(
      key: const ValueKey('compliance'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        ScreenHeader(
          icon: Icons.verified_user_outlined,
          title: 'Compliance reporting',
          subtitle:
              '${open.length} reports need attention before the next close.',
        ),
        const SizedBox(height: 12),
        for (final report in reports)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SectionCard(
              title: report.title,
              action: StatusPill(
                label: report.status.label,
                icon: report.status.icon,
                compact: true,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoLine(icon: Icons.business_outlined, text: report.area),
                  InfoLine(
                    icon: Icons.calendar_month_outlined,
                    text: 'Due ${formatDate(report.dueDate)}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.note,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.data, required this.onClear, super.key});

  final OperationsData data;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings and privacy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const ScreenHeader(
            icon: Icons.settings_outlined,
            title: 'Local workspace',
            subtitle:
                'Business records are stored on this device with no account, sync, analytics, or external service.',
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Workspace totals',
            child: Column(
              children: [
                InfoLine(
                  icon: Icons.inventory_2_outlined,
                  text: '${data.inventory.length} inventory groups',
                ),
                InfoLine(
                  icon: Icons.local_shipping_outlined,
                  text: '${data.orders.length} supply orders',
                ),
                InfoLine(
                  icon: Icons.event_available_outlined,
                  text: '${data.reservations.length} reservations',
                ),
                InfoLine(
                  icon: Icons.verified_user_outlined,
                  text: '${data.reports.length} compliance reports',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SectionCard(
            title: 'Privacy posture',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoLine(
                  icon: Icons.cloud_off_outlined,
                  text: 'No cloud upload or remote account registration',
                ),
                InfoLine(
                  icon: Icons.analytics_outlined,
                  text: 'No analytics, ads, contacts, camera, or location',
                ),
                InfoLine(
                  icon: Icons.lock_outline,
                  text: 'Records remain inside local Android app storage',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: kScreenshotMode
                ? null
                : () {
                    onClear();
                    Navigator.of(context).pop();
                  },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Clear local records'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Support: contact@morgantthierry.app',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class InventoryFormSheet extends StatefulWidget {
  const InventoryFormSheet({super.key});

  @override
  State<InventoryFormSheet> createState() => _InventoryFormSheetState();
}

class _InventoryFormSheetState extends State<InventoryFormSheet> {
  final _name = TextEditingController();
  final _location = TextEditingController(text: 'Main storage');
  final _quantity = TextEditingController(text: '12');
  final _minimum = TextEditingController(text: '6');
  final _target = TextEditingController(text: '18');
  final _note = TextEditingController(text: 'Added during the current count.');

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _quantity.dispose();
    _minimum.dispose();
    _target.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetFrame(
      title: 'Add inventory item',
      children: [
        TextField(
          controller: _name,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Item name'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _location,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Storage location'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: NumberField(controller: _quantity, label: 'Current'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: NumberField(controller: _minimum, label: 'Minimum'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: NumberField(controller: _target, label: 'Target'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _note,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Operational note'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              InventoryItem(
                id: uniqueId('stock'),
                name: name,
                quantity: parseInt(_quantity.text, fallback: 0),
                minimumQuantity: parseInt(_minimum.text, fallback: 0),
                targetQuantity: parseInt(_target.text, fallback: 1),
                location: _location.text.trim().isEmpty
                    ? 'Main storage'
                    : _location.text.trim(),
                note: _note.text.trim().isEmpty
                    ? 'Added during the current count.'
                    : _note.text.trim(),
                updatedAt: DateTime.now(),
              ),
            );
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save item'),
        ),
      ],
    );
  }
}

class OrderFormSheet extends StatefulWidget {
  const OrderFormSheet({super.key});

  @override
  State<OrderFormSheet> createState() => _OrderFormSheetState();
}

class _OrderFormSheetState extends State<OrderFormSheet> {
  final _item = TextEditingController();
  final _vendor = TextEditingController(text: 'Approved supplier');
  final _quantity = TextEditingController(text: '24');
  final _cost = TextEditingController(text: '420');
  final _note = TextEditingController(
    text: 'Link order to current stock risk.',
  );

  @override
  void dispose() {
    _item.dispose();
    _vendor.dispose();
    _quantity.dispose();
    _cost.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetFrame(
      title: 'Create supply order',
      children: [
        TextField(
          controller: _item,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Item or supply'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _vendor,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Supplier'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: NumberField(controller: _quantity, label: 'Quantity'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DecimalField(controller: _cost, label: 'Est. cost'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _note,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Order note'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            final item = _item.text.trim();
            if (item.isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              SupplyOrder(
                id: uniqueId('order'),
                vendor: _vendor.text.trim().isEmpty
                    ? 'Approved supplier'
                    : _vendor.text.trim(),
                itemName: item,
                quantity: parseInt(_quantity.text, fallback: 1),
                status: OrderStatus.requested,
                neededBy: DateTime.now().add(const Duration(days: 3)),
                estimatedCost: double.tryParse(_cost.text.trim()) ?? 0,
                note: _note.text.trim().isEmpty
                    ? 'Order created from the operations board.'
                    : _note.text.trim(),
              ),
            );
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save order'),
        ),
      ],
    );
  }
}

class ReservationFormSheet extends StatefulWidget {
  const ReservationFormSheet({super.key});

  @override
  State<ReservationFormSheet> createState() => _ReservationFormSheetState();
}

class _ReservationFormSheetState extends State<ReservationFormSheet> {
  final _client = TextEditingController();
  final _area = TextEditingController(text: 'Main floor');
  final _guests = TextEditingController(text: '4');
  final _note = TextEditingController(text: 'Confirm setup before arrival.');

  @override
  void dispose() {
    _client.dispose();
    _area.dispose();
    _guests.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetFrame(
      title: 'Create reservation',
      children: [
        TextField(
          controller: _client,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Client or group'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _area,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Area'),
        ),
        const SizedBox(height: 10),
        NumberField(controller: _guests, label: 'Guests'),
        const SizedBox(height: 10),
        TextField(
          controller: _note,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Reservation note'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            final client = _client.text.trim();
            if (client.isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              Reservation(
                id: uniqueId('booking'),
                client: client,
                area: _area.text.trim().isEmpty
                    ? 'Main floor'
                    : _area.text.trim(),
                time: DateTime.now().add(const Duration(hours: 4)),
                partySize: parseInt(_guests.text, fallback: 1),
                note: _note.text.trim().isEmpty
                    ? 'Confirm setup before arrival.'
                    : _note.text.trim(),
              ),
            );
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save reservation'),
        ),
      ],
    );
  }
}

class ReportFormSheet extends StatefulWidget {
  const ReportFormSheet({super.key});

  @override
  State<ReportFormSheet> createState() => _ReportFormSheetState();
}

class _ReportFormSheetState extends State<ReportFormSheet> {
  final _title = TextEditingController();
  final _area = TextEditingController(text: 'Operations');
  final _note = TextEditingController(text: 'Checklist started by duty lead.');

  @override
  void dispose() {
    _title.dispose();
    _area.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetFrame(
      title: 'New compliance report',
      children: [
        TextField(
          controller: _title,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Report title'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _area,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Business area'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _note,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Report note'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            final title = _title.text.trim();
            if (title.isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              ComplianceReport(
                id: uniqueId('report'),
                title: title,
                area: _area.text.trim().isEmpty
                    ? 'Operations'
                    : _area.text.trim(),
                status: ReportStatus.due,
                dueDate: DateTime.now().add(const Duration(days: 2)),
                note: _note.text.trim().isEmpty
                    ? 'Checklist started by duty lead.'
                    : _note.text.trim(),
              ),
            );
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save report'),
        ),
      ],
    );
  }
}

class FormSheetFrame extends StatelessWidget {
  const FormSheetFrame({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class NumberField extends StatelessWidget {
  const NumberField({required this.controller, required this.label, super.key});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
    );
  }
}

class DecimalField extends StatelessWidget {
  const DecimalField({
    required this.controller,
    required this.label,
    super.key,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.child,
    this.action,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.icon,
    this.dark = false,
    this.compact = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool dark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final background = dark
        ? Colors.white.withValues(alpha: .12)
        : AppColors.aqua.withValues(alpha: .12);
    final foreground = dark ? Colors.white : AppColors.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark ? Colors.white.withValues(alpha: .2) : AppColors.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: compact ? 14 : 16),
          SizedBox(width: compact ? 4 : 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class PriorityRow extends StatelessWidget {
  const PriorityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class TimelineRow extends StatelessWidget {
  const TimelineRow({
    required this.time,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String time;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              time,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(width: 1, height: 42, color: AppColors.line),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
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

class DetailTile extends StatelessWidget {
  const DetailTile({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class InfoLine extends StatelessWidget {
  const InfoLine({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

class OperationsData {
  const OperationsData({
    required this.inventory,
    required this.orders,
    required this.reservations,
    required this.reports,
  });

  final List<InventoryItem> inventory;
  final List<SupplyOrder> orders;
  final List<Reservation> reservations;
  final List<ComplianceReport> reports;

  factory OperationsData.empty() => const OperationsData(
    inventory: [],
    orders: [],
    reservations: [],
    reports: [],
  );

  factory OperationsData.seeded() {
    final now = DateTime.now();
    return OperationsData(
      inventory: [
        InventoryItem(
          id: 'stock-packaging',
          name: 'Tamper seal packaging',
          quantity: 18,
          minimumQuantity: 20,
          targetQuantity: 70,
          location: 'Aisle 2 / Bin 4',
          note:
              'Below minimum after weekend dispatch. Add to next supplier run.',
          updatedAt: now.subtract(const Duration(hours: 5)),
        ),
        InventoryItem(
          id: 'stock-tablets',
          name: 'Service tablets',
          quantity: 11,
          minimumQuantity: 5,
          targetQuantity: 12,
          location: 'Front office locker',
          note: 'All active devices checked and assigned to shift leads.',
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
        InventoryItem(
          id: 'stock-cleaning',
          name: 'Cleaning concentrate',
          quantity: 7,
          minimumQuantity: 10,
          targetQuantity: 36,
          location: 'Back room shelf C',
          note: 'Usage elevated this week. Confirm delivery before Friday.',
          updatedAt: now.subtract(const Duration(hours: 10)),
        ),
        InventoryItem(
          id: 'stock-forms',
          name: 'Compliance forms',
          quantity: 42,
          minimumQuantity: 12,
          targetQuantity: 45,
          location: 'Admin cabinet',
          note: 'Ready for the next reporting cycle.',
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
      ],
      orders: [
        SupplyOrder(
          id: 'order-seals',
          vendor: 'Northline Supplies',
          itemName: 'Tamper seal packaging',
          quantity: 60,
          status: OrderStatus.requested,
          neededBy: now.add(const Duration(days: 2)),
          estimatedCost: 680,
          note: 'Prioritize because current stock is below minimum.',
        ),
        SupplyOrder(
          id: 'order-concentrate',
          vendor: 'CleanCore Pro',
          itemName: 'Cleaning concentrate',
          quantity: 30,
          status: OrderStatus.approved,
          neededBy: now.add(const Duration(days: 4)),
          estimatedCost: 340,
          note: 'Approved by operations lead and ready for pickup.',
        ),
        SupplyOrder(
          id: 'order-badges',
          vendor: 'Atlas Office',
          itemName: 'Visitor badges',
          quantity: 100,
          status: OrderStatus.received,
          neededBy: now.subtract(const Duration(days: 1)),
          estimatedCost: 95,
          note: 'Received and placed in front office storage.',
        ),
      ],
      reservations: [
        Reservation(
          id: 'booking-amira',
          client: 'Amira group',
          area: 'Conference room A',
          time: DateTime(now.year, now.month, now.day, 10, 30),
          partySize: 8,
          note: 'Prepare projector, water service, and visitor badges.',
        ),
        Reservation(
          id: 'booking-galaxy',
          client: 'Galaxy Logistics',
          area: 'Loading bay 2',
          time: DateTime(now.year, now.month, now.day, 14, 0),
          partySize: 3,
          note: 'Hold receiving team for compliance handoff.',
        ),
        Reservation(
          id: 'booking-board',
          client: 'Board review',
          area: 'Main meeting room',
          time: DateTime(now.year, now.month, now.day + 1, 9, 0),
          partySize: 12,
          note: 'Stock room report must be printed before arrival.',
        ),
      ],
      reports: [
        ComplianceReport(
          id: 'report-stock',
          title: 'Inventory variance review',
          area: 'Warehouse',
          status: ReportStatus.due,
          dueDate: now.add(const Duration(days: 1)),
          note: 'Reconcile count sheet against supply order receipts.',
        ),
        ComplianceReport(
          id: 'report-safety',
          title: 'Safety walk checklist',
          area: 'Operations floor',
          status: ReportStatus.inProgress,
          dueDate: now.add(const Duration(days: 2)),
          note: 'Two corrective actions assigned to shift supervisors.',
        ),
        ComplianceReport(
          id: 'report-archive',
          title: 'Monthly archive',
          area: 'Administration',
          status: ReportStatus.filed,
          dueDate: now.subtract(const Duration(days: 3)),
          note: 'Signed copy retained in local records.',
        ),
      ],
    );
  }

  factory OperationsData.fromJson(Map<String, dynamic> json) => OperationsData(
    inventory: (json['inventory'] as List<dynamic>? ?? [])
        .map((item) => InventoryItem.fromJson(item as Map<String, dynamic>))
        .toList(),
    orders: (json['orders'] as List<dynamic>? ?? [])
        .map((item) => SupplyOrder.fromJson(item as Map<String, dynamic>))
        .toList(),
    reservations: (json['reservations'] as List<dynamic>? ?? [])
        .map((item) => Reservation.fromJson(item as Map<String, dynamic>))
        .toList(),
    reports: (json['reports'] as List<dynamic>? ?? [])
        .map((item) => ComplianceReport.fromJson(item as Map<String, dynamic>))
        .toList(),
  );

  List<PriorityItem> get priorityItems {
    final items = <PriorityItem>[
      for (final item in inventory.where((item) => item.isAtRisk))
        PriorityItem(
          icon: Icons.inventory_2_outlined,
          title: item.name,
          subtitle: '${item.quantity} on hand in ${item.location}',
          status: 'Stock',
          color: AppColors.warning,
        ),
      for (final order in orders.where(
        (order) => order.status == OrderStatus.requested,
      ))
        PriorityItem(
          icon: Icons.local_shipping_outlined,
          title: order.itemName,
          subtitle: '${order.vendor} - due ${formatDate(order.neededBy)}',
          status: 'Order',
          color: AppColors.primary,
        ),
      for (final report in reports.where(
        (report) => report.status == ReportStatus.due,
      ))
        PriorityItem(
          icon: Icons.verified_user_outlined,
          title: report.title,
          subtitle: '${report.area} - due ${formatDate(report.dueDate)}',
          status: 'Report',
          color: AppColors.alert,
        ),
    ];
    if (items.isEmpty) {
      return [
        const PriorityItem(
          icon: Icons.check_circle_outline,
          title: 'Operations are balanced',
          subtitle: 'No stock, order, or reporting item is overdue.',
          status: 'Clear',
          color: AppColors.success,
        ),
      ];
    }
    return items;
  }

  OperationsData copyWith({
    List<InventoryItem>? inventory,
    List<SupplyOrder>? orders,
    List<Reservation>? reservations,
    List<ComplianceReport>? reports,
  }) {
    return OperationsData(
      inventory: inventory ?? this.inventory,
      orders: orders ?? this.orders,
      reservations: reservations ?? this.reservations,
      reports: reports ?? this.reports,
    );
  }

  Map<String, dynamic> toJson() => {
    'inventory': inventory.map((item) => item.toJson()).toList(),
    'orders': orders.map((item) => item.toJson()).toList(),
    'reservations': reservations.map((item) => item.toJson()).toList(),
    'reports': reports.map((item) => item.toJson()).toList(),
  };
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.minimumQuantity,
    required this.targetQuantity,
    required this.location,
    required this.note,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int quantity;
  final int minimumQuantity;
  final int targetQuantity;
  final String location;
  final String note;
  final DateTime updatedAt;

  bool get isAtRisk => quantity <= minimumQuantity;

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    id: json['id'] as String? ?? uniqueId('stock'),
    name: json['name'] as String? ?? 'Untitled item',
    quantity: json['quantity'] as int? ?? 0,
    minimumQuantity: json['minimumQuantity'] as int? ?? 0,
    targetQuantity: json['targetQuantity'] as int? ?? 1,
    location: json['location'] as String? ?? 'Main storage',
    note: json['note'] as String? ?? '',
    updatedAt: parseDate(json['updatedAt'] as String?),
  );

  InventoryItem copyWith({int? quantity, String? note, DateTime? updatedAt}) {
    return InventoryItem(
      id: id,
      name: name,
      quantity: quantity ?? this.quantity,
      minimumQuantity: minimumQuantity,
      targetQuantity: targetQuantity,
      location: location,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'minimumQuantity': minimumQuantity,
    'targetQuantity': targetQuantity,
    'location': location,
    'note': note,
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class SupplyOrder {
  const SupplyOrder({
    required this.id,
    required this.vendor,
    required this.itemName,
    required this.quantity,
    required this.status,
    required this.neededBy,
    required this.estimatedCost,
    required this.note,
  });

  final String id;
  final String vendor;
  final String itemName;
  final int quantity;
  final OrderStatus status;
  final DateTime neededBy;
  final double estimatedCost;
  final String note;

  factory SupplyOrder.fromJson(Map<String, dynamic> json) => SupplyOrder(
    id: json['id'] as String? ?? uniqueId('order'),
    vendor: json['vendor'] as String? ?? 'Supplier',
    itemName: json['itemName'] as String? ?? 'Supply item',
    quantity: json['quantity'] as int? ?? 1,
    status: OrderStatusX.fromName(json['status'] as String?),
    neededBy: parseDate(json['neededBy'] as String?),
    estimatedCost: (json['estimatedCost'] as num?)?.toDouble() ?? 0,
    note: json['note'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'vendor': vendor,
    'itemName': itemName,
    'quantity': quantity,
    'status': status.name,
    'neededBy': neededBy.toIso8601String(),
    'estimatedCost': estimatedCost,
    'note': note,
  };
}

class Reservation {
  const Reservation({
    required this.id,
    required this.client,
    required this.area,
    required this.time,
    required this.partySize,
    required this.note,
  });

  final String id;
  final String client;
  final String area;
  final DateTime time;
  final int partySize;
  final String note;

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
    id: json['id'] as String? ?? uniqueId('booking'),
    client: json['client'] as String? ?? 'Client',
    area: json['area'] as String? ?? 'Main floor',
    time: parseDate(json['time'] as String?),
    partySize: json['partySize'] as int? ?? 1,
    note: json['note'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'client': client,
    'area': area,
    'time': time.toIso8601String(),
    'partySize': partySize,
    'note': note,
  };
}

class ComplianceReport {
  const ComplianceReport({
    required this.id,
    required this.title,
    required this.area,
    required this.status,
    required this.dueDate,
    required this.note,
  });

  final String id;
  final String title;
  final String area;
  final ReportStatus status;
  final DateTime dueDate;
  final String note;

  factory ComplianceReport.fromJson(Map<String, dynamic> json) =>
      ComplianceReport(
        id: json['id'] as String? ?? uniqueId('report'),
        title: json['title'] as String? ?? 'Report',
        area: json['area'] as String? ?? 'Operations',
        status: ReportStatusX.fromName(json['status'] as String?),
        dueDate: parseDate(json['dueDate'] as String?),
        note: json['note'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'area': area,
    'status': status.name,
    'dueDate': dueDate.toIso8601String(),
    'note': note,
  };
}

class PriorityItem {
  const PriorityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color color;
}

enum OrderStatus { requested, approved, received }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.requested:
        return 'Requested';
      case OrderStatus.approved:
        return 'Approved';
      case OrderStatus.received:
        return 'Received';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.requested:
        return Icons.pending_actions_outlined;
      case OrderStatus.approved:
        return Icons.task_alt_outlined;
      case OrderStatus.received:
        return Icons.inventory_outlined;
    }
  }

  static OrderStatus fromName(String? name) {
    return OrderStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => OrderStatus.requested,
    );
  }
}

enum ReportStatus { due, inProgress, filed }

extension ReportStatusX on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.due:
        return 'Due';
      case ReportStatus.inProgress:
        return 'In progress';
      case ReportStatus.filed:
        return 'Filed';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportStatus.due:
        return Icons.warning_amber_outlined;
      case ReportStatus.inProgress:
        return Icons.pending_actions_outlined;
      case ReportStatus.filed:
        return Icons.verified_outlined;
    }
  }

  static ReportStatus fromName(String? name) {
    return ReportStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => ReportStatus.due,
    );
  }
}

String uniqueId(String prefix) =>
    '$prefix-${DateTime.now().microsecondsSinceEpoch}';

int parseInt(String value, {required int fallback}) =>
    int.tryParse(value.trim()) ?? fallback;

DateTime parseDate(String? value) =>
    DateTime.tryParse(value ?? '') ?? DateTime.now();

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String formatDay(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String currency(double value) => '\$${value.toStringAsFixed(0)}';
