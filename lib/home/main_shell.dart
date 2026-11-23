import 'package:carsbuzz/carlisting/car_listing_screen.dart';
import 'package:carsbuzz/home/dashboard_screen.dart';
import 'package:carsbuzz/more/more_screen.dart';
import 'package:carsbuzz/sellcar/sell_car_wizard_screen.dart';
import 'package:carsbuzz/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Bottom-navigation shell, a port of the Android HomeActivity + bottom_nav_menu.xml:
/// Dashboard, Buy, Sell, More.
class MainShell extends StatefulWidget {
  static const int tabDashboard = 0;
  static const int tabBuy = 1;
  static const int tabSell = 2;
  static const int tabMore = 3;

  final int initialTab;

  /// Opens the sell-car flow right away (used after a login that was started from Sell).
  final bool openSellOnStart;

  const MainShell({
    super.key,
    this.initialTab = tabDashboard,
    this.openSellOnStart = false,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // After a login started from Sell, come back to the Sell tab (Android LOGIN_ORIGIN).
  late int _index = widget.openSellOnStart ? MainShell.tabSell : widget.initialTab;

  // Tabs are built the first time they are opened and then kept alive.
  final Set<int> _built = {};

  @override
  void initState() {
    super.initState();
    _built.add(_index);
  }

  void _onTap(int i) {
    // Like Android, the Sell tab shows the brand screen with the bottom bar; login is asked for
    // when the seller picks a brand or uploads an RC.
    setState(() {
      _index = i;
      _built.add(i);
    });
  }

  void _onLoggedOut() {
    // Same as Android: after logout go back to the dashboard as a guest.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  Widget _tab(int i) {
    if (!_built.contains(i)) return const SizedBox.shrink();
    switch (i) {
      case MainShell.tabDashboard:
        return const DashboardScreen();
      case MainShell.tabBuy:
        return CarListingScreen(onBack: () => _onTap(MainShell.tabDashboard));
      case MainShell.tabSell:
        return SellCarWizardScreen(onBack: () => _onTap(MainShell.tabDashboard));
      case MainShell.tabMore:
        return MoreScreen(onLoggedOut: _onLoggedOut);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _index,
        children: List.generate(4, _tab),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: _index,
          onTap: _onTap,
          selectedItemColor: AppColors.navSelected,
          unselectedItemColor: AppColors.navUnselected,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontFamily: 'Outfit'),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Outfit'),
          items: [
            _item('assets/icons/ic_home.svg', 'Dashboard', MainShell.tabDashboard),
            _item('assets/icons/ic_buy_car.svg', 'Buy', MainShell.tabBuy),
            _item('assets/icons/ic_sell_car.svg', 'Sell', MainShell.tabSell),
            _item('assets/icons/ic_me.svg', 'More', MainShell.tabMore),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _item(String asset, String label, int i) {
    Widget icon(Color color) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: SvgPicture.asset(
            asset,
            width: 24,
            height: 22,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        );
    return BottomNavigationBarItem(
      icon: icon(AppColors.navUnselected),
      activeIcon: icon(AppColors.navSelected),
      label: label,
    );
  }
}
