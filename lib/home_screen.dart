import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key});

  Map<String, dynamic>? paymentIntentData;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stripe Test'),
      ),
      body: Column(
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
                child: Text('Pay'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> makePayment() async {
    try {
      paymentIntentData = await createPaymentIntent('20', 'USD');
    } catch (e) {
      debugPrint('exception ==> ${e.toString()}');
    }
  }

  createPaymentIntent(String amount, String currency) async{
      try {
        Map<String, dynamic> body = {
          'amount' : calculateAmount(amount),
          'currency' : currency,
          'payment_method_types[]' : 'card'
        };
        var response = await http.post(Uri.parse(uri));
    } catch (e) {
      debugPrint('exception ==> ${e.toString()}');
    }
  }

  calculateAmount(String amount){
    final price = int.parse(amount) * 100;
    return price;
  }
}
