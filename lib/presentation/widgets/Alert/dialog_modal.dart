import 'package:flutter/material.dart';

/// Menampilkan dialog sukses dengan animasi dan desain yang menarik
///
/// Parameter:
/// - [context]: BuildContext yang diperlukan untuk menampilkan dialog
/// - [title]: Judul dialog (default: 'Status Berhasil')
/// - [message]: Pesan utama dialog (default: 'Operasi berhasil')
/// - [description]: Deskripsi tambahan (default: null)
/// - [iconData]: Ikon yang ditampilkan (default: Icons.print_rounded)
/// - [primaryColor]: Warna utama tema dialog (default: Colors.green)
/// - [onOkPressed]: Callback saat tombol OK ditekan (default: hanya menutup dialog)
void showSuccessDialog({
  required BuildContext context,
  String title = 'Status Berhasil',
  String message = 'Operasi berhasil',
  String? description,
  IconData iconData = Icons.print_rounded,
  Color primaryColor = Colors.green,
  VoidCallback? onOkPressed,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        backgroundColor: Colors.white,
        elevation: 8.0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24.0,
              ),
            ),
            const SizedBox(width: 12.0),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                size: 70.0,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14.0,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onOkPressed != null) {
                onOkPressed();
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: primaryColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16.0, 16.0),
      );
    },
  );
}
