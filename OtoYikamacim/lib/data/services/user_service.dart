import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'users';

  Future<bool> testConnection() async {
    try {
      print('Testing Firestore connection...');
      await _firestore.collection(_collectionName).limit(1).get();
      print('Firestore connection successful');
      return true;
    } catch (e) {
      print('Firestore connection error: $e');
      return false;
    }
  }

  Future<void> createUser({
    required String uid,
    required String email,
    required String fullName,
    required String password,
  }) async {
    try {
      if (!await testConnection()) {
        throw Exception('Could not connect to Firestore');
      }

      print('Starting Firestore document creation...');
      print('Collection: $_collectionName');
      print('Document ID (UID): $uid');
      
      final userData = {
        'uid': uid,
        'email': email,
        'full_name': fullName,
        'password': password,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      print('Attempting to create user document with data: $userData');
      
      await _firestore.collection(_collectionName).doc(uid).set(
        userData,
        SetOptions(merge: true),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Firestore operation timed out');
        },
      );
      
      final docSnapshot = await _firestore.collection(_collectionName).doc(uid).get();
      if (docSnapshot.exists) {
        print('Document successfully created and verified in Firestore');
        print('Document data: ${docSnapshot.data()}');
      } else {
        throw Exception('Document was not created successfully');
      }
      
    } catch (e, stackTrace) {
      print('Error creating Firestore document:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      if (!await testConnection()) {
        throw Exception('Could not connect to Firestore');
      }

      print('Fetching user data for UID: $uid');
      final doc = await _firestore.collection(_collectionName).doc(uid).get();
      
      if (doc.exists) {
        print('User document found: ${doc.data()}');
        return doc.data();
      } else {
        print('No user document found for UID: $uid');
        return null;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      rethrow;
    }
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      print('Updating user data for UID: $uid');
      print('Update data: $data');
      
      await _firestore.collection(_collectionName).doc(uid).update({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      print('User data updated successfully');
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      print('Deleting user document for UID: $uid');
      await _firestore.collection(_collectionName).doc(uid).delete();
      print('User document deleted successfully');
    } catch (e) {
      print('Error deleting user document: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      print('Searching for user with email: $email');
      
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        print('User found with email: $email');
        return querySnapshot.docs.first.data();
      }
      
      print('No user found with email: $email');
      return null;
    } catch (e) {
      print('Error searching user by email: $e');
      rethrow;
    }
  }
} 