import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets.dart/app_bar_widgets.dart';
import '../../data/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String? _selectedPlate;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userData = _authService.userData;
      setState(() {
        _userData = userData;
        if (userData != null && userData['plate_numbers'] != null && (userData['plate_numbers'] as List).isNotEmpty) {
          _selectedPlate = (userData['plate_numbers'] as List).first;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showEditDialog({
    required String title,
    required String field,
    required String currentValue,
    List<TextInputFormatter>? inputFormatters,
  }) async {
    final controller = TextEditingController(text: currentValue);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '$title Düzenle',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          inputFormatters: inputFormatters,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: title,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _updateUserData({field: result});
    }
  }
  Future<void> _updateUserData(Map<String, dynamic> newData) async {
    try {
      setState(() => _isLoading = true);

      final querySnapshot = await _authService.firestore
          .collection('users')
          .where('email', isEqualTo: _userData!['email'])
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await _authService.firestore.collection('users').doc(docId).update({
          ...newData,
          'updated_at': FieldValue.serverTimestamp(),
        });

        setState(() {
          _userData = {
            ..._userData!,
            ...newData,
          };
        });
        _authService.updateUserData(newData);
      }
    } catch (e) {
      print('Güncelleme hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signout(context: context);
    } catch (e) {
      print('Çıkış yapılırken hata: $e');
    }
  }

  Future<void> _showEditAddressDialog({
  required String title,
  required String field,
  required String currentValue,
}) async {
  // Mevcut adresi parçalayarak alanlara doldur
  List<String> parts = currentValue.split(',').map((e) => e.trim()).toList();
  String city = parts.isNotEmpty ? parts[0] : '';
  String district = parts.length > 1 ? parts[1] : '';
  String neighborhood = parts.length > 2 ? parts[2] : '';
  String extra = parts.length > 3 ? parts.sublist(3).join(', ') : '';

  final cityController = TextEditingController(text: city);
  final districtController = TextEditingController(text: district);
  final neighborhoodController = TextEditingController(text: neighborhood);
  final extraController = TextEditingController(text: extra);

  final result = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('$title Düzenle', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cityController,
                decoration: const InputDecoration(labelText: "İl"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: districtController,
                decoration: const InputDecoration(labelText: "İlçe"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: neighborhoodController,
                decoration: const InputDecoration(labelText: "Mahalle"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: extraController,
                decoration: const InputDecoration(labelText: "Sokak / Ek Bilgi"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final fullAddress =
                  '${cityController.text}, ${districtController.text}, ${neighborhoodController.text}, ${extraController.text}';
              Navigator.pop(context, fullAddress);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Kaydet'),
          ),
        ],
      );
    },
  );

  if (result != null) {
    await _updateUserData({field: result});
  }
}

  Future<void> _showPlatesDialog() async {
    List<String> plates = List<String>.from(_userData!['plate_numbers'] ?? []);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Plakalar',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedPlate != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.purple, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedPlate!,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              if (plates.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(Icons.directions_car_outlined, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'Henüz plaka eklenmemiş',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: plates.length,
                  itemBuilder: (context, index) {
                    final plate = plates[index];
                    final isSelected = plate == _selectedPlate;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.purple.withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.purple.withOpacity(0.2) : Colors.grey[200]!,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        leading: Icon(
                          Icons.directions_car,
                          color: isSelected ? Colors.purple : Colors.grey[600],
                          size: 20,
                        ),
                        title: Text(
                          plate,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                            color: isSelected ? Colors.purple : Colors.black87,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isSelected)
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline, color: Colors.purple, size: 20),
                                onPressed: () {
                                  setState(() => _selectedPlate = plate);
                                  Navigator.pop(context, true);
                                },
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () async {
                                if (plate == _selectedPlate) {
                                  _selectedPlate = null;
                                }
                                plates.removeAt(index);
                                await _updateUserData({'plate_numbers': plates});
                                if (context.mounted) {
                                  Navigator.pop(context, true);
                                }
                              },
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final newPlate = await _showAddPlateDialog();
                  if (newPlate != null) {
                    plates.add(newPlate);
                    if (_selectedPlate == null) {
                      _selectedPlate = newPlate;
                    }
                    await _updateUserData({'plate_numbers': plates});
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  }
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Yeni Plaka Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Kapat',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    if (result == true) {
      setState(() {
        // Dialog'dan döndüğünde state'i güncelle
      });
    }
  }

  Future<String?> _showAddPlateDialog() async {
    final plateController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Yeni Plaka Ekle',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: plateController,
          inputFormatters: [
            UpperCaseTextFormatter(),
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: const InputDecoration(
            labelText: 'Plaka',
            hintText: '34ABC123',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (plateController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen plaka bilgisini girin'),
                  ),
                );
                return;
              }
              Navigator.pop(context, plateController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Şifre Değiştir',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mevcut Şifre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre (Tekrar)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (currentPasswordController.text.isEmpty ||
                  newPasswordController.text.isEmpty ||
                  confirmPasswordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen tüm alanları doldurun'),
                  ),
                );
                return;
              }

              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Yeni şifreler eşleşmiyor'),
                  ),
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Şifre en az 6 karakter olmalıdır'),
                  ),
                );
                return;
              }

              try {
                await _authService.updatePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                  context: context,
                );
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              } catch (e) {
                // Hata mesajı AuthService içinde gösteriliyor
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Şifre başarıyla değiştirildi
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifreniz başarıyla değiştirildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildCustomAppBar(
        title: "Hesabım",
        actionIcon: Icons.logout,
        onActionTap: _logout,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text('Kullanıcı bilgileri bulunamadı'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(
                        title: 'Email',
                        value: _userData!['email'] ?? '',
                        icon: Icons.email_outlined,
                        onEdit: null,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        title: 'Ad Soyad',
                        value: _userData!['name'] ?? '',
                        icon: Icons.person_outline,
                        onEdit: () => _showEditDialog(
                          title: 'Ad Soyad',
                          field: 'name',
                          currentValue: _userData!['name'] ?? '',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        title: 'Telefon',
                        value: _userData!['phone'] ?? '',
                        icon: Icons.phone_outlined,
                        onEdit: () => _showEditDialog(
                          title: 'Telefon',
                          field: 'phone',
                          currentValue: _userData!['phone'] ?? '',
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                            _PhoneNumberInputFormatter(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        title: 'Plakalar',
                        value: _selectedPlate ?? (_userData!['plate_numbers']?.isNotEmpty == true
                            ? '${(_userData!['plate_numbers'] as List).length} plaka'
                            : 'Plaka yok'),
                        icon: Icons.directions_car,
                        onEdit: _showPlatesDialog,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        title: 'Adres',
                        value: _userData!['address'] ?? '',
                        icon: Icons.location_on_outlined,
                        onEdit: () => _showEditAddressDialog(
                          title: 'Adres',
                          field: 'address',
                          currentValue: _userData!['address'] ?? '',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.white,
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                        child: ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF1F3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_outline,
                              color: Color(0xFF7E57C2),
                              size: 24,
                            ),
                          ),
                          title: Text(
                            'Şifre Değiştir',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Color(0xFF7E57C2)),
                          onTap: _showChangePasswordDialog,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback? onEdit,
  }) {
    return Card(
      color: Colors.white,
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF1F3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFF7E57C2),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        subtitle: Text(
          value.isEmpty ? 'Belirtilmemiş' : value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: onEdit != null
            ? const Icon(Icons.chevron_right, color: Color(0xFF7E57C2))
            : null,
        onTap: onEdit,
      ),
    );
  }
}

class _PhoneNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 4 || i == 7 || i == 9 || i == 11) buffer.write(' ');
      buffer.write(text[i]);
    }

    final formattedText = buffer.toString();
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

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