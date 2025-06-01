import 'package:flutter/material.dart';

void showCustomPopup({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = "OK",
  String? cancelText,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  IconData? icon, // Menyesuaikan ikon
  Color? iconColor, // Menyesuaikan warna ikon
  int? duration, // Durasi auto-close dalam detik (null = tidak auto-close)
}) {
  showDialog(
    context: context,
    barrierDismissible: false, // Agar tidak bisa ditutup dengan klik di luar
    builder: (BuildContext context) {
      if (duration != null) {
        Future.delayed(Duration(seconds: duration), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      }

      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 350, // Batas maksimal lebar pop-up (Windows & layar besar)
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) // Jika ada ikon, tampilkan
                  Icon(
                    icon,
                    color: iconColor ?? Colors.blue, // Warna default biru
                    size: 40,
                  ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (cancelText != null)
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[400],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (onCancel != null) onCancel();
                          },
                          child: Text(cancelText, style: TextStyle(color: Colors.black)),
                        ),
                      ),
                    if (cancelText != null) const SizedBox(width: 10), // Spasi antar tombol
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (onConfirm != null) onConfirm();
                        },
                        child: Text(confirmText, style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

///Penggunaan
///Pop-up dengan tombol "OK" saja
//showCustomPopup(
//   context: context,
//   title: "Info",
//   message: "Operasi berhasil!",
//   confirmText: "OK",
// );
/// Pop-up dengan "Cancel" & "OK"
//showCustomPopup(
//   context: context,
//   title: "Konfirmasi",
//   message: "Apakah Anda yakin ingin keluar?",
//   confirmText: "Ya",
//   cancelText: "Batal",
//   onConfirm: () {
//     print("Dikonfirmasi!");
//   },
//   onCancel: () {
//     print("Dibatalkan!");
//   },
// );
///Pop-up otomatis hilang setelah 5 detik
//showCustomPopup(
//   context: context,
//   title: "Notifikasi",
//   message: "Ini akan hilang dalam 5 detik",
//   confirmText: "OK",
//   duration: 5, // Akan otomatis tertutup dalam 5 detik
// );

///Penggunaan icon
//showCustomPopup(
//   context: context,
//   title: "Berhasil",
//   message: "Struk berhasil dicetak.",
//   confirmText: "OK",
//   duration: 5, // Auto-close dalam 5 detik
//   icon: Icons.check_circle, // Ikon centang
//   iconColor: Colors.green, // Warna hijau
// );

///code icon
//Jenis	Ikon	Kode
// ✅ Berhasil	=	Icons.check_circle
// ❌ Error	=	Icons.error
// ❓ Konfirmasi	=	Icons.help_outline
// 🔍 Pencarian	=	Icons.search
// 🛑 Stop / Blokir	=	Icons.block
// 💾 Simpan	=	Icons.save
// 📤 Upload	=	Icons.upload
// 📥 Download	=	Icons.download
// 🖨 Cetak	=	Icons.print
// ⚙️ Pengaturan	=	Icons.settings