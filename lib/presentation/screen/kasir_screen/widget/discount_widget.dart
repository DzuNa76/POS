import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pos/core/providers/cart_provider.dart';
import 'package:pos/core/providers/customer_provider.dart';
import 'package:pos/core/utils/config.dart';
import 'package:pos/data/models/cart_item.dart';
import 'package:pos/data/models/voucher/voucher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscountVoucherWidget extends StatefulWidget {
  final Function(String)? onDiscountApplied;
  final Function(String)? onVoucherApplied;
  final bool isApplyButtonEnabled;
  final List<VoucherModel>? voucher;
  final String? sid;

  const DiscountVoucherWidget({
    Key? key,
    this.onDiscountApplied,
    this.onVoucherApplied,
    this.isApplyButtonEnabled = true,
    this.voucher,
    this.sid,
  }) : super(key: key);

  @override
  _DiscountVoucherWidgetState createState() => _DiscountVoucherWidgetState();
}

class _DiscountVoucherWidgetState extends State<DiscountVoucherWidget> {
  // Constants
  static const _primaryColor = Color(0xFF533F77);
  static const _backgroundColor = Color(0xFFF7F9FC);

  // Tab controller
  int _currentTabIndex = 0;
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _voucherController = TextEditingController();

  // Tambahkan variabel untuk menyimpan voucher yang sedang digunakan
  String? _activeVoucherId;

  @override
  void initState() {
    super.initState();
    checkVoucher();
    _currentTabIndex = ConfigService.isUsingDiscount
        ? 0
        : (ConfigService.isUsingVoucher ? 1 : 0);
  }

  void checkVoucher() async {
    final prefs = await SharedPreferences.getInstance();
    final voc = prefs.getBool('voucher_used') ?? false;
    if (voc == true) {
      _activeVoucherId = prefs.getString('voucher_name');
    } else {
      _activeVoucherId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tabs
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (ConfigService.isUsingDiscount) _buildTabItem(0, 'Diskon'),
                  if (ConfigService.isUsingVoucher) _buildTabItem(1, 'Voucher'),
                ],
              ),
            ),
          ),

          // Content Area
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _currentTabIndex == 0
                ? _buildDiscountContent()
                : _buildVoucherContent(cartProvider.cartItems),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
    bool isSelected = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 5,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? _primaryColor : Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _discountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0%',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: _backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: widget.isApplyButtonEnabled
                  ? () {
                      // Tambahkan logika untuk menerapkan diskon
                      if (_discountController.text.isNotEmpty) {
                        // Panggil callback onDiscountApplied jika disediakan
                        widget.onDiscountApplied
                            ?.call(_discountController.text);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Diskon ${_discountController.text} berhasil diterapkan'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        _discountController
                            .clear(); // Mengosongkan input setelah diterapkan
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mohon masukkan besaran diskon'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                elevation: 2,
              ),
              child: const Text(
                'Pakai',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoucherContent(List<CartItem> cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () {
            _showVoucherInputModal(cart);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            elevation: 2,
          ),
          child: const Text(
            'Masukan Kode  Voucher',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        // Input field untuk kode voucher
        // Row(
        //   children: [
        //     Expanded(
        //       child: TextField(
        //         controller: _voucherController,
        //         decoration: InputDecoration(
        //           hintText: 'Masukkan kode voucher',
        //           hintStyle: TextStyle(color: Colors.grey.shade400),
        //           filled: true,
        //           fillColor: _backgroundColor,
        //           border: OutlineInputBorder(
        //             borderRadius: BorderRadius.circular(12),
        //             borderSide: BorderSide.none,
        //           ),
        //           contentPadding: const EdgeInsets.symmetric(
        //             horizontal: 16,
        //             vertical: 8,
        //           ),
        //         ),
        //       ),
        //     ),
        //     const SizedBox(width: 12),
        //     ElevatedButton(
        //       onPressed: widget.isApplyButtonEnabled
        //           ? () {
        //               if (_voucherController.text.isNotEmpty) {
        //                 widget.onVoucherApplied?.call(_voucherController.text);

        //                 ScaffoldMessenger.of(context).showSnackBar(
        //                   SnackBar(
        //                     content: Text(
        //                         'Voucher ${_voucherController.text} berhasil diterapkan'),
        //                     duration: const Duration(seconds: 2),
        //                   ),
        //                 );
        //                 _voucherController.clear();
        //               } else {
        //                 ScaffoldMessenger.of(context).showSnackBar(
        //                   const SnackBar(
        //                     content: Text('Mohon masukkan kode voucher'),
        //                     duration: Duration(seconds: 2),
        //                   ),
        //                 );
        //               }
        //             }
        //           : null,
        //       style: ElevatedButton.styleFrom(
        //         backgroundColor: _primaryColor,
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(12),
        //         ),
        //         padding: const EdgeInsets.symmetric(
        //           horizontal: 20,
        //           vertical: 20,
        //         ),
        //         elevation: 2,
        //       ),
        //       child: const Text(
        //         'Pakai',
        //         style: TextStyle(
        //           fontWeight: FontWeight.w600,
        //         ),
        //       ),
        //     ),
        //   ],
        // ),

        // Divider dan label untuk daftar voucher
        const SizedBox(height: 4),
        const Divider(
          thickness: 0.5,
          color: Colors.grey,
        ),

        // Daftar voucher - Mengurangi tinggi container untuk mengatasi overflow
        widget.voucher != null && widget.voucher!.isNotEmpty
            ? Flexible(
                fit: FlexFit.loose,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.2,
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: widget.voucher!.length,
                    itemBuilder: (context, index) {
                      final voucher = widget.voucher![index];
                      return _buildVoucherItem(voucher, cart);
                    },
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Tidak ada voucher tersedia',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
      ],
    );
  }

  void _showVoucherInputModal(List<CartItem> cart) {
    final TextEditingController voucherController = TextEditingController();
    final FocusNode voucherFocusNode = FocusNode();
    bool isLoading = false;
    bool hasError = false;
    String errorMessage = '';

    // Request focus after a short delay to ensure the keyboard shows up
    Future.delayed(const Duration(milliseconds: 200), () {
      voucherFocusNode.requestFocus();
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Header with icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.local_offer_rounded,
                            color: _primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Punya Kode Voucher?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Masukkan kode untuk mendapatkan diskon',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.grey.shade700,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Input field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: hasError
                              ? Colors.red.shade400
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: TextField(
                        controller: voucherController,
                        focusNode: voucherFocusNode,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Contoh: SAVE20',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.normal,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          suffixIcon: voucherController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    setState(() {
                                      voucherController.clear();
                                      hasError = false;
                                      errorMessage = '';
                                    });
                                  },
                                  icon: Icon(
                                    Icons.cancel_rounded,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            hasError = false;
                            errorMessage = '';
                          });
                        },
                      ),
                    ),

                    // Error message
                    if (hasError && errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red.shade400,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              errorMessage,
                              style: TextStyle(
                                color: Colors.red.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.blue.shade100,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.blue.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Kode voucher hanya berlaku untuk satu kali transaksi dan tidak dapat digabung dengan promo lainnya.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Apply button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                final voucherCode =
                                    voucherController.text.trim();

                                if (voucherCode.isEmpty) {
                                  setState(() {
                                    hasError = true;
                                    errorMessage =
                                        'Kode voucher tidak boleh kosong';
                                  });
                                  return;
                                }

                                setState(() {
                                  isLoading = true;
                                });

                                // Simulate API call to validate voucher
                                await Future.delayed(
                                    const Duration(seconds: 1));

                                // Example validation logic - replace with actual API call
                                final bool isValid = voucherCode.length >= 4;

                                setState(() {
                                  isLoading = false;

                                  if (!isValid) {
                                    hasError = true;
                                    errorMessage =
                                        'Kode voucher tidak valid atau telah kadaluarsa';
                                  } else {
                                    // Success - close modal and apply voucher

                                    Navigator.pop(context);

                                    // Show success notification
                                  }
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade500,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              )
                            : const Text(
                                'Terapkan Voucher',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVoucherItem(VoucherModel voucher, List<CartItem> cart) {
    bool isActive = _activeVoucherId == voucher.name;

    return _VoucherItemWidget(
      voucher: voucher,
      isActive: isActive,
      onTap: () async {
        if (!isActive) {
          final prefs = await SharedPreferences.getInstance();
          if (prefs.getBool('voucher_used') == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Ada Voucher yang sudah aktif, silahkan batalkan voucher yang aktif terlebih dahulu'),
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            _showVoucherDetailModal(voucher, cart);
          }
        }
      },
      onCancel: isActive
          ? () async {
              setState(() {
                _activeVoucherId = null;
              });

              CartProvider cartProvider =
                  Provider.of<CartProvider>(context, listen: false);
              cartProvider.resetVoucher();

              final prefs = await SharedPreferences.getInstance();
              prefs.setBool('voucher_used', false);
              await prefs.setString('voucher_name', '');
              await prefs.setString('voucher_datas', '');
              widget.onVoucherApplied?.call('');

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Voucher dibatalkan'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          : null,
    );
  }

  void _showVoucherDetailModal(VoucherModel voucher, List<CartItem> cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _VoucherDetailModal(
            voucher: voucher,
            cart: cart,
            onApply: () async {
              if (cart.isEmpty) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: _primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shopping_cart_sharp,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Peringatan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF212121),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Keranjang masih kosong.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF757575),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 24,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                minimumSize: const Size(double.infinity, 0),
                              ),
                              child: const Text(
                                'Tutup',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              } else {
                CartProvider cartProvider =
                    Provider.of<CartProvider>(context, listen: false);
                CustomerProvider customerProvider =
                    Provider.of<CustomerProvider>(context, listen: false);
                _voucherProgress();

                final calculate = await cartProvider.useVoucher(
                  voucher,
                  cartProvider.cartItems,
                  customerProvider.customer?.id.toString() ?? '',
                );

                if (calculate['status'] == 'sukses') {
                  setState(() {
                    _activeVoucherId = voucher.name;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('voucher_used', true);
                  await prefs.setString('voucher_name', voucher.name!);
                  await prefs.setString('voucher_datas', calculate.toString());

                  widget.onVoucherApplied?.call(calculate.toString());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Voucher ${voucher.name} berhasil diterapkan'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  Navigator.pop(context);
                  Navigator.pop(context);
                } else {
                  setState(() {
                    _activeVoucherId = '';
                  });

                  Navigator.pop(context);

                  showErrorDialog(
                    errorTitle: "Voucher tidak bisa digunakan",
                    errorMessage: calculate['message'],
                  );
                }
              }
            },
          ),
        );
      },
    );
  }

  Future<dynamic> showErrorDialog({
    required String errorTitle,
    required String errorMessage,
    Function? onRetry,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext context) {
        return _ErrorDialog(
          errorTitle: errorTitle,
          errorMessage: errorMessage,
          onRetry: onRetry != null ? () => onRetry() : null,
        );
      },
    );
  }

  Future<dynamic> _voucherProgress() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext context) {
        return _LoadingDialog(
          title: 'Menerapkan Voucher',
          message: 'Harap tunggu sebentar sistem sedang memproses voucher',
        );
      },
    );
  }
}

// Extract common styles
class _Styles {
  static const primaryColor = Color(0xFF533F77);
  static const backgroundColor = Color(0xFFF7F9FC);

  static final boxShadow = [
    BoxShadow(
      color: Colors.grey.shade200,
      spreadRadius: 1,
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static final borderRadius = BorderRadius.circular(16);
}

// Extract voucher item widget
class _VoucherItemWidget extends StatelessWidget {
  final VoucherModel voucher;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _VoucherItemWidget({
    required this.voucher,
    required this.isActive,
    required this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? _Styles.primaryColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: _Styles.primaryColor, width: 1.5)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _buildVoucherImage(context),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVoucherDetails(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherImage(BuildContext context) {
    if (voucher.voucherImage != null && voucher.voucherImage!.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: "${dotenv.env['API_URL']}${voucher.voucherImage}",
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (context, url, error) =>
                const Icon(Icons.error, size: 20),
          ),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _Styles.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.card_giftcard,
          color: _Styles.primaryColor, size: 22),
    );
  }

  Widget _buildVoucherDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          voucher.voucherName ?? 'Voucher',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          voucher.name ?? '',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _Styles.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Dipakai',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isActive && onCancel != null)
              TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.red,
                ),
                label: const Text(
                  'Batal Pakai',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// Extract term item widget
class _TermItemWidget extends StatelessWidget {
  final String text;

  const _TermItemWidget({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extract loading dialog widget
class _LoadingDialog extends StatelessWidget {
  final String title;
  final String message;

  const _LoadingDialog({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width / 2;
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
        child: Container(
          width: screenWidth * 0.5,
          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _Styles.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const SizedBox(
                  height: 48,
                  width: 48,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_Styles.primaryColor),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  letterSpacing: -0.5,
                  color: Color(0xFF212121),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF757575),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _Styles.primaryColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _Styles.primaryColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _Styles.primaryColor.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extract error dialog widget
class _ErrorDialog extends StatelessWidget {
  final String errorTitle;
  final String errorMessage;
  final VoidCallback? onRetry;

  const _ErrorDialog({
    required this.errorTitle,
    required this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width / 2;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      elevation: 0,
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
      child: Container(
        width: screenWidth * 0.8,
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const SizedBox(
                height: 48,
                width: 48,
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              errorTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: -0.5,
                color: Color(0xFF212121),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF757575),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null) ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Extract voucher detail modal widget
class _VoucherDetailModal extends StatelessWidget {
  final VoucherModel voucher;
  final List<CartItem> cart;
  final VoidCallback onApply;

  const _VoucherDetailModal({
    required this.voucher,
    required this.cart,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 24,
            offset: Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (voucher.voucherImage != null &&
                  voucher.voucherImage!.isNotEmpty)
                _buildVoucherImage(context),
              _buildContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherImage(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: "${dotenv.env['API_URL']}${voucher.voucherImage}",
            fit: BoxFit.cover,
            memCacheWidth: 800, // Optimize memory usage
            memCacheHeight: 400,
            placeholder: (context, url) => Center(
              child: CircularProgressIndicator(
                color: _Styles.primaryColor,
                strokeWidth: 2,
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: _Styles.primaryColor.withOpacity(0.1),
              child: Center(
                child: Icon(
                  Icons.local_offer_outlined,
                  size: 48,
                  color: _Styles.primaryColor,
                ),
              ),
            ),
          ),
        ),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
              stops: const [0.5, 1.0],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                voucher.voucherName ?? 'Promo Spesial',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _Styles.primaryColor,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  voucher.name ?? '-',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (voucher.voucherImage == null || voucher.voucherImage!.isEmpty)
            _buildHeader(context),
          _buildPeriodSection(),
          const SizedBox(height: 20),
          _buildTermsSection(),
          const SizedBox(height: 32),
          _buildApplyButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Detail Voucher',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _Styles.primaryColor,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          voucher.voucherName ?? 'Promo Spesial',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPeriodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Periode Voucher'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _Styles.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: _Styles.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${voucher.validFrom ?? 'Sekarang'} - ${voucher.validUpto ?? 'Tanpa batas'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Berlaku ${voucher.validHourFrom} - ${voucher.validHourTo} WIB',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTermsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Syarat & Ketentuan'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (voucher.description != null &&
                  voucher.description!.isNotEmpty)
                Text(
                  voucher.description ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              SizedBox(
                height: voucher.description != null &&
                        voucher.description!.isNotEmpty
                    ? 16
                    : 0,
              ),
              const Text(
                'Syarat & Ketentuan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildTermsList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTermsList() {
    return Column(
      children: [
        if (voucher.discountType == 'Cash Discount')
          _TermItemWidget(
            text: voucher.applyDiscountOn == 'Transaction'
                ? 'Potongan berlaku untuk seluruh transaksi'
                : 'Potongan berlaku untuk item tertentu',
          ),
        if (voucher.discountAmountType == 'Fixed Amount Discount' &&
            voucher.discountAmount! > 0)
          _TermItemWidget(
            text:
                'Potongan sebesar Rp ${_formatCurrency(voucher.discountAmount!)}',
          ),
        if (voucher.discountAmountType == 'Percentage DIscount' &&
            voucher.discountPercentage! > 0)
          _TermItemWidget(
            text: 'Potongan sebesar ${voucher.discountPercentage}%',
          ),
        if (voucher.maxDiscountAmount != null && voucher.maxDiscountAmount! > 0)
          _TermItemWidget(
            text:
                'Maksimal potongan Rp ${_formatCurrency(voucher.maxDiscountAmount!)}',
          ),
        if (voucher.minimumSpending != null && voucher.minimumSpending! > 0)
          _TermItemWidget(
            text:
                'Minimum pembelanjaan Rp ${_formatCurrency(voucher.minimumSpending!)}',
          ),
        if (voucher.discountType == 'Discount on Cheapest')
          _TermItemWidget(
            text: 'Diskon berlaku untuk ${voucher.qtyDiscounted} item termurah',
          ),
        if (voucher.qtyRequired != null && voucher.qtyRequired! > 0)
          _TermItemWidget(
            text: 'Memerlukan pembelian minimal ${voucher.qtyRequired} item',
          ),
        if (voucher.requiredItemType == 'Selected Item')
          _TermItemWidget(text: 'Berlaku untuk item tertentu'),
        if (voucher.requiredItemType == 'All Item')
          _TermItemWidget(text: 'Berlaku untuk semua item'),
        if (voucher.applyDiscountOn == 'Item' &&
            voucher.qtyDiscounted != null &&
            voucher.qtyDiscounted! > 0)
          _TermItemWidget(
            text: 'Diskon berlaku untuk ${voucher.qtyDiscounted} item',
          ),
        if (voucher.haveQuota == 1 &&
            voucher.quota != null &&
            voucher.quota! > 0)
          _TermItemWidget(
            text:
                'Kuota tersedia: ${voucher.quota! - (voucher.usedQuota ?? 0)}/${voucher.quota}',
          ),
        _TermItemWidget(text: 'Tidak dapat digabung dengan promo lain'),
        _TermItemWidget(text: 'Hanya berlaku untuk satu kali transaksi'),
        if (voucher.welcomeVoucher == 1)
          _TermItemWidget(text: 'Voucher khusus untuk pengguna baru'),
        if (voucher.thirdPartyVoucher == 1)
          _TermItemWidget(text: 'Voucher pihak ketiga'),
        if (voucher.giftCardVoucher == 1)
          _TermItemWidget(text: 'Voucher kartu hadiah'),
        if (voucher.redeemableVoucher == 1)
          _TermItemWidget(text: 'Voucher dapat ditukarkan'),
      ],
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onApply,
        style: ElevatedButton.styleFrom(
          backgroundColor: _Styles.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Gunakan Voucher',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  String _formatCurrency(num amount) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return amount
        .toString()
        .replaceAllMapped(reg, (Match match) => '${match[1]}.');
  }
}
