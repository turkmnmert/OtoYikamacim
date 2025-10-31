import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/order_service.dart';
import 'package:provider/provider.dart';

class PastOrdersScreen extends StatefulWidget {
  const PastOrdersScreen({super.key});

  @override
  _PastOrdersScreenState createState() => _PastOrdersScreenState();
}

class _PastOrdersScreenState extends State<PastOrdersScreen> {
  final List<String> _pastOrderStatuses = [
    'randevu_iptal_edildi',
    'işlem yapıldı'
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userData?['uid'];

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Geçmiş İşlemler'),
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
        title: const Text('Geçmiş İşlemler'),
        backgroundColor: const Color(0xFF6B4EFF),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('user_id', isEqualTo: userId)
            .where('status',
                whereIn: _pastOrderStatuses) // Filter by past order statuses
            .snapshots(),
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
              child: Text('Henüz geçmiş işlem bulunmuyor.'),
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
                      // Display relevant order details for the user
                      _buildDetailRow(
                          'Durum', _mapStatusForDisplay(order['status'])),
                      _buildDetailRow('Tarih', formattedDate),
                      _buildDetailRow('Toplam Tutar',
                          '\$${order['total_amount'].toStringAsFixed(2)}'),
                      // Add other relevant details as needed, e.g., products
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
        return Colors.green; // Yeşil
      case 'İşlemler Yapılıyor':
        return Colors.blue; // Mavi
      case 'Araç Yola Çıktı':
        return Colors.orange; // Turuncu
      case 'Randevu Alındı':
        return Colors.grey; // Gri
      case 'Randevu İptal Edildi':
        return Colors.red; // Kırmızı
      default:
        return Colors.grey; // Varsayılan gri
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
