import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';

  Stream<List<Product>> getProducts() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList());
  }

  Future<void> addProduct(Product product) async {
    await _firestore.collection(_collection).add(product.toMap());
  }

  Future<void> updateProduct(String id, Product product) async {
    await _firestore.collection(_collection).doc(id).update(product.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  Future<void> addSampleProducts() async {
    final sampleProducts = [
      {
        'name': 'iPhone 15',
        'description': 'Latest iPhone model',
        'price': 999.99,
        'imageUrl': 'https://images.unsplash.com/photo-1695048133142-1a20484bce54?q=80&w=1000',
      },
      {
        'name': 'MacBook Pro',
        'description': 'Powerful laptop for professionals',
        'price': 1999.99,
        'imageUrl': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?q=80&w=1000',
      },
      {
        'name': 'AirPods Pro',
        'description': 'Premium wireless earbuds',
        'price': 249.99,
        'imageUrl': 'https://images.unsplash.com/photo-1606220588911-4b9d2f9a0e98?q=80&w=1000',
      },
      {
        'name': 'iPad Pro',
        'description': 'Professional tablet',
        'price': 799.99,
        'imageUrl': 'https://images.unsplash.com/photo-1588675646184-f5b0b0b0b0b0?q=80&w=1000',
      },
      {
        'name': 'Apple Watch',
        'description': 'Smartwatch with health features',
        'price': 399.99,
        'imageUrl': 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?q=80&w=1000',
      },
      {
        'name': 'HomePod',
        'description': 'Smart speaker with Siri',
        'price': 299.99,
        'imageUrl': 'https://images.unsplash.com/photo-1547721064-da6cfb341d50?q=80&w=1000',
      },
      {
        'name': 'Apple TV',
        'description': 'Streaming device',
        'price': 129.99,
        'imageUrl': 'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?q=80&w=1000',
      },
      {
        'name': 'Magic Keyboard',
        'description': 'Wireless keyboard',
        'price': 99.99,
        'imageUrl': 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?q=80&w=1000',
      },
    ];
    final snapshot = await _firestore.collection(_collection).get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
    for (var product in sampleProducts) {
      await _firestore.collection(_collection).add(product);
    }
  }
} 