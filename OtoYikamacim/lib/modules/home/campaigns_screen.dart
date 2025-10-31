import 'package:flutter/material.dart';

class CampaignsScreen extends StatelessWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kampanyalar'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCampaignCard('assets/kampanya1.png', 'Haftaiçi Özel %5 İndirim', 'Bu kampanya haftaiçi yapacağınız yıkamalarda geçerlidir.', 'İndirim Kodu: APP5'),
            _buildCampaignCard('assets/kampanya2.png', 'İlk Siparişe %30 İndirim', 'Yeni müşterilere özel ilk yıkama siparişinde geçerlidir.' , 'İndirim Kodu: APP30'),
            _buildCampaignCard('assets/kampanya3.png', 'İç-Dış Yıkamada Kampanya', 'İç ve dış yıkama paketlerinde geçerli özel fiyat.' , 'İndirim Kodu: APP10'),
            _buildCampaignCard('assets/kampanya4.png', 'Haftasonu Özel %10 İndirim', 'Bu kampanya haftasonu yapacağınız yıkamalarda geçerlidir.' , 'İndirim Kodu: APP10'),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignCard(String imagePath, String title, String description, String appCode) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150, // Increased image width
              height: 120, // Increased image height
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover, // Ensure the image covers the container
              ),
            ),
            const SizedBox(width: 16), // Spacing between image and text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8), // Spacing between title and description
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8), // Spacing between title and description
                  Text(
                    appCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.red,
                       
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