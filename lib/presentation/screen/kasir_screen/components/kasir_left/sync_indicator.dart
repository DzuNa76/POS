// lib/presentation/widgets/product_grid/sync_indicator.dart
import 'package:flutter/material.dart';

class SyncIndicator extends StatelessWidget {
  final int currentBatch;
  final int loadedItems;
  final int savedItems;

  const SyncIndicator({
    Key? key,
    required this.currentBatch,
    required this.loadedItems,
    required this.savedItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Chip(
        avatar: const Icon(Icons.sync, size: 16),
        label:
            Text('Batch $currentBatch: $loadedItems loaded, $savedItems saved'),
        backgroundColor: const Color(0xFF533F77),
      ),
    );
  }
}
