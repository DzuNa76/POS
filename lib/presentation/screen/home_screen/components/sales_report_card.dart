import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:pos/data/models/models.dart';

class SalesReportCard extends StatefulWidget {
  const SalesReportCard({Key? key}) : super(key: key);

  @override
  State<SalesReportCard> createState() => _SalesReportCardState();
}

class _SalesReportCardState extends State<SalesReportCard> {
  String selectedPeriod = 'day';
  final List<SalesData> dummyData = [
    SalesData('Mon', 1000),
    SalesData('Tue', 1200),
    SalesData('Wed', 800),
    SalesData('Thu', 1500),
    SalesData('Fri', 1700),
    SalesData('Sat', 900),
    SalesData('Sun', 1100),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Sales Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: selectedPeriod,
                  items: const [
                    DropdownMenuItem(value: 'day', child: Text('Day')),
                    DropdownMenuItem(value: 'week', child: Text('Week')),
                    DropdownMenuItem(value: 'month', child: Text('Month')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedPeriod = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Avg. per $selectedPeriod',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 4),
            const Text(
              'Rp 123,456',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: screenWidth > 600 ? 300 : 200,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                title: ChartTitle(text: 'Weekly Sales'),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries<SalesData, String>>[
                  ColumnSeries<SalesData, String>(
                    dataSource: dummyData,
                    xValueMapper: (SalesData data, _) => data.day,
                    yValueMapper: (SalesData data, _) => data.sales,
                    name: 'Sales',
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


