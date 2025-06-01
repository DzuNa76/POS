import 'package:flutter/material.dart';
import 'package:pos/presentation/widgets/widgets.dart';

class HomeResponsive extends StatelessWidget {
  const HomeResponsive({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Define breakpoints for responsiveness
        bool isDesktop = constraints.maxWidth > 1024;
        bool isTablet = constraints.maxWidth > 810 && constraints.maxWidth <= 1024;
        bool isMobile = constraints.maxWidth <= 810;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard cards
              if (isDesktop || isTablet)
                Row(
                  children: const [
                    Expanded(
                      child: DashboardCard(
                        icon: Icon(Icons.attach_money, color: Colors.green, size: 40),
                        title: 'Total Sales',
                        value: 'Rp 12,345,678',
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: DashboardCard(
                        icon: Icon(Icons.shopping_cart, color: Colors.blue, size: 40),
                        title: 'Total Orders',
                        value: '123 Orders',
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: DashboardCard(
                        icon: Icon(Icons.people, color: Colors.orange, size: 40),
                        title: 'Total Customers',
                        value: '456 Customers',
                      ),
                    ),
                  ],
                )
              else
                // For mobile, display cards in a column
                Column(
                  children: const [
                    DashboardCard(
                      icon: Icon(Icons.attach_money, color: Colors.green, size: 40),
                      title: 'Total Sales',
                      value: 'Rp 12,345,678',
                    ),
                    SizedBox(height: 16),
                    DashboardCard(
                      icon: Icon(Icons.shopping_cart, color: Colors.blue, size: 40),
                      title: 'Total Orders',
                      value: '123 Orders',
                    ),
                    SizedBox(height: 16),
                    DashboardCard(
                      icon: Icon(Icons.people, color: Colors.orange, size: 40),
                      title: 'Total Customers',
                      value: '456 Customers',
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Sales Report and Transaction Cards
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sales Report Card
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: const [
                          SalesReportCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Transaction Card
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(left: 8), // Ensure proper margin
                            child: const TransactionCard(),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                // For tablet and mobile, display in a column
                Column(
                  children: const [
                    SalesReportCard(),
                    SizedBox(height: 16),
                    TransactionCard(),
                  ],
                ),
              const SizedBox(height: 16),

              // Full-width button at the bottom
              CustomActionButton(
                label: 'Cashier',
                onPressed: () {
                  // Handle button action here
                  debugPrint('Action button pressed');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
