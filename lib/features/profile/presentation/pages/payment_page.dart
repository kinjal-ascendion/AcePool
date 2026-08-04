import 'package:flutter/material.dart';
import '../widgets/payment_method_card.dart';
import '../widgets/payment_save_button.dart';
import '../widgets/upi_details_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {

  static final _db = FirebaseFirestore.instanceFor(
  app: Firebase.app(),
  databaseId: 'acepool',
);

  String _selectedMethod = "UPI";

bool _isEditing = false;

final TextEditingController _upiController =
    TextEditingController();

final TextEditingController _phoneController =
    TextEditingController();

    Future<void> _savePaymentDetails() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  await _db.collection('users').doc(uid).update({
    'paymentMethod': _selectedMethod,
    'upiId': _upiController.text.trim(),
  });

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Payment details updated"),
    ),
  );
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey.shade50,

    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        "Payment",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.black),
    ),

    body: SingleChildScrollView(
  padding: const EdgeInsets.all(20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Text(
        "PAYMENT METHODS",
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),

      const SizedBox(height: 18),

      PaymentMethodCard(
        selectedMethod: _selectedMethod,
        onChanged: (method) {
          setState(() {
            _selectedMethod = method;
          });
        },
      ),

      if (_selectedMethod == "UPI") ...[

        //const SizedBox(height: 1),
/*
        const Text(
          "UPI DETAILS",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
*/
        const SizedBox(height: 18),

        UpiDetailsCard(
          isEditing: _isEditing,
          upiController: _upiController,
          phoneController: _phoneController,
          onEdit: () {
            setState(() {
              _isEditing = !_isEditing;
            });
          },
        ),
      ],

      const SizedBox(height: 40),

      PaymentSaveButton(
  onPressed: _savePaymentDetails,
),

      const SizedBox(height: 20),

    ],
  ),
),
  );
}
}