import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/cart_service.dart';
import '../../data/services/order_service.dart';

// Input formatters
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\s+'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    final string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty || text.length > 5) {
      return newValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2 && !text.contains('/')) buffer.write('/');
      buffer.write(text[i]);
    }

    final formattedText = buffer.toString();
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

// Payment Screen Widget
class PaymentScreen extends StatefulWidget {
  final List<Map<String, dynamic>> productsWithQuantity;
  final double totalAmount;
  final String userAddress;
  final DateTime? selectedDate;
  final String? selectedTime;
  final Map<String, dynamic>? userData; // Pass user data
  final double discountPercentage; // Pass discount percentage

  const PaymentScreen({
    super.key,
    required this.productsWithQuantity,
    required this.totalAmount,
    required this.userAddress,
    required this.selectedDate,
    required this.selectedTime,
    required this.userData,
    required this.discountPercentage, // Receive discount percentage
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _orderService = OrderService();
  bool _isLoading = false;

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    // Add validation here if needed

    try {
      setState(() => _isLoading = true);

      await _orderService.createOrder(
        userId: widget.userData!['uid'],
        userName: widget.userData!['name'],
        userEmail: widget.userData!['email'],
        userAddress: widget.userAddress,
        productsWithQuantity: widget.productsWithQuantity,
        totalAmount: widget.totalAmount * (1 - widget.discountPercentage / 100), // Use discounted price
        cardNumber: _cardNumberController.text.isNotEmpty
            ? _cardNumberController.text
            : '',
        expiryDate: _expiryDateController.text.isNotEmpty
            ? _expiryDateController.text
            : '',
        cvv: _cvvController.text.isNotEmpty ? _cvvController.text : '',
        appointmentDate: widget.selectedDate,
        appointmentTime: widget.selectedTime,
      );

      // Randevu Firestore'a kaydediliyor - Moved from CartScreen
      if (widget.selectedDate != null && widget.selectedTime != null) {
        await FirebaseFirestore.instance.collection('appointments').add({
          'date': Timestamp.fromDate(widget.selectedDate!),
          'timeSlot': widget.selectedTime,
          'createdAt': FieldValue.serverTimestamp(),
          'user_id': widget.userData!['uid'],
          'user_name': widget.userData!['name'],
          'user_address': widget.userAddress,
          'user_phone': widget.userData!['phone'] ?? 'Belirtilmemiş',
          'user_plate': (widget.userData!['plate_numbers'] != null &&
                  (widget.userData!['plate_numbers'] as List).isNotEmpty)
              ? (widget.userData!['plate_numbers'] as List)[0]
              : 'Belirtilmemiş',
          'status': 'randevu_alindi',
        });
      }

      // Clear cart after successful order
      if (mounted) {
         Provider.of<CartService>(context, listen: false).clear();
      }

      if (mounted) {
        // Navigate back to the cart or show a success screen
        Navigator.pop(context); // Assuming we go back to the cart screen after payment

        // Optionally, show a success message on the previous screen
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('Ödeme ve randevu başarıyla tamamlandı!'),
             backgroundColor: Colors.green,
           ),
         );
      }

    } catch (e) {
      print('Sipariş oluşturulurken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem sırasında bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final finalTotalAmount = widget.totalAmount * (1 - widget.discountPercentage / 100); // Calculate final amount with discount

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Toplam Tutar: \$' + finalTotalAmount.toStringAsFixed(2),
                    style: GoogleFonts.raleway(
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                         color: Color(0xFF6B4EFF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                   Text(
                    'Teslimat Adresi: ' + widget.userAddress,
                     style: GoogleFonts.raleway(
                        textStyle: const TextStyle(
                          fontSize: 14,
                         ),
                      ),
                  ),
                  const SizedBox(height: 16),
                   Text(
                    'Randevu Tarihi: ' + (widget.selectedDate != null ? DateFormat('dd MMMM yyyy', 'tr_TR').format(widget.selectedDate!) : 'Belirtilmemiş'),
                     style: GoogleFonts.raleway(
                        textStyle: const TextStyle(
                          fontSize: 14,
                         ),
                      ),
                  ),
                  const SizedBox(height: 16),
                   Text(
                    'Randevu Saati: ' + (widget.selectedTime ?? 'Belirtilmemiş'),
                      style: GoogleFonts.raleway(
                        textStyle: const TextStyle(
                          fontSize: 14,
                         ),
                      ),
                  ),
                   const SizedBox(height: 24),
                  Text(
                    'Ödeme Bilgileri',
                    style: GoogleFonts.raleway(
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      _CardNumberInputFormatter(),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Kart Numarası',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _expiryDateController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(5),
                            _DateInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Son Kullanım Tar.',
                            hintText: 'MM/YY',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          decoration: InputDecoration(
                            labelText: 'CVV',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4EFF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Ödemeyi Tamamla',
                        style: GoogleFonts.raleway(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 