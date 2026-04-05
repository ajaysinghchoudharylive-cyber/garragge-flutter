import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/refer_and_earn_widget.dart';
import '../screens/refer_and_earn_screen.dart';

/// Updated Groups Screen showing Refer & Earn functionality
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CarsBuzz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () {
              // Navigate to full refer and earn screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReferAndEarnScreen(),
                ),
              );
            },
            tooltip: 'Refer & Earn',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Refer and Earn Widget
            ReferAndEarnWidget(
              onReferNowTapped: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReferAndEarnScreen(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Additional content can go here
            _buildAdditionalContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Book Service',
                  Icons.car_repair,
                  Colors.blue,
                  () => _showComingSoon('Book Service'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'My Bookings',
                  Icons.history,
                  Colors.orange,
                  () => _showComingSoon('My Bookings'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Support',
                  Icons.support_agent,
                  Colors.purple,
                  () => _showComingSoon('Support'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Profile',
                  Icons.person,
                  Colors.green,
                  () => _showComingSoon('Profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}