import 'package:carsbuzz/models/category_item.dart';
import 'package:flutter/material.dart';

class ServiceItemCard extends StatelessWidget{
  final CategoryItem item;

  const ServiceItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Title + Image
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTitleSection(),
                ),
                _buildImageAndButton(),
              ],
            ),

            const SizedBox(height: 6),

            // 🔹 Freebies
            if (item.freebies.isNotEmpty) _buildFreebies(),

            const SizedBox(height: 6),

            // 🔹 Coupon section
            _buildCouponBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.itemName ?? '',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        ...item.facilities.map(
          (e) => Text('• ${e.name}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            if (item.discount != null)
              Text(
                '₹${item.price}',
                style: const TextStyle(
                  fontSize: 12,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              '₹${item.price}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            if (item.discount != null)
              Text(
                '${item.discount}% OFF',
                style: const TextStyle(fontSize: 12, color: Colors.green),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageAndButton() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            item.media.isNotEmpty ? item.media.first.mediaUrl : '',
            height: 120,
            width: 120,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.car_repair, size: 80),
          ),
        ),
        const SizedBox(height: 8),
        // ElevatedButton(
        //   onPressed: () {},
        //   child: Text((item.isAdded ?? false) ? 'Added' : 'Add'),
        // ),
      ],
    );
  }

  Widget _buildFreebies() {
    return Container(
      width: double.infinity,
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          ...item.freebies.map((e) => Text('• ${e.name}', style: TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildCouponBox() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.discount, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Get ₹0 OFF – Final: ₹${item.price}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
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
