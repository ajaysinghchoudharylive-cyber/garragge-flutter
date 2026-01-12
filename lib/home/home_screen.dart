import 'package:carsbuzz/home/category_tab.dart';
import 'package:carsbuzz/home/home_repo.dart';
import 'package:carsbuzz/home/service_item_card.dart';
import 'package:carsbuzz/models/category_item.dart';
import 'package:carsbuzz/models/category_response.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeRepo _repo = HomeRepo();

  List<CategoryResponse> _categories = [];
  List<CategoryItem> _items = [];

  int _selectedIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  void _loadHome() {
    debugPrint('HomeScreen: _loadHome called');

    _repo.fetchHomeData(
      onSuccess: (data) {
        debugPrint('HomeScreen: onSuccess called');
        setState(() {
          _categories = data;
          _items = data.first.items;
          _loading = false;
        });
      },
      onError: (e) {
        debugPrint('HomeScreen: onError called -> $e');
        setState(() => _loading = false);
      },
    );
  }

  void _onCategoryTap(int index) {
    setState(() {
      _selectedIndex = index;
      _items = _categories[index].items;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detailing Services'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          _buildCategoryTabs(),
          Expanded(child: _buildItemsList()),
        ],
      ),
    );
  }

  // 🔹 CATEGORY TABS (Ceramic / PPF)
  Widget _buildCategoryTabs() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: List.generate(_categories.length, (index) {
          return CategoryTab(
            title: _categories[index].itemCategory,
            isSelected: index == _selectedIndex,
            onTap: () => _onCategoryTap(index),
          );
        }),
      ),
    );
  }

  // 🔹 SERVICE ITEMS LIST
  Widget _buildItemsList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        return ServiceItemCard(item: _items[index]);
      },
    );
  }
}
