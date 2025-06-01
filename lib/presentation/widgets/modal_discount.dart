import 'package:flutter/material.dart';

class ModalExample extends StatelessWidget {
  void showCustomModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top bar with close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Modal Title",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Divider(),
                // Content divided into 3 columns
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.category, size: 40, color: Colors.blue),
                        SizedBox(height: 8),
                        Text("Column 1"),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.star, size: 40, color: Colors.orange),
                        SizedBox(height: 8),
                        Text("Column 2"),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.settings, size: 40, color: Colors.green),
                        SizedBox(height: 8),
                        Text("Column 3"),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Modal Example"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => showCustomModal(context),
          child: Text("Show Modal"),
        ),
      ),
    );
  }
}
