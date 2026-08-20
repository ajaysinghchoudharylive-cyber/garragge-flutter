import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carsbuzz/sellcar/sell_car_dashboard.dart';
import 'package:carsbuzz/sellcar/sell_car_wizard_screen.dart';
import 'package:carsbuzz/carlisting/car_listing_screen.dart';
import 'package:carsbuzz/profile/profile_screen.dart';

/// Main home screen with bottom navigation - mirrors native HomeActivity.kt
/// Provides tabs for: Dashboard (Sell Car), Buy Car, Sell Car action, Profile, Support
class SellCarHomeScreen extends StatefulWidget {
  const SellCarHomeScreen({super.key});

  @override
  State<SellCarHomeScreen> createState() => _SellCarHomeScreenState();
}

class _SellCarHomeScreenState extends State<SellCarHomeScreen> {
  int _currentIndex = 0;
  String? _city;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _city = prefs.getString('city');
      _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    });
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      // Sell Car tab - navigate to wizard
      if (_isLoggedIn) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SellCarWizardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to sell your car')),
        );
      }
      return;
    }
    setState(() => _currentIndex = index);
  }

  Widget _buildBody() {
    try {
      switch (_currentIndex) {
        case 0:
          return SellCarDashboard(
            city: _city,
            onSellCarTap: () => _onTabTapped(2),
            onBuyCarTap: () => setState(() => _currentIndex = 1),
          );
        case 1:
          return const CarListingScreen();
        case 3:
          return const ProfileScreen();
        case 4:
          return _buildSupportScreen();
        default:
          return SellCarDashboard(
            city: _city,
            onSellCarTap: () => _onTabTapped(2),
            onBuyCarTap: () => setState(() => _currentIndex = 1),
          );
      }
    } catch (e) {
      return Center(child: Text('Error: $e'));
    }
  }

  Widget _buildSupportScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.support_agent, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Support',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Need help? Contact us anytime.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1A73E8),
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car),
              label: 'Buy Car',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline, size: 32),
              activeIcon: Icon(Icons.add_circle, size: 32),
              label: 'Sell Car',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.support_agent_outlined),
              activeIcon: Icon(Icons.support_agent),
              label: 'Support',
            ),
          ],
        ),
      ),
    );
  }
}
