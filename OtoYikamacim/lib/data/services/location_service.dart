import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getCities() async {
    try {
      print('Fetching cities...');
      final doc = await _firestore.collection('locations').doc('cities').get();
      print('Cities document exists: ${doc.exists}');
      if (doc.exists && doc.data() != null) {
        final cities = List<String>.from(doc.data()!['cities'] ?? []);
        print('Found ${cities.length} cities: $cities');
        return cities;
      }
      print('No cities found in document');
      return [];
    } catch (e) {
      print('Error getting cities: $e');
      return [];
    }
  }

  Future<List<String>> getDistricts(String city) async {
    try {
      print('Fetching districts for city: $city');
      final doc = await _firestore
          .collection('locations')
          .doc('districts')
          .collection(city)
          .doc('list')
          .get();
      print('Districts document exists: ${doc.exists}');
      if (doc.exists && doc.data() != null) {
        final districts = List<String>.from(doc.data()!['districts'] ?? []);
        print('Found ${districts.length} districts for $city: $districts');
        return districts;
      }
      print('No districts found for city: $city');
      return [];
    } catch (e) {
      print('Error getting districts for $city: $e');
      return [];
    }
  }

  Future<List<String>> getNeighborhoods(String city, String district) async {
    try {
      print('Fetching neighborhoods for $city, $district');
      final doc = await _firestore
          .collection('locations')
          .doc('neighborhoods')
          .collection(city)
          .doc(district)
          .get();
      print('Neighborhoods document exists: ${doc.exists}');
      if (doc.exists && doc.data() != null) {
        final neighborhoods = List<String>.from(doc.data()!['neighborhoods'] ?? []);
        print('Found ${neighborhoods.length} neighborhoods for $city, $district: $neighborhoods');
        return neighborhoods;
      }
      print('No neighborhoods found for $city, $district');
      return [];
    } catch (e) {
      print('Error getting neighborhoods for $city, $district: $e');
      return [];
    }
  }
} 