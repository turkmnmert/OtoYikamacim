import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/order_service.dart';
import 'package:provider/provider.dart';

class UserOrdersScreen extends StatefulWidget {
  const UserOrdersScreen({super.key});

  @override
  _UserOrdersScreenState createState() => _UserOrdersScreenState();
}

class _UserOrdersScreenState extends State<UserOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userData?['uid'];

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rezervasyonlarım'),
          backgroundColor: const Color(0xFF6B4EFF),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Kullanıcı bilgisi alınamıyor.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezervasyonlarım'),
        backgroundColor: const Color(0xFF6B4EFF),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('user_id', isEqualTo: userId)
            .where('status', whereNotIn: [
          'işlem yapıldı',
          'randevu_iptal_edildi'
        ]).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Bir hata oluştu: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final orders = snapshot.data?.docs ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Text('Henüz rezervasyon bulunmuyor.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;
              final createdAt = (order['created_at'] as Timestamp).toDate();
              final formattedDate =
                  DateFormat('dd/MM/yyyy HH:mm').format(createdAt);

              // Define the statuses that should NOT show the cancel button
              const uncancelableStatuses = [
                'ekip_yola_cikti',
                'işlem yapılıyor',
                'işlem yapıldı'
              ];
              final shouldShowCancelButton =
                  !uncancelableStatuses.contains(order['status']);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Sipariş #$orderId',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order['status']),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _mapStatusForDisplay(order['status']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                          'Durum', _mapStatusForDisplay(order['status'])),
                      _buildDetailRow('Tarih', formattedDate),
                      _buildDetailRow('Toplam Tutar',
                          '\$${order['total_amount'].toStringAsFixed(2)}'),
                      if (order['products'] != null &&
                          order['products'] is List) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Ürünler:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        ...(order['products'] as List).map((product) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${product['name']} x${product['quantity']}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            )),
                      ],
                      if (shouldShowCancelButton)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  // Show confirmation dialog
                                  final bool? confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Randevu İptali'),
                                        content: const Text(
                                            'Bu randevuyu iptal etmek istediğinizden emin misiniz?'),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text('Vazgeç'),
                                            onPressed: () {
                                              Navigator.of(context).pop(false);
                                            },
                                          ),
                                          TextButton(
                                            child: const Text('İptal Et'),
                                            onPressed: () {
                                              Navigator.of(context).pop(true);
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (confirm == true) {
                                    // Update order status
                                    await OrderService().updateOrderStatus(
                                        orderId, 'randevu_iptal_edildi');

                                    // Delete appointment if exists
                                    if (order['appointment_date']
                                            is Timestamp &&
                                        order['appointment_time'] is String) {
                                      await OrderService()
                                          .deleteAppointmentForOrder(
                                              order['appointment_date']
                                                  as Timestamp,
                                              order['appointment_time']
                                                  as String);
                                    }

                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Randevu başarıyla iptal edildi.'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  print(
                                      'Randevu iptal edilirken hata oluştu: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Randevu iptal edilirken hata oluştu: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Randevuyu İptal Et'),
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
      ),
    );
  }

  Color _getStatusColor(String? status) {
    String displayStatus = _mapStatusForDisplay(status);

    switch (displayStatus) {
      case 'İşlemler Yapıldı':
        return Colors.green;
      case 'İşlemler Yapılıyor':
        return Colors.blue;
      case 'Araç Yola Çıktı':
        return Colors.orange;
      case 'Randevu Alındı':
        return Colors.grey;
      case 'Randevu İptal Edildi':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _mapStatusForDisplay(String? status) {
    switch (status?.toLowerCase()) {
      case 'işlem yapıldı':
        return 'İşlemler Yapıldı';
      case 'işlem yapılıyor':
        return 'İşlemler Yapılıyor';
      case 'ekip_yola_cikti':
        return 'Araç Yola Çıktı';
      case 'pending':
      case 'rezervasyon alındı':
      case 'rezervasyon oluşturuldu':
      case 'randevu_alindi':
        return 'Randevu Alındı';
      case 'randevu_iptal_edildi':
        return 'Randevu İptal Edildi';
      default:
        return status ?? 'Bilinmiyor';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
