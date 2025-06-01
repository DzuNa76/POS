import 'package:flutter/material.dart';
import 'package:pos/presentation/widgets/widgets.dart';
import 'package:pos/presentation/screen/screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: const SidebarMenu(),
      body: const HomeResponsive(), // Menggunakan HomeResponsive
    );
  }
}
