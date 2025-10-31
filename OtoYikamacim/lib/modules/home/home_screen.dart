import 'package:alsat/core/size.dart';
import 'package:alsat/data/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './user_orders_screen.dart';
import './past_orders_screen.dart';
import './campaigns_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  String? address;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    address = _authService.userData?['address'] ?? '';
  }

  Future<void> _showEditAddressDialog({
    required String title,
    required String field,
    required String currentValue,
  }) async {
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
          title: Text('$title Düzenle',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'İl',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: districtController,
                  decoration: const InputDecoration(
                    labelText: 'İlçe',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: neighborhoodController,
                  decoration: const InputDecoration(
                    labelText: 'Mahalle',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: extraController,
                  decoration: const InputDecoration(
                    labelText: 'Sokak / Ek Bilgi',
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
              onPressed: () {
                if (cityController.text.isEmpty ||
                    districtController.text.isEmpty ||
                    neighborhoodController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Lütfen il, ilçe ve mahalle alanlarını doldurun'),
                    ),
                  );
                  return;
                }
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
      await _updateUserData({'address': result});
    }
  }

  Future<void> _updateUserData(Map<String, dynamic> newData) async {
    try {
      setState(() => _isLoading = true);

      final querySnapshot = await _authService.firestore
          .collection('users')
          .where('email', isEqualTo: _authService.userData!['email'])
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await _authService.firestore.collection('users').doc(docId).update({
          ...newData,
          'updated_at': FieldValue.serverTimestamp(),
        });

        setState(() {
          address = newData['address'];
        });
        _authService.updateUserData(newData);
      }
    } catch (e) {
      print('Güncelleme hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    final List<String> addressParts =
        (address ?? '').split(',').map((e) => e.trim()).toList();

    final String mainTitle = addressParts.length >= 2
        ? '${addressParts[0]}, ${addressParts[1]}'
        : (address ?? 'Adres yok');

    final String subTitle =
        addressParts.length > 2 ? addressParts.sublist(2).join(', ') : '';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: SizeConfig.getProportionateScreenHeight2(50)),
            Center(
              child: Image.asset(
                'assets/logo.png',
                height: SizeConfig.getProportionateScreenHeight2(81),
                width: SizeConfig.getProportionateScreenWidth2(158.48),
              ),
            ),
            SizedBox(
              height: SizeConfig.getProportionateScreenHeight2(25),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: SizeConfig.getProportionateScreenWidth2(30),
                right: SizeConfig.getProportionateScreenWidth2(30),
              ),
              child: InkWell(
                onTap: () => _showEditAddressDialog(
                  title: 'Adres',
                  field: 'address',
                  currentValue: address ?? '',
                ),
                child: Row(
                  children: [
                    Container(
                      height: SizeConfig.getProportionateScreenHeight2(45.06),
                      width: SizeConfig.getProportionateScreenWidth2(45),
                      decoration: BoxDecoration(
                        color: Color(0xFFFDAA5D),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Image.asset(
                        "assets/location.png",
                        height: SizeConfig.getProportionateScreenHeight2(14),
                        width: SizeConfig.getProportionateScreenWidth2(19.5),
                      ),
                    ),
                    SizedBox(width: SizeConfig.blockWidth2 * 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mainTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: SizeConfig.getProportionateFontSize(14),
                            ),
                          ),
                          Text(
                            subTitle.isNotEmpty ? subTitle : 'Adres bulunamadı',
                            style: TextStyle(
                              fontSize: SizeConfig.getProportionateFontSize(12),
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RotationTransition(
                      turns: const AlwaysStoppedAnimation(270 / 360),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: SizeConfig.getProportionateFontSize(24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: SizeConfig.getProportionateScreenHeight2(25),
            ),
            Center(
              child: SizedBox(
                width: SizeConfig.getProportionateScreenWidth2(318),
                height: SizeConfig.getProportionateScreenHeight2(54),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Ara",
                    hintStyle: TextStyle(
                      fontSize: SizeConfig.getProportionateFontSize2(13),
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(
                          SizeConfig.getProportionateScreenWidth2(8)),
                      child: Image.asset(
                        'assets/search.png',
                        width: SizeConfig.getProportionateScreenWidth2(24),
                        height: SizeConfig.getProportionateScreenHeight2(24),
                      ),
                    ),
                    suffixIcon: Padding(
                      padding: EdgeInsets.all(
                          SizeConfig.getProportionateScreenWidth2(8)),
                      child: Image.asset(
                        'assets/mic.png',
                        width: SizeConfig.getProportionateScreenWidth2(24),
                        height: SizeConfig.getProportionateScreenHeight2(24),
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFEFF1F3),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: SizeConfig.getProportionateScreenHeight2(0),
                      horizontal: SizeConfig.getProportionateScreenWidth2(20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          SizeConfig.getProportionateScreenWidth2(12)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: SizeConfig.blockHeight2 * 20),
            Padding(
              padding: EdgeInsets.only(
                left: SizeConfig.getProportionateScreenWidth2(30),
                right: SizeConfig.getProportionateScreenWidth2(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: SizeConfig.getProportionateScreenHeight2(168),
                      width: SizeConfig.getProportionateScreenWidth2(318),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(SizeConfig.blockWidth2 * 12),
                      ),
                      child: PageView.builder(
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(
                                SizeConfig.blockWidth2 * 20),
                            child: Image.asset(
                              'assets/slider${index + 1}.png',
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.blockHeight2 * 24),
                  Text("Kategoriler",
                      style: TextStyle(
                          fontSize: SizeConfig.getProportionateFontSize(16),
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: SizeConfig.blockHeight2 * 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const UserOrdersScreen()));
                        },
                        child: _buildCategoryCard("assets/time.png",
                            "Rezervasyonlarım", Color(0xFF4AB7B6)),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const PastOrdersScreen()));
                        },
                        child: _buildCategoryCard("assets/union.png",
                            "Geçmiş İşlemler", Color(0xFF4B9DCB)),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const CampaignsScreen()));
                        },
                        child: _buildCategoryCard(
                            "assets/tag.png", "Kampanyalar", Color(0xFFA187D9)),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.blockHeight2 * 24),
                  Text("Favori Hizmetler",
                      style: TextStyle(
                          fontSize: SizeConfig.getProportionateFontSize2(18),
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: SizeConfig.blockHeight2 * 24),
                  Container(
                    width: SizeConfig.getProportionateScreenWidth2(364),
                    height: SizeConfig.getProportionateScreenHeight2(186),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(SizeConfig.blockWidth2 * 12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Teslim Edilmiş",
                                          style: TextStyle(
                                              color: Color(0xFF14AB87),
                                              fontSize: SizeConfig
                                                  .getProportionateFontSize2(
                                                      14))),
                                      Text("Çar, 27 Tem 2024",
                                          style: TextStyle(
                                              fontSize: SizeConfig
                                                  .getProportionateFontSize2(
                                                      12))),
                                    ],
                                  ),
                                  Image.asset(
                                    'assets/car.png',
                                    width: SizeConfig.blockWidth2 * 172,
                                    height: SizeConfig.blockHeight2 * 106,
                                    fit: BoxFit.contain,
                                  ),
                                  SizedBox(width: SizeConfig.blockWidth2 * 12),
                                ],
                              ),
                              SizedBox(height: SizeConfig.blockHeight2 * 30),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Sipariş ID : #28292999",
                                            style: TextStyle(
                                                fontSize: SizeConfig
                                                    .getProportionateFontSize2(
                                                        12))),
                                        Text("Toplam Tutar : 123.9₺",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: SizeConfig
                                                    .getProportionateFontSize2(
                                                        16))),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {},
                                    borderRadius: BorderRadius.circular(
                                        SizeConfig.blockWidth2 * 12),
                                    child: Container(
                                      width: SizeConfig.blockWidth2 * 97,
                                      height: SizeConfig.blockHeight2 * 36,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF4AB7B6),
                                        borderRadius: BorderRadius.circular(
                                            SizeConfig.blockWidth2 * 12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        "Sipariş Et",
                                        style: TextStyle(
                                          fontSize: SizeConfig
                                              .getProportionateFontSize2(12),
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: SizeConfig.blockWidth2 * 12,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: SizeConfig.blockWidth2 * 30,
                                height: SizeConfig.blockHeight2 * 186,
                                decoration: BoxDecoration(
                                  color: Color(0xFFEA7173),
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(
                                        SizeConfig.blockWidth2 * 12),
                                    bottomRight: Radius.circular(
                                        SizeConfig.blockWidth2 * 12),
                                  ),
                                ),
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: Center(
                                    child: Text(
                                      "Tekrar Sipariş Ver %10 İNDİRİM",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: SizeConfig
                                            .getProportionateFontSize2(12),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.blockHeight2 * 24),
                  Text("Siparişinizi Takip Edin",
                      style: TextStyle(
                          fontSize: SizeConfig.getProportionateFontSize2(18),
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: SizeConfig.blockHeight2 * 24),
                  Container(
                    width: SizeConfig.getProportionateScreenWidth2(364),
                    height: SizeConfig.getProportionateScreenHeight2(134),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8EDD9),
                      borderRadius:
                          BorderRadius.circular(SizeConfig.blockWidth2 * 12),
                    ),
                    padding: EdgeInsets.all(SizeConfig.blockWidth2 * 16),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: Image.asset(
                              "assets/delivery.png",
                              width:
                                  SizeConfig.getProportionateScreenWidth2(82),
                              height:
                                  SizeConfig.getProportionateScreenHeight2(82),
                            )),
                        SizedBox(width: SizeConfig.blockWidth2 * 16),
                        Expanded(
                          flex: 7,
                          child: Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text("Sipariş ID #12365236",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: SizeConfig
                                            .getProportionateFontSize2(14))),
                                SizedBox(
                                  height: SizeConfig.blockHeight2 * 8,
                                ),
                                Text("12 items, est time 1Hr",
                                    style: TextStyle(
                                        fontSize: SizeConfig
                                            .getProportionateFontSize2(10))),
                                SizedBox(
                                  height: SizeConfig.blockHeight2 * 18,
                                ),
                                InkWell(
                                  onTap: () {},
                                  borderRadius: BorderRadius.circular(
                                      SizeConfig.blockWidth2 * 12),
                                  child: Container(
                                    width: SizeConfig.blockWidth2 * 97,
                                    height: SizeConfig.blockHeight2 * 36,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF14AB87),
                                      borderRadius: BorderRadius.circular(
                                          SizeConfig.blockWidth2 * 12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "Takip Et",
                                      style: TextStyle(
                                        fontSize: SizeConfig
                                            .getProportionateFontSize2(12),
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.blockHeight2 * 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String imagePath, String title, Color color) {
    return Container(
      width: SizeConfig.blockWidth2 * 100,
      height: SizeConfig.blockHeight2 * 100,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(SizeConfig.blockWidth2 * 12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            width: SizeConfig.blockWidth2 * 40,
            height: SizeConfig.blockHeight2 * 40,
          ),
          SizedBox(height: SizeConfig.blockHeight2 * 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: SizeConfig.getProportionateFontSize(10),
            ),
          ),
        ],
      ),
    );
  }
}
