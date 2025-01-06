import 'package:flutter/material.dart';

class PaymentMethodPage extends StatefulWidget {
  final String psychologistName;
  final String price;

  const PaymentMethodPage({
    super.key,
    required this.psychologistName,
    required this.price,
  });

  @override
  State<PaymentMethodPage> createState() => PaymentMethodPageState();
}

class PaymentMethodPageState extends State<PaymentMethodPage> {
  String? _selectedMethod;

  final List<String> _paymentMethods = [
    'Credit Card',
    'PayPal',
    'Bank Transfer',
    'E-Wallet',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method',
            style: TextStyle(
                color: Color(0xFF0097A7), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0097A7)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consultation with ${widget.psychologistName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ${widget.price}',
              style: const TextStyle(fontSize: 16, color: Colors.cyan),
            ),
            const SizedBox(height: 24),
            const Text(
              'Choose a payment method:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _paymentMethods.length,
                itemBuilder: (context, index) {
                  final method = _paymentMethods[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _selectedMethod == method
                            ? Colors.cyan
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      title: Text(method),
                      trailing: _selectedMethod == method
                          ? const Icon(Icons.check_circle, color: Colors.cyan)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedMethod = method;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedMethod != null
                    ? () {
                        // Implement payment process here
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Processing payment with $_selectedMethod')),
                        );
                        // Navigate to payment confirmation or chat page
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Proceed to Payment',
                    style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
