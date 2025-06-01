import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pos/core/providers/app_state.dart';
import 'package:pos/presentation/widgets/widgets.dart';
import 'package:provider/provider.dart';

class OrderSummaryScreenMobile extends StatelessWidget {
  const OrderSummaryScreenMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomerInfoWidget(
              onCustomerNameChanged: (name) {
                context.read<AppState>().updateCustomerName(name);
              },
            ),
            SizedBox(height: 8.h),
            OrderOptionsWidget(),
            SizedBox(height: 8.h),
            const Divider(),
            SizedBox(height: 8.h),
            Expanded(
              child: ListView(
                children: [
                  SelectedProductsWidget(),
                  SizedBox(height: 8.h),
                  DiscountWidget(),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            const Divider(),
            SizedBox(height: 16.h),
            VoucherAndTotalWidget(),
          ],
        ),
      ),
    );
  }
}
