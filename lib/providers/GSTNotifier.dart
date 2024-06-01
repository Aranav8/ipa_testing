import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridobiko/core/Constants.dart';
import 'package:ridobiko/data/GST.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class GSTNotififer extends StateNotifier<GST> {
  GSTNotififer()
      : super(
          GST(
            id: '1',
            cgst: 0,
            sgst: 0,
            gst: 0,
            isGSTApplicable: false,
            isSGSTApplicable: false,
            isCGSTApplicable: false,
          ),
        ) {
    fetch();
  }

  double get getGSTPercentage {
    double sum = 0;
    sum += state.isCGSTApplicable ? state.cgst : 0;
    sum += state.isSGSTApplicable ? state.sgst : 0;
    sum += state.isGSTApplicable ? state.gst : 0;
    print('Calculated GST Percentage: $sum');
    return sum;
  }

  void fetch() async {
    try {
      print('Fetching GST data...'); // Add this line
      var prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('token') ?? '';
      print('Token: $token'); // Add this line
      var res = await http.post(
          Uri.parse('${Constants().url}android_app_customer/api/getGst.php'),
          headers: {
            'token': token,
          });
      var data = jsonDecode(res.body)['data'];
      print('Fetched GST data: $data'); // Add this line
      state = GST.fromMap(data);
      print('GST state updated: ${state.gst}'); // Add this line
      print('GST percentage: $getGSTPercentage');
    } catch (e) {
      print('Error fetching GST data: $e'); // Add this line
      state = GST(
        id: '1',
        cgst: 0,
        sgst: 0,
        gst: 10,
        isGSTApplicable: false,
        isSGSTApplicable: false,
        isCGSTApplicable: false,
      );
    }
  }
}
