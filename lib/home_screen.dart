import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

const String privateKey =
    'sk_test_51MWJsQEIrCfLPdwzCfzxHn6P9xl3dGMgYer9zS3gUxO7Zj3taRxdIRBO0xmA6FZKID62sr79xwtZWFzcqfshjib600CZXsh7kQ';

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key});

  Map<String, dynamic>? paymentIntentData;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stripe Test'),
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              onTap: () async {
                await makePayment();
              },
              child: Container(
                height: 50,
                width: 200,
                decoration: const BoxDecoration(color: Colors.green),
                child: const Center(
                  child: Text('Buy'),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            InkWell(
              onTap: () async {
                await subscriptions();
              },
              child: Container(
                height: 50,
                width: 200,
                decoration: const BoxDecoration(color: Colors.green),
                child: const Center(
                  child: Text('Subscribe'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> makePayment() async {
    try {
      final customer = await _createCustomer();
      paymentIntentData = await createPaymentIntent('20', 'USD');
      await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: paymentIntentData!['client_secret'],
              style: ThemeMode.dark,
              customerId: customer['id'],
              merchantDisplayName: 'Oraxtech'));

      await displayPaymentSheet();
    } catch (e) {
      debugPrint('exception makepayment ==> ${e.toString()}');
    }
  }

  Future<void> subscriptions() async {
    final customer = await _createCustomer();
    final paymentMethod = await _createPaymentMethod(
      number: null,
      expMonth: null,
      expYear: null,
      cvc: null,
    );
    await _attachPaymentMethod(paymentMethod['id'], customer['id']);
    await _updateCustomer(paymentMethod['id'], customer['id']);
    await _createSubscriptions(customer['id']);
  }

  displayPaymentSheet() async {
    try {
      Stripe.instance.presentPaymentSheet();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  createPaymentIntent(String amount, String currency) async {
    try {
      Map<String, String>? header = {
        'Authorization': 'Bearer $privateKey',
        'Content-Type': 'application/x-www-form-urlencoded'
      };
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount).toString(),
        'currency': currency,
        'payment_method_types[]': 'card'
      };
      var response = await http.post(
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body,
          headers: header);
      return jsonDecode(response.body.toString());
    } catch (e) {
      debugPrint('exception paymentintent ==> ${e.toString()}');
    }
  }

  calculateAmount(String amount) {
    final price = int.parse(amount) * 100;
    return price;
  }

  Future<Map<String, dynamic>> _createCustomer() async {
    const String url = 'https://api.stripe.com/v1/customers';

    Map<String, String>? headers = {
      'Authorization': 'Bearer $privateKey',
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: {'description': 'customer','email': 'fakhar.oraxtech@gmail.com'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print(json.decode(response.body));
      throw 'Failed to register as a customer.';
    }
  }

  Future<Map<String, dynamic>> _createPaymentMethod(
      {required String? number,
      required String? expMonth,
      required String? expYear,
      required String? cvc}) async {
    const String url = 'https://api.stripe.com/v1/payment_methods';

    Map<String, String>? headers = {
      'Authorization': 'Bearer $privateKey',
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: {
        'type': 'card',
        'card[number]': '4242424242424242',
        'card[exp_month]': '12',
        'card[exp_year]': '23',
        'card[cvc]': '123',
        'country': 'Pakistan'
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print(json.decode(response.body));
      throw 'Failed to create PaymentMethod.';
    }
  }

  Future<Map<String, dynamic>> _attachPaymentMethod(
      String paymentMethodId, String customerId) async {
    final String url =
        'https://api.stripe.com/v1/payment_methods/$paymentMethodId/attach';

    Map<String, String>? headers = {
      'Authorization': 'Bearer $privateKey',
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: {
        'customer': customerId,
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print(json.decode(response.body));
      throw 'Failed to attach PaymentMethod.';
    }
  }

  Future<Map<String, dynamic>> _updateCustomer(
      String paymentMethodId, String customerId) async {
    final String url = 'https://api.stripe.com/v1/customers/$customerId';

    Map<String, String>? headers = {
      'Authorization': 'Bearer $privateKey',
      'Content-Type': 'application/x-www-form-urlencoded'
    };

    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: {
        'invoice_settings[default_payment_method]': paymentMethodId,
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print(json.decode(response.body));
      throw 'Failed to update Customer.';
    }
  }

  Future<Map<String, dynamic>> _createSubscriptions(String customerId) async {
    const String url = 'https://api.stripe.com/v1/subscriptions';

    Map<String, String>? headers = {
      'Authorization': 'Bearer $privateKey',
      'Content-Type': 'application/x-www-form-urlencoded'
    };

    Map<String, dynamic> body = {
      'customer': customerId,
      'items[0][price]': 'price_1MXMLrEIrCfLPdwzCOscaXso',
    };

    var response =
        await http.post(Uri.parse(url), headers: headers, body: body);
    if (response.statusCode == 200) {
            print(json.decode(response.body));

      return json.decode(response.body);
    } else {
      print(json.decode(response.body));
      throw 'Failed to register as a subscriber.';
    }
  }
}
