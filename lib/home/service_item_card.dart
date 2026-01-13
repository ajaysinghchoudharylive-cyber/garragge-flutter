import 'package:carsbuzz/models/category_item.dart';
import 'package:flutter/material.dart';

class ServiceItemCard extends StatefulWidget {
  final CategoryItem item;

  const ServiceItemCard({
    super.key,
    required this.item,
  });

  @override
  State<ServiceItemCard> createState() => _ServiceItemCardState();
}

class _ServiceItemCardState extends State<ServiceItemCard> {
  bool isAdded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTitleSection(item)),
                _buildImageAndCart(),
              ],
            ),
            const SizedBox(height: 6),
            if (item.freebies.isNotEmpty)
              SizedBox(width: double.infinity, child: _buildFreebies(item)),
            const SizedBox(height: 2),
            _buildCouponBox(item),
          ],
        ),
      ),
    );
  }

  Widget _buildImageAndCart() {
    return SizedBox(
      width: 100,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 100,
                  width: 100,
                  color: Colors.black,
                  child: Image.network(
                    widget.item.media.isNotEmpty
                        ? widget.item.media.first.mediaUrl
                        : '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.car_repair,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
          Positioned(
            top: 84,
            child: isAdded ? _buildAddedButton() : _buildAddButton(),
          ),
        ],
      ),
    );
  }

  /// ADD
 Widget _buildAddButton() {
  return SizedBox(
    width: 90,
    height: 32,
    child: ElevatedButton(
      onPressed: () {
        setState(() {
          isAdded = true;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: EdgeInsets.zero, // ✅ remove internal padding
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      child: const Text(
        'ADD',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

/// ADDED + -
Widget _buildAddedButton() {
  return Container(
    width: 90,
    height: 30,
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(2),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center, // 👈 key
      mainAxisSize: MainAxisSize.min,              // 👈 key
      children: [
        // ➖ minus
        GestureDetector(
          onTap: () {
            setState(() {
              isAdded = false;
            });
          },
          child: const Icon(
            Icons.remove,
            size: 12,
            color: Colors.white,
          ),
        ),

        const SizedBox(width: 6), // ✅ controlled spacing

        const Text(
          'ADDED',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(width: 6), // ✅ controlled spacing

        // ➕ plus (disabled)
        const Icon(
          Icons.add,
          size: 12,
          color: Colors.white38,
        ),
      ],
    ),
  );
}

  Widget _buildTitleSection(CategoryItem item) {
    final discountedPrice = item.discount != null
        ? item.price! - (item.price! * item.discount! / 100)
        : item.price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.itemName ?? '',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...item.facilities.map(
          (e) => Text(
            '• ${e.name}',
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (item.discount != null)
              Text(
                '₹${item.price}',
                style: const TextStyle(
                  fontSize: 10,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              '₹${discountedPrice!.toInt()}',
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (item.discount != null)
              Text(
                '${item.discount}% OFF',
                style:
                    const TextStyle(fontSize: 10, color: Colors.green),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFreebies(CategoryItem item) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Free',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          ),
          ...item.freebies.map(
            (e) => Text(
              '• ${e.name}',
              style: const TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponBox(CategoryItem item) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.discount, color: Colors.blue),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              'Final price: ₹${item.price}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }
}
