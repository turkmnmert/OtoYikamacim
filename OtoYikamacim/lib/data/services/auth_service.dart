import 'package:alsat/modules/auth/login_screen.dart';
import 'package:alsat/modules/home/main_page_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _userData;

  FirebaseFirestore get firestore => _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String? get currentUser {
    final user = _auth.currentUser;
    return user?.email;
  }

  Map<String, dynamic>? get userData => _userData;

  bool get isAdmin => _userData?['isAdmin'] ?? false;

  void updateUserData(Map<String, dynamic> newData) {
    _userData = {
      ..._userData ?? {},
      ...newData,
    };
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required BuildContext context,
    required String fullname,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'name': fullname,
        'phone': '',
        'address': '',
        'plate_numbers': [],
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      _userData = {
        'uid': uid,
        'email': email,
        'name': fullname,
        'phone': '',
        'address': '',
        'plate_numbers': [],
      };

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = _handleAuthException(e);
      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Kayıt olurken bir hata oluştu',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  Future<Map<String, dynamic>?> signin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        _userData = userDoc.data();
        _userData!['uid'] = uid;
        return _userData; // Kullanıcı bilgilerini döndür
      } else {
        // Kullanıcı belgesi yoksa oturumu kapat ve null döndür
        await _auth.signOut();
        return null;
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = _handleAuthException(e);
      if (context.mounted) {
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      }
      return null; // Hata durumunda null döndür
    } catch (e) {
      if (context.mounted) {
        Fluttertoast.showToast(
          msg: 'Giriş yapılırken bir hata oluştu',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      }
      return null; // Hata durumunda null döndür
    }
  }

  Future<void> signout({required BuildContext context}) async {
    try {
      await _auth.signOut();
      _userData = null;

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Fluttertoast.showToast(
          msg: 'Çıkış yapılırken bir hata oluştu',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      }
    }
  }

  Future<void> addManualUser({
    required String email,
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: '123456',
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'phone': phone,
        'address': address,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      await _auth.signOut();
    } catch (e) {
      print('Manuel kullanıcı eklenirken hata oluştu: $e');
      rethrow;
    }
  }

  Future<void> migrateUsersToAuth() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();

      for (var doc in querySnapshot.docs) {
        final userData = doc.data();
        final email = userData['email'];
        final password = userData['password'];

        if (email != null && password != null) {
          try {
            final userCredential = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );

            await doc.reference.update({
              'uid': userCredential.user!.uid,
              'updated_at': FieldValue.serverTimestamp(),
            });
          } on FirebaseAuthException catch (e) {
            if (e.code == 'email-already-in-use') {
              print('Kullanıcı zaten mevcut: $email');
            } else {
              print('Kullanıcı taşınırken hata: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Kullanıcı taşıma işleminde hata: $e');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı';
      case 'wrong-password':
        return 'Hatalı şifre';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış';
      case 'too-many-requests':
        return 'Çok fazla başarısız giriş denemesi. Lütfen daha sonra tekrar deneyin';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter olmalıdır';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda';
      default:
        return 'Bir hata oluştu: ${e.message}';
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required BuildContext context,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumda değil');

      // Re-authenticate
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);

      Fluttertoast.showToast(
        msg: 'Şifre başarıyla güncellendi',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: e.toString(),
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  Future<void> createAdminUser({
    required String email,
    required String password,
    required String fullname,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'name': fullname,
        'isAdmin': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Admin kullanıcısı oluşturulurken hata: $e');
      rethrow;
    }
  }
}
