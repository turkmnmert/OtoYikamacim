import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../widgets.dart/app_bar_widgets.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/cart_service.dart';
import '../../data/services/order_service.dart';
import '../../modules/home/payment_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();

  void showTopSnackBar(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF6B4EFF),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2))
        .then((_) => overlayEntry.remove());
  }
}

class _CartScreenState extends State<CartScreen> {
  final _authService = AuthService();
  final _orderService = OrderService();
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  // Kart bilgisi controller'ları
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  // Randevu state'leri
  DateTime? _selectedDate;
  String? _selectedTime;
  List<Map<String, dynamic>> _bookedSlots = [];
  bool _isBookingLoading = true;

  // İndirim kodu için yeni controller
  final TextEditingController _discountCodeController = TextEditingController();

  // İndirim state'leri
  double _discountPercentage = 0.0;
  String _discountMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchBookedSlots();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userData = _authService.userData;
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBookedSlots() async {
    setState(() => _isBookingLoading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('appointments').get();
      setState(() {
        _bookedSlots = snapshot.docs.map((doc) => doc.data()).toList();
        _isBookingLoading = false;
      });
    } catch (e) {
      print('Randevular çekilirken hata oluştu: $e');
      setState(() => _isBookingLoading = false);
    }
  }

  // Randevu oluştur (güncellendi)
  Future<void> _processPayment(
      BuildContext context, CartService cartService) async {
    if (_selectedDate == null || _selectedTime == null) {
      // Kullanıcı tarih ve saat seçimi yapmadıysa uyarı göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen randevu tarihi ve saati seçin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Ürün listesini adet bilgisiyle birlikte hazırla
      final productsWithQuantity = cartService.items
          .map((product) => {
                'id': product.id,
                'name': product.name,
                'price': product.price,
                'image_url': product.imageUrl,
                'quantity': cartService.getItemCount(product),
              })
          .toList();

      await _orderService.createOrder(
        userId: _authService.userData!['uid'],
        userName: _authService.userData!['name'],
        userEmail: _authService.userData!['email'],
        userAddress: _userData!['address'] ?? 'Belirtilmemiş',
        productsWithQuantity: productsWithQuantity,
        totalAmount: cartService.getTotalPrice() * (1 - _discountPercentage / 100),
        cardNumber: _cardNumberController.text.isNotEmpty
            ? _cardNumberController.text
            : '',
        expiryDate: _expiryDateController.text.isNotEmpty
            ? _expiryDateController.text
            : '',
        cvv: _cvvController.text.isNotEmpty ? _cvvController.text : '',
        appointmentDate: _selectedDate,
        appointmentTime: _selectedTime,
      );

      // Randevu Firestore'a kaydediliyor
      await FirebaseFirestore.instance.collection('appointments').add({
        'date': Timestamp.fromDate(_selectedDate!),
        'timeSlot': _selectedTime,
        'createdAt': FieldValue.serverTimestamp(),
        // Müşteri bilgileri eklendi
        'user_id': _authService.userData!['uid'],
        'user_name': _authService.userData!['name'],
        'user_address': _userData!['address'] ?? 'Belirtilmemiş',
        'user_phone': _userData!['phone'] ?? 'Belirtilmemiş', // Telefon bilgisi
        // Plaka bilgisi (İlk plaka kaydediliyor, seçim UI'ı eklendiğinde güncellenebilir)
        'user_plate': (_userData!['plate_numbers'] != null &&
                (_userData!['plate_numbers'] as List).isNotEmpty)
            ? (_userData!['plate_numbers'] as List)[0]
            : 'Belirtilmemiş',
        // Randevu durumu eklendi (Varsayılan olarak beklemede)
        'status': 'randevu_alindi', // Set initial status to 'randevu_alindi'
      });

      cartService.clear();

      if (context.mounted) {
        widget.showTopSnackBar(
          context,
          "Ödeme ve randevu başarıyla tamamlandı!",
        );
      }
    } catch (e) {
      print('Sipariş oluşturulurken hata: $e'); // Reverted error printing
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem sırasında bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Kullanılabilir tarihleri hesapla
  List<DateTime> _getAvailableDates() {
    final dates = <DateTime>[];
    final today = DateTime.now();
    // Saati sıfırla ki karşılaştırmada sorun olmasın
    final startOfToday = DateTime(today.year, today.month, today.day);
    final maxDate = startOfToday.add(const Duration(days: 7));

    for (int i = 0; i < 7; i++) {
      final date = startOfToday.add(Duration(days: i));
      // Geçmiş tarihi veya bugünün geçmiş saatlerini içeren bir tarihi eklememek için kontrol
      if (date.isBefore(startOfToday)) continue;
      dates.add(date);
    }

    return dates;
  }

  // Seçilen tarih için müsait saatleri kontrol et (Güncellendi)
  List<Map<String, dynamic>> _getAvailableTimeSlots(DateTime date) {
    const timeSlots = [
      '09:00',
      '10:00',
      '11:00',
      '12:00',
      '13:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00'
    ];

    final bookedTimesForDate = _bookedSlots
        .where((slot) {
          final slotDate = (slot['date'] as Timestamp).toDate();
          // Sadece aynı gün ve aynı saat dilimi doluysa al
          return slotDate.year == date.year &&
              slotDate.month == date.month &&
              slotDate.day == date.day &&
              timeSlots.contains(slot['timeSlot']);
        })
        .map((slot) => slot['timeSlot'] as String)
        .toList();

    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    return timeSlots.map((time) {
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final slotDateTime = DateTime(date.year, date.month, date.day, hour,
          minute); // Seçilen tarihle birleştir

      bool isBooked = bookedTimesForDate.contains(time);
      bool isPast = isToday && slotDateTime.isBefore(now);

      return {
        'time': time,
        'isBooked': isBooked,
        'isPast': isPast,
        'isAvailable': !isBooked && !isPast, // Müsaitlik kontrolü
      };
    }).toList();
  }

  // İndirim kodu işlemleri
  void _applyDiscount() async {
    final enteredCode = _discountCodeController.text.trim();
    print('Gelen kod: "$enteredCode"');

   
    try {
      final campaignSnapshot = await FirebaseFirestore.instance
          .collection('campaigns')
          .where('name', isEqualTo: enteredCode)
          .get();

      print(campaignSnapshot.docs);
      print('Belge sayısı: ${campaignSnapshot.docs.length}');

      if (campaignSnapshot.docs.isNotEmpty) {
        final data = campaignSnapshot.docs.first.data();
        print('Gelen veri: $data');

        final discount = data['discount'];
        if (discount != null && discount is num) {
          setState(() {
            _discountPercentage = discount.toDouble();
            _discountMessage = 'İndirim kodu uygulandı!';
          });
        } else {
          setState(() {
            _discountPercentage = 0.0;
            _discountMessage = 'Geçersiz indirim bilgisi.';
          });
        }
      } else {
        setState(() {
          _discountPercentage = 0.0;
          _discountMessage = 'Geçersiz indirim kodu.';
        });
      }
    } catch (e) {
      print('Hata: $e');
      setState(() {
        _discountPercentage = 0.0;
        _discountMessage = 'Bir hata oluştu.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final cartItems = cartService.items;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildCustomAppBar(
        title: "Hesabım", // Burası Sepet olarak değişmeli mi?
        actionIcon: Icons.delete_outline,
        onActionTap: cartService.clear,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Color(0xFF6B4EFF),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sepetiniz boş',
                          style: GoogleFonts.raleway(
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ürün eklemek için ürünler sayfasına gidin',
                          style: GoogleFonts.raleway(
                            textStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final product = cartItems[index];
                            final quantity = cartService.getItemCount(product);

                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: product.imageUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const Center(
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Color(0xFF6B4EFF)),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const Center(
                                          child: Icon(
                                            Icons.error_outline,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: GoogleFonts.raleway(
                                              textStyle: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${product.price.toStringAsFixed(2)} TL',
                                            style: GoogleFonts.raleway(
                                              textStyle: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF6B4EFF),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons
                                                    .remove_circle_outline),
                                                onPressed: () {
                                                  cartService
                                                      .removeItem(product);
                                                },
                                                color: const Color(0xFF6B4EFF),
                                              ),
                                              Text(
                                                quantity.toString(),
                                                style: GoogleFonts.raleway(
                                                  textStyle: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.add_circle_outline),
                                                onPressed: () {
                                                  cartService.addItem(product);
                                                },
                                                color: const Color(0xFF6B4EFF),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Randevu Tarihi Seçimi
                            Text(
                              'Randevu Tarihi Seçin',
                              style: GoogleFonts.raleway(
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _isBookingLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  )) // Randevular yüklenirken
                                : SizedBox(
                                    height: 50, // Butonlar için sabit yükseklik
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _getAvailableDates().length,
                                      itemBuilder: (context, index) {
                                        final date =
                                            _getAvailableDates()[index];
                                        final isSelected = _selectedDate !=
                                                null &&
                                            _selectedDate!.year == date.year &&
                                            _selectedDate!.month ==
                                                date.month &&
                                            _selectedDate!.day == date.day;

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4.0),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                _selectedDate = date;
                                                _selectedTime =
                                                    null; // Tarih değişince saati sıfırla
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isSelected
                                                  ? const Color(0xFF6B4EFF)
                                                  : Colors.grey[200],
                                              foregroundColor: isSelected
                                                  ? Colors.white
                                                  : Colors.black87,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16),
                                            ),
                                            child: Text(
                                              DateFormat('dd MMMM', 'tr_TR')
                                                  .format(date),
                                              style: GoogleFonts.raleway(),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                            const SizedBox(height: 20),

                            // Randevu Saati Seçimi
                            if (_selectedDate != null) ...[
                              Text(
                                'Randevu Saati Seçin',
                                style: GoogleFonts.raleway(
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: _getAvailableTimeSlots(_selectedDate!)
                                    .map((slot) {
                                  final time = slot['time'] as String;
                                  final isAvailable =
                                      slot['isAvailable'] as bool;
                                  final isSelected = _selectedTime == time;

                                  return ElevatedButton(
                                    onPressed: isAvailable
                                        ? () {
                                            setState(() {
                                              _selectedTime = time;
                                            });
                                          }
                                        : null, // Müsait değilse onPressed null olacak
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isSelected
                                          ? const Color(0xFF6B4EFF)
                                          : isAvailable
                                              ? Colors.grey[200]
                                              : Colors.grey[
                                                  400], // Dolu ise daha koyu gri
                                      foregroundColor: isSelected
                                          ? Colors.white
                                          : isAvailable
                                              ? Colors.black87
                                              : Colors
                                                  .black54, // Dolu ise yazı rengi soluk
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                    ),
                                    child: Text(
                                      time,
                                      style: GoogleFonts.raleway(
                                        decoration: !isAvailable
                                            ? TextDecoration.lineThrough
                                            : null, // Müsait değilse üstünü çiz
                                        decorationColor: !isAvailable
                                            ? Colors.black87
                                            : null, // Çizgi rengi
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Ödeme Bilgileri ve Toplam
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Toplam:',
                                  style: GoogleFonts.raleway(
                                    textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '\$${(cartService.getTotalPrice() * (1 - _discountPercentage / 100)).toStringAsFixed(2)}',
                                  style: GoogleFonts.raleway(
                                    textStyle: const TextStyle(
                                      color: Color(0xFF6B4EFF),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),

                            // İndirim Kodu Girişi
                            const SizedBox(height: 16),
                            TextField(
                              controller: _discountCodeController,
                              decoration: InputDecoration(
                                labelText: 'İndirim Kodu',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: ElevatedButton(
                                  onPressed: _applyDiscount,
                                  child: const Text('Uygula'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // İndirim Mesajı
                            if (_discountMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  _discountMessage,
                                  style: GoogleFonts.raleway(
                                    textStyle: TextStyle(
                                      fontSize: 14,
                                      color: _discountPercentage > 0 ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),
                            // Ödeme Ekranına Geç Butonu
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_selectedDate == null || _selectedTime == null) {
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       const SnackBar(
                                         content: Text('Lütfen randevu tarihi ve saati seçin.'),
                                         backgroundColor: Colors.orange,
                                       ),
                                     );
                                     return;
                                   }
                                   Navigator.push(
                                     context,
                                     MaterialPageRoute(
                                       builder: (context) => PaymentScreen(
                                         productsWithQuantity: cartService.items
                                             .map((product) => {
                                                   'id': product.id,
                                                   'name': product.name,
                                                   'price': product.price,
                                                   'image_url': product.imageUrl,
                                                   'quantity': cartService.getItemCount(product),
                                                 })
                                             .toList(),
                                         totalAmount: cartService.getTotalPrice(), // Pass original total amount
                                         userAddress: _userData!['address'] ?? 'Belirtilmemiş',
                                         selectedDate: _selectedDate,
                                         selectedTime: _selectedTime,
                                         userData: _userData,
                                         discountPercentage: _discountPercentage, // Pass discount percentage
                                       ),
                                     ),
                                   );
                                }, // Navigate to PaymentScreen
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6B4EFF),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Ödeme Ekranına Geç',
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
                    ],
                  ),
      ),
    );
  }
}

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

// Bu formatter zaten _PhoneNumberInputFormatter olarak tanımlı, çakışmayı önlemek için sildim.
/*
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
*/
