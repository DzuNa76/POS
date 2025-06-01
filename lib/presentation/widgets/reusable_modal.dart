import 'package:flutter/material.dart';
import 'package:pos/presentation/widgets/widgets.dart';

class ReusableModal {
  static void show(
    BuildContext context,
    String title,
    Widget content,
    int initialQuantity,
    VoidCallback onIncrement,
    VoidCallback onDecrement,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            int quantity = initialQuantity;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top bar dengan judul dan tombol close
                  Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12.0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.black),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Konten modal
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.75,
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              // Kolom 1 - Catatan Customer
                              Expanded(
                                child: Container(
                                  color: Colors.white,
                                  padding: EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Catatan Customer',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 8),
                                      TextField(
                                        decoration: InputDecoration(
                                          hintText: 'Masukkan catatan',
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Kolom 2 - Preference
                              Expanded(
                                child: Container(
                                  color: Colors.white,
                                  padding: EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Preference',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Column(
                                        children: [
                                          'Preference 1',
                                          'Preference 2',
                                          'Preference 3'
                                        ]
                                            .map(
                                              (String pref) => RadioListTile(
                                                title: Text(pref),
                                                value: pref,
                                                groupValue: 'Preference 1',
                                                onChanged: (value) {},
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Kolom 3 - Add On
                              Expanded(
                                child: Container(
                                  color: Colors.white,
                                  padding: EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Add On',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Column(
                                        children: List.generate(5, (index) {
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Checkbox(
                                                  value: false,
                                                  onChanged: (value) {}),
                                              Expanded(
                                                child: Text(
                                                    'Add On ${index + 1}'),
                                              ),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.remove),
                                                    onPressed: () {
                                                      if (quantity > 1) {
                                                        setState(() {
                                                          quantity--;
                                                          onDecrement();
                                                        });
                                                      }
                                                    },
                                                  ),
                                                  Text('$quantity'),
                                                  IconButton(
                                                    icon: Icon(Icons.add),
                                                    onPressed: () {
                                                      setState(() {
                                                        quantity++;
                                                        onIncrement();
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(thickness: 2),
                        Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Quantity Selector
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove),
                                    onPressed: () {
                                      if (quantity > 1) {
                                        setState(() {
                                          quantity--;
                                          onDecrement();
                                        });
                                      }
                                    },
                                  ),
                                  Text(quantity.toString(),
                                      style: TextStyle(fontSize: 18)),
                                  IconButton(
                                    icon: Icon(Icons.add),
                                    onPressed: () {
                                      setState(() {
                                        quantity++;
                                        onIncrement();
                                      });
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  child: Text('Pilih'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
