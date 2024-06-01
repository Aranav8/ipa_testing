import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ridobiko/controllers/auth/auth_controller.dart';
import 'package:ridobiko/core/notification_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bookings/YourOrder.dart';
import 'rental.dart';
import '../subscription/subscriptions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ridobiko/providers/provider.dart';
import '../more/more.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:http/http.dart' as http;

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage>
    with WidgetsBindingObserver {
  NotificationServices notificationServices = NotificationServices();
  List<String> contacts = [];
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _initialLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    initialize();
    _updateLocation();
  }

  Future<void> initialize() async {
    print('Initializing...');
    tz.initializeTimeZones();
    await _requestPermissionsSequentially([
      Permission.location,
      Permission.camera,
      Permission.photos,
      Permission.notification,
      Permission.contacts,
      // Add more permissions here if needed
    ]);
    print('Permissions requested');

    if (await Permission.location.isGranted) {
      _startLocationTracking();
      print('User location fetched');
    }

    if (await Permission.notification.isGranted) {
      notificationServices.requestNotificationPermissions();
      notificationServices.forgroundMessage();
      notificationServices.firebaseInit(context);
      notificationServices.isTokenRefresh();
      print('Notification services initialized');
    }

    // Fetch contacts (this will only send them to backend if they haven't been sent before)
    if (await Permission.contacts.isGranted) {
      _fetchContacts();
    }

    print('Initialization complete.');
  }

  Future<void> _requestPermissionsSequentially(
      List<Permission> permissions) async {
    for (var permission in permissions) {
      if (!(await permission.isGranted)) {
        var permissionStatus = await permission.request();
        if (!permissionStatus.isGranted) {
          print('${permission.toString()} permission not granted');
        } else {
          print('${permission.toString()} permission granted');
        }
      }
    }
  }

  Future<void> _fetchContacts() async {
    final prefs = await SharedPreferences.getInstance();

    // Retrieve the stored mobile number
    final mobileNumber = prefs.getString('mobile');
    print('Retrieved mobile number: $mobileNumber');

    if (mobileNumber == null) {
      print('Mobile number is null');
      return;
    }

    // Check if contacts have already been sent for this mobile number
    bool contactsSent = prefs.getBool('contacts_sent_$mobileNumber') ?? false;

    if (contactsSent) {
      print('Contacts have already been sent for $mobileNumber. Skipping...');
      return;
    }

    List<String> fetchedContacts = await _getContactsFromRepository();
    setState(() {
      contacts = fetchedContacts;
      print('${fetchedContacts.length} contacts fetched');
    });

    // Store contacts locally
    _storeContactsInSharedPreferences(fetchedContacts);

    // Send contacts to the backend
    await _sendContactsToBackend(fetchedContacts, mobileNumber);
  }

  Future<void> _sendContactsToBackend(
      List<String> contacts, String mobileNumber) async {
    final url =
        'http://192.168.31.83/database.php'; // Update this with your backend URL

    // Fetch contacts with numbers from device
    List<Contact> contactsWithNumbers = await _getContactsWithNumbers();

    // Filter contacts list based on fetched contacts with numbers
    List<Contact> contactsToBeSent = contactsWithNumbers
        .where((contact) => contacts.contains(contact.displayName))
        .toList();

    // Convert the list of contact objects into a list of maps with 'number' and 'name' fields
    List<Map<String, String?>> contactsData = contactsToBeSent.map((contact) {
      return {
        'number': contact.phones?.first.value,
        'name': contact.displayName ?? "",
      };
    }).toList();

    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'login_mobile_number': mobileNumber,
        'contacts':
            contactsData, // Send the structured contacts data to the backend
      }),
    );

    if (response.statusCode == 200) {
      print('Contacts successfully sent to backend');
      // Set the flag in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('contacts_sent_$mobileNumber', true);
    } else {
      print('Failed to send contacts to backend');
      // Handle error accordingly
    }
  }

  Future<List<Contact>> _getContactsWithNumbers() async {
    // Fetch all contacts from the device
    Iterable<Contact> allContacts = await ContactsService.getContacts();

    // Filter contacts with phone numbers
    List<Contact> contactsWithNumbers = allContacts.where((contact) {
      return (contact.phones ?? [])
          .isNotEmpty; // Use the null-aware operator to provide an empty list if contact.phones is null
    }).toList();

    return contactsWithNumbers;
  }

  Future<List<String>> _getContactsFromRepository() async {
    List<String> contactNames = [];
    Iterable<Contact> contacts = await ContactsService.getContacts();
    for (Contact contact in contacts) {
      contactNames.add(contact.displayName ?? "");
    }
    return contactNames;
  }

  Future<void> _storeContactsInSharedPreferences(List<String> contacts) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String contactsJson = contacts.join(',');
    await prefs.setString('contacts', contactsJson);
  }

  void _startLocationTracking() {
    _getCurrentLocation().then((initialLocation) {
      setState(() {
        _initialLocation = initialLocation;
      });
    });
  }

  void _stopLocationTracking() {
    _positionStreamSubscription?.cancel();
  }

  Future<Position> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      print(
          'Initial Latitude: ${position.latitude}, Longitude: ${position.longitude}');
      return position;
    } catch (e) {
      print('Error getting current location: $e');
      throw Exception('Error getting current location: $e');
    }
  }

  Future<void> _updateLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      setState(() {
        _initialLocation = position;
      });

      // Retrieve the stored mobile number
      final prefs = await SharedPreferences.getInstance();
      final mobileNumber = prefs.getString('mobile');
      print('Retrieved mobile number: $mobileNumber');

      if (mobileNumber != null) {
        await _sendLocationToBackend(
            mobileNumber, position.latitude, position.longitude);
      }

      print(
          'Updated Latitude: ${position.latitude}, Longitude: ${position.longitude}');
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  Future<void> _sendLocationToBackend(
      String mobileNumber, double latitude, double longitude) async {
    final url =
        'http://192.168.31.83/update_location.php'; // Update with your backend URL

    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'login_mobile_number': mobileNumber,
        'date_time': DateTime.now().toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (response.statusCode == 200) {
      print('Location successfully sent to backend');
    } else {
      print('Failed to send location to backend');
      // Handle error accordingly
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('App lifecycle state changed: $state');
    if (state == AppLifecycleState.resumed) {
      print('App resumed');
      _updateLocation(); // Call update location when app resumes
    }
  }

  @override
  void dispose() {
    _stopLocationTracking();
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  Future<void> checkForUpdate() async {
    final response =
        await ref.read(authControllerProvider.notifier).checkForUpdate(context);
    if (response) {
      showUpdateAlertBox();
    }
  }

  void showUpdateAlertBox() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Update Available'),
            content: const Text(
                'New version of app is available. Please update the app to continue.'),
            actions: [
              TextButton(
                child: const Text(
                  'Update',
                  style: TextStyle(
                    color: Color.fromRGBO(139, 0, 0, 1),
                  ),
                ),
                onPressed: () {
                  if (defaultTargetPlatform == TargetPlatform.iOS) {
                    launch(
                        'https://apps.apple.com/in/app/ridobiko-scooter-bike-rental/id1667260245');
                  } else if (defaultTargetPlatform == TargetPlatform.android) {
                    launch(
                        'https://play.google.com/store/apps/details?id=com.ridobikocustomer.app');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  pageCaller(int index) {
    switch (index) {
      case 0:
        return Rental(
          callBack,
          homeContext: context,
        );
      case 1:
        return Subscriptions(callBack);
      case 2:
        return const YourOrder();
      case 3:
        return const More();
    }
  }

  int selectedPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pageCaller(selectedPage),
      bottomNavigationBar: NavigationBar(
          selectedIndex: selectedPage,
          height: 70,
          onDestinationSelected: (int index) {
            setState(() {
              selectedPage = index;
            });
          },
          backgroundColor: Colors.white,
          elevation: 10,
          destinations: [
            NavigationDestination(
              icon: Image.asset(
                "assets/icons/motorcycle.png",
                height: 25,
                color: selectedPage == 0 ? Colors.black87 : Colors.black45,
              ),
              label: 'Rental',
            ),
            NavigationDestination(
                selectedIcon: Image.asset(
                  "assets/icons/s_selected.png",
                  height: 20,
                  color: Colors.black87,
                ),
                icon: Image.asset(
                  "assets/icons/s.png",
                  height: 20,
                  // color: selectedPage == 1 ? Colors.black87  : Colors.black45,
                ),
                label: 'Subscriptions'),
            NavigationDestination(
                selectedIcon: Image.asset(
                  "assets/icons/booking_selected.png",
                  height: 20,
                  color: Colors.black87,
                ),
                icon: Image.asset(
                  "assets/icons/booking.png",
                  height: 20,
                  // color: selectedPage == 2 ? Colors.black87  : Colors.black45,
                ),
                // icon: Icon(Icons.book_online,),
                label: 'Booking'),
            NavigationDestination(
                selectedIcon: Image.asset(
                  "assets/icons/menu-f.png",
                  height: 20,
                  color: Colors.black87,
                ),
                icon: Image.asset(
                  "assets/icons/menu.png",
                  height: 20,
                  // color: selectedPage == 3 ? Colors.black87  : Colors.black45,
                ),
                label: 'More'),
          ]),
    );
  }

  void callBack(int index) {
    setState(() {
      selectedPage = index;
    });
  }
}
