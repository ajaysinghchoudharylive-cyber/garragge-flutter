import 'package:carsbuzz/home/category_tab.dart';
import 'package:carsbuzz/home/home_repo.dart';
import 'package:carsbuzz/home/service_item_card.dart';
import 'package:carsbuzz/models/category_response.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key}); // ❗ NOT const

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeRepo _repo = HomeRepo();

  final ScrollController _listController = ScrollController();
  final Map<int, GlobalKey> _categoryKeys = {};

  List<CategoryResponse> _categories = [];
  int _selectedIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  void _loadHome() {
    _repo.fetchHomeData(
      onSuccess: (data) {
        if (!mounted) return;

        _categoryKeys.clear();
        for (int i = 0; i < data.length; i++) {
          _categoryKeys[i] = GlobalKey();
        }

        setState(() {
          _categories = data;
          _loading = false;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _loading = false);
      },
    );
  }

  void _onCategoryTap(int index) {
    if (index < 0 || index >= _categories.length) return;

    setState(() => _selectedIndex = index);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _categoryKeys[index]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
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
          Expanded(child: _buildCategoryList()),
        ],
      ),
    );
  }

  // ✅ NO Row, NO Expanded, NO Flex problems
  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return CategoryTab(
            title: _categories[index].itemCategory,
            isSelected: index == _selectedIndex,
            onTap: () => _onCategoryTap(index),
          );
        },
      ),
    );
  }

  Widget _buildCategoryList() {
    return ListView.builder(
      controller: _listController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];

        return Column(
          key: _categoryKeys[index],
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12,0),
              child: Text(
                category.itemCategory,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...category.items.map(
              (item) => ServiceItemCard(item: item),
            ),
          ],
        );
      },
    );
  }
}
