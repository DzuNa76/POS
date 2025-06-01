import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/notification.dart';

class SettingsInterfaceScreen extends StatefulWidget {
  final bool removeAppBar;
  const SettingsInterfaceScreen({Key? key, this.removeAppBar = false}) : super(key: key);

  @override
  _SettingsInterfaceScreenState createState() => _SettingsInterfaceScreenState();
}

class _SettingsInterfaceScreenState extends State<SettingsInterfaceScreen> {
  String _viewType = "grid"; // Default view type
  final List<String> _viewOptions = ["grid", "list"]; // Options for dropdown

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
  }

  // Load view preference
  Future<void> _loadViewPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _viewType = prefs.getString('viewType') ?? "grid";
    });
  }

  // Save view preference
  Future<void> _saveViewPreference(String viewType) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('viewType', viewType);
    setState(() {
      _viewType = viewType;
    });

    showCustomPopup(
      context: context,
      title: "Tampilan Dirubah",
      message: "View type updated to ${viewType.toUpperCase()}!.",
      confirmText: "OK",
      duration: 5, // Auto-close dalam 5 detik
      icon: Icons.check_circle, // Ikon centang
      iconColor: Colors.green, // Warna hijau
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cek ukuran layar untuk menentukan apakah AppBar harus ditampilkan
    bool isLargeScreen = MediaQuery.of(context).size.width > 600;
    bool shouldRemoveAppBar = widget.removeAppBar || isLargeScreen;

    return Scaffold(
      appBar: shouldRemoveAppBar ? null : AppBar(
        title: const Text('Interface Settings'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose View Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.teal[700],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _viewType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: _viewOptions.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option.toUpperCase(), style: const TextStyle(fontSize: 16)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _saveViewPreference(newValue);
                }
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Your current view type: ${_viewType.toUpperCase()}',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
