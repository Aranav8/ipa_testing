// // location_service.dart
// import 'package:geolocator/geolocator.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class LocationService {
//   static Future<void> storeLastLocation() async {
//     try {
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.low,
//         timeLimit: const Duration(
//             seconds: 5), // Example of providing additional parameters
//       );
//
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       prefs.setDouble('lastLatitude', position.latitude);
//       prefs.setDouble('lastLongitude', position.longitude);
//     } catch (e) {
//       print('Error storing location: $e');
//     }
//   }
//
//   static Future<Position> getLastLocation() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     double? lastLatitude = prefs.getDouble('lastLatitude');
//     double? lastLongitude = prefs.getDouble('lastLongitude');
//
//     return Position(
//       latitude: lastLatitude ?? 0.0,
//       longitude: lastLongitude ?? 0.0,
//       accuracy: 0.0, // Example of providing additional parameters
//       altitude: 0.0,
//       heading: 0.0,
//       speed: 0.0,
//       speedAccuracy: 0.0,
//       timestamp: DateTime.now(), altitudeAccuracy: 0.0, headingAccuracy: 0.0,
//     );
//   }
// }
