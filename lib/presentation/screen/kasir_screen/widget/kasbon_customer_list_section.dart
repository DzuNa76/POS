import 'package:flutter/material.dart';
import 'package:pos/data/models/customer/customer.dart';
import 'package:pos/core/theme/app_colors.dart';
import 'package:pos/presentation/screen/kasir_screen/widget/kasbon_customer_list_item.dart';

class CustomerListSection extends StatelessWidget {
  final List<Customer> customers;
  final Customer? selectedCustomer;
  final bool isLoading;
  final TextEditingController searchController;
  final bool searchByPhone;
  final Function(String) onSearch;
  final Function(Customer) onSelectCustomer;
  final Function(bool) onToggleSearchMode;

  const CustomerListSection({
    Key? key,
    required this.customers,
    required this.selectedCustomer,
    required this.isLoading,
    required this.searchController,
    required this.searchByPhone,
    required this.onSearch,
    required this.onSelectCustomer,
    required this.onToggleSearchMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.3,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _buildCustomerList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer List',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText:
                    searchByPhone ? 'Search by phone...' : 'Search by name...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: onSearch,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSearchToggle('Name', !searchByPhone),
              const SizedBox(width: 16),
              _buildSearchToggle('Phone', searchByPhone),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchToggle(String label, bool isSelected) {
    return InkWell(
      onTap: () => onToggleSearchMode(label == 'Phone'),
      child: Row(
        children: [
          Radio<String>(
            value: label.toLowerCase(),
            groupValue: searchByPhone ? 'phone' : 'name',
            activeColor: AppColors.accent,
            onChanged: (value) => onToggleSearchMode(label == 'Phone'),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2.5,
        ),
      );
    }

    if (customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No customers found',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        final isSelected = customer == selectedCustomer;

        return CustomerListItem(
          customer: customer,
          isSelected: isSelected,
          onTap: () => onSelectCustomer(customer),
        );
      },
    );
  }
}
