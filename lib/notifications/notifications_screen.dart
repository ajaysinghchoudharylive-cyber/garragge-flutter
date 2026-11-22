import 'package:carsbuzz/cardetails/car_details_screen.dart';
import 'package:carsbuzz/carlisting/car_api.dart';
import 'package:carsbuzz/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Notifications list, a port of the Android NotificationsListFragment
/// (fragment_notifications_list.xml + item_notification.xml).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _today = [];
  List<AppNotification> _week = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final (today, week) = await CarApi.notifications();
      if (!mounted) return;
      setState(() {
        _today = today;
        _week = week;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onTap(AppNotification n) async {
    if (!n.read) {
      setState(() => n.read = true);
      CarApi.markRead(n.id);
    }
    final carId = n.carId;
    if (carId != null && carId > 0) {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => CarDetailsScreen(carId: carId)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final empty = !_loading && _today.isEmpty && _week.isEmpty;
    return Scaffold(
      backgroundColor: AppColors.accountBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black26,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Notifications',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : empty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: 0.5,
                        child: Icon(Icons.notifications_none,
                            size: 80, color: AppColors.accountSubtitle),
                      ),
                      SizedBox(height: 16),
                      Text('No notifications yet',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
                      SizedBox(height: 8),
                      Text('Your notifications will appear here',
                          style: TextStyle(fontSize: 14, color: AppColors.accountSubtitle)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_today.isNotEmpty) ...[_header('Today'), ..._today.map(_item)],
                      if (_week.isNotEmpty) ...[_header('Last 7 Days'), ..._week.map(_item)],
                    ],
                  ),
                ),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accountSubtitle)),
      );

  Widget _item(AppNotification n) {
    final (IconData icon, Color tint) = switch (n.type) {
      'view' => (Icons.track_changes, AppColors.brandBlue),
      'lead' => (Icons.support_agent, const Color(0xFF059669)),
      _ => (Icons.notifications_none, AppColors.accent),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onTap(n),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: tint),
                  ),
                  if (!n.read)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration:
                            const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: n.read ? FontWeight.w400 : FontWeight.w700,
                            color: Colors.black)),
                    const SizedBox(height: 4),
                    Text(n.body,
                        style: const TextStyle(fontSize: 12, color: AppColors.accountSubtitle)),
                  ],
                ),
              ),
              if ((n.carImage ?? '').isNotEmpty) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(n.carImage!,
                      width: 60,
                      height: 45,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(width: 60, height: 45)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
