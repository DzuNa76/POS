// lib/presentation/widgets/product_grid/product_detail_form.dart
import 'package:flutter/material.dart';

class ProductDetailForm extends StatelessWidget {
  final Function(String) onCustomerNameChanged;
  final Function(String?) onSizeChanged;
  final Function(List<String>) onFeaturesChanged;
  final String? selectedOption;
  final List<String> selectedFeatures;
  
  const ProductDetailForm({
    Key? key,
    required this.onCustomerNameChanged,
    required this.onSizeChanged,
    required this.onFeaturesChanged,
    required this.selectedOption,
    required this.selectedFeatures,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column 1: Customer Name Input
        Expanded(
          child: _buildNotesSection(),
        ),
        const SizedBox(width: 12),

        // Column 2: Radio Buttons for Item Size
        Expanded(
          child: _buildSizeSection(),
        ),
        const SizedBox(width: 12),

        // Column 3: Checkboxes for Add-ons
        Expanded(
          child: _buildAddonsSection(),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Catatan",
          style: TextStyle(fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          onChanged: onCustomerNameChanged,
        ),
      ],
    );
  }

  Widget _buildSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Size",
          style: TextStyle(fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        RadioListTile<String>(
          title: const Text("Small"),
          value: "Small",
          groupValue: selectedOption,
          onChanged: onSizeChanged,
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        RadioListTile<String>(
          title: const Text("Medium"),
          value: "Medium",
          groupValue: selectedOption,
          onChanged: onSizeChanged,
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        RadioListTile<String>(
          title: const Text("Large"),
          value: "Large",
          groupValue: selectedOption,
          onChanged: onSizeChanged,
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ],
    );
  }

  Widget _buildAddonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Add-ons",
          style: TextStyle(fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        _buildFeatureCheckbox("Extra Feature 1"),
        _buildFeatureCheckbox("Extra Feature 2"),
        _buildFeatureCheckbox("Extra Feature 3"),
      ],
    );
  }

  Widget _buildFeatureCheckbox(String feature) {
    return CheckboxListTile(
      title: Text(feature),
      value: selectedFeatures.contains(feature),
      onChanged: (bool? value) {
        List<String> updatedFeatures = [...selectedFeatures];
        if (value ?? false) {
          updatedFeatures.add(feature);
        } else {
          updatedFeatures.remove(feature);
        }
        onFeaturesChanged(updatedFeatures);
      },
      contentPadding: EdgeInsets.zero,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}