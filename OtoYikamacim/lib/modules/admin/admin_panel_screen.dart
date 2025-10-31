import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/services/order_service.dart';
import '../../data/services/auth_service.dart';
import 'package:provider/provider.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Define the statuses for each tab
  final List<String> _activeStatuses = [
    'randevu_alindi',
    'ekip_yola_cikti',
    'işlem yapılıyor',
    'pending',
    'rezervasyon alındı',
    'rezervasyon oluşturuldu'
  ];
  final String _cancelledStatus = 'randevu_iptal_edildi';
  final String _completedStatus = 'işlem yapıldı';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        backgroundColor: const Color(0xFF6B4EFF),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Aktif Siparişler'),
            Tab(text: 'İptal Edilen Siparişler'),
            Tab(text: 'Tamamlanan Siparişler'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              try {
                await Provider.of<AuthService>(context, listen: false)
                    .signout(context: context);
              } catch (e) {
                print('Çıkış yapılırken hata oluştu: $e');
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(statuses: _activeStatuses),
          _buildOrderList(statuses: [_cancelledStatus]),
          _buildOrderList(statuses: [_completedStatus]),
        ],
      ),
    );
  }

  Widget _buildOrderList({required List<String> statuses}) {
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('created_at', descending: true);

    if (statuses.length == 1) {
      query = query.where('status', isEqualTo: statuses[0]);
    } else {
      query = query.where('status', whereIn: statuses);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
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
          String emptyMessage;
          if (statuses.contains(_cancelledStatus)) {
            emptyMessage = 'Henüz iptal edilen sipariş bulunmuyor';
          } else if (statuses.contains(_completedStatus)) {
            emptyMessage = 'Henüz tamamlanan sipariş bulunmuyor';
          } else if (statuses.contains('randevu_alindi')) {
            emptyMessage = 'Henüz aktif sipariş bulunmuyor';
          } else {
            emptyMessage = 'Henüz sipariş bulunmuyor';
          }
          return Center(
            child: Text(emptyMessage),
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
              child: InkWell(
                onTap: () => _showOrderDetails(context, order, orderId),
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
                      Text(
                        'Müşteri: ${order['user_name']}',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      Text(
                        'Tarih: $formattedDate',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      Text(
                        'Toplam: \$${order['total_amount'].toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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

  String _mapDisplayStatusToDatabaseStatus(String displayStatus) {
    switch (displayStatus) {
      case 'İşlemler Yapıldı':
        return 'işlem yapıldı';
      case 'İşlemler Yapılıyor':
        return 'işlem yapılıyor';
      case 'Araç Yola Çıktı':
        return 'ekip_yola_cikti';
      case 'Randevu Alındı':
        return 'randevu_alindi';
      case 'Randevu İptal Edildi':
        return 'randevu_iptal_edildi';
      default:
        return displayStatus.toLowerCase();
    }
  }

  void _showOrderDetails(
      BuildContext context, Map<String, dynamic> order, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sipariş Detayları #$orderId',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Müşteri Adı', order['user_name']),
              _buildDetailRow('E-posta', order['user_email']),
              _buildDetailRow(
                  'Telefon', order['user_phone'] ?? 'Belirtilmemiş'),
              _buildDetailRow('Adres', order['user_address']),
              _buildDetailRow('Plaka', order['user_plate'] ?? 'Belirtilmemiş'),
              _buildDetailRow(
                  'Randevu Tarihi',
                  order['appointment_date'] != null
                      ? DateFormat('dd/MM/yyyy').format(
                          (order['appointment_date'] as Timestamp).toDate())
                      : 'Belirtilmemiş'),
              _buildDetailRow('Randevu Saati',
                  order['appointment_time'] ?? 'Belirtilmemiş'),
              const SizedBox(height: 16),
              Text(
                'Durumu Güncelle:',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              // Hide dropdown if the order is cancelled or completed
              if (order['status'] != 'randevu_iptal_edildi' &&
                  order['status'] != 'işlem yapıldı')
                DropdownButtonFormField<String>(
                  value: order['status'],
                  items: [
                    DropdownMenuItem(
                        value: 'randevu_alindi', child: Text('Randevu Alındı')),
                    DropdownMenuItem(
                        value: 'ekip_yola_cikti',
                        child: Text('Araç Yola Çıktı')),
                    DropdownMenuItem(
                        value: 'işlem yapılıyor',
                        child: Text('İşlemler Yapılıyor')),
                    DropdownMenuItem(
                        value: 'işlem yapıldı',
                        child: Text('İşlemler Yapıldı')),
                    DropdownMenuItem(
                        value: 'randevu_iptal_edildi',
                        child: Text('Randevuyu İptal Et')),
                  ].where((item) => item.value != null).toList(),
                  onChanged: (newValue) async {
                    if (newValue != null) {
                      try {
                        if (newValue == 'randevu_iptal_edildi') {
                          await OrderService()
                              .updateOrderStatus(orderId, newValue);
                          if (order['appointment_date'] is Timestamp &&
                              order['appointment_time'] is String) {
                            await OrderService().deleteAppointmentForOrder(
                                order['appointment_date'] as Timestamp,
                                order['appointment_time'] as String);
                          }
                        } else {
                          await OrderService()
                              .updateOrderStatus(orderId, newValue);
                        }
                      } catch (e) {
                        print('Durum güncellenirken hata oluştu: $e');
                      }
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 15),
                  ),
                )
              else
                Text(_mapStatusForDisplay(order[
                    'status'])), // Display status as text if cancelled or completed
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Ürünler',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(order['products'] as List).map((product) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${product['name']} x${product['quantity']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          '\$${(product['price'] * product['quantity']).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Toplam Tutar:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${order['total_amount'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4EFF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
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
