// // lib/services/payment_service.dart
//
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
//
// class PaymentService {
//   final String apiKey;
//   final String apiSecret;
//   final bool isSandbox;
//
//   PaymentService({
//     required this.apiKey,
//     required this.apiSecret,
//     this.isSandbox = true,
//   });
//
//   Future<String> initiateOrder({
//     required String reference,
//     required String amount,
//     required String currency,
//     required String name,
//   }) async {
//     final baseUrl = isSandbox
//         ? 'https://api-test.noonpayments.com/payment/v1'
//         : 'https://api.noonpayments.com/payment/v1';
//     final uri = Uri.parse('$baseUrl/order');
//     final bodyJson = jsonEncode({
//       'apiOperation': 'INITIATE',
//       'order': {
//         'reference': reference,
//         'amount': amount,
//         'currency': currency,
//         'name': name,
//       },
//     });
//
//     // Build Basic-auth header (username: apiKey, password: apiSecret)
//     final authHeader =
//         'Basic ' + base64Encode(utf8.encode('$apiKey:$apiSecret'));
//
//     // DEBUG logging
//     debugPrint('→ POST $uri');
//     debugPrint('→ Authorization: $authHeader');
//     debugPrint('→ Body: $bodyJson');
//
//     final response = await http.post(
//       uri,
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': authHeader,
//       },
//       body: bodyJson,
//     );
//
//     debugPrint('← ${response.statusCode}: ${response.body}');
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['resultCode'].toString() == '0') {
//         return data['result']['order']['id'] as String;
//       } else {
//         throw Exception(
//             'Payment initiation failed (code ${data['resultCode']})');
//       }
//     } else {
//       throw Exception('HTTP error ${response.statusCode}');
//     }
//   }
// }
