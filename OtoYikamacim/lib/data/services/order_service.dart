import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createOrder({
    required String userId,
    required String userName,
    required String userEmail,
    required String userAddress,
    required List<Map<String, dynamic>> productsWithQuantity,
    required double totalAmount,
    String? cardNumber,
    String? expiryDate,
    String? cvv,
    DateTime? appointmentDate,
    String? appointmentTime,
  }) async {
    try {
      final orderData = {
        'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'user_address': userAddress,
        'products': productsWithQuantity,
        'total_amount': totalAmount,
        'status': 'randevu_alindi',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'card_number': cardNumber ?? '',
        'expiry_date': expiryDate ?? '',
        'cvv': cvv ?? '',
        if (appointmentDate != null)
          'appointment_date': Timestamp.fromDate(appointmentDate),
        if (appointmentTime != null) 'appointment_time': appointmentTime,
      };

      await _firestore.collection('orders').add(orderData);
    } catch (e) {
      print('Sipariş oluşturulurken hata: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Sipariş durumu güncellenirken hata: $e');
      rethrow;
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).delete();
    } catch (e) {
      print('Sipariş silinirken hata: $e');
      rethrow;
    }
  }

  Future<void> deleteAppointmentForOrder(
      Timestamp appointmentDate, String appointmentTime) async {
    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('date', isEqualTo: appointmentDate)
          .where('timeSlot', isEqualTo: appointmentTime)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Randevu silinirken hata: $e');
      rethrow;
    }
  }
}
