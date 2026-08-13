import 'package:acepool/di/injection.dart';
import 'package:acepool/features/profile/presentation/bloc/profile_payment_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/payment_method_card.dart';
import '../widgets/payment_save_button.dart';
import '../widgets/upi_details_card.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late final ProfilePaymentBloc _bloc;

  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  int _lastSavedTick = 0;

  @override
  void initState() {
    super.initState();
    _bloc = sl<ProfilePaymentBloc>();
  }

  @override
  void dispose() {
    _upiController.dispose();
    _phoneController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<ProfilePaymentBloc, ProfilePaymentState>(
        listener: (context, state) {
          if (state.savedTick != _lastSavedTick) {
            _lastSavedTick = state.savedTick;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Payment details updated")),
            );
            // Return to the Profile page after a successful save.
            Navigator.of(context).pop();
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
            _bloc.add(const ProfilePaymentErrorDismissed());
          }
        },
        builder: (context, state) {
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
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.black),
            ),

            body: Column(
              children: [
                // Scrollable content — cards only.
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "PAYMENT METHODS",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Color(0xFF757575),
                          ),
                        ),

                        const SizedBox(height: 12),

                        PaymentMethodCard(
                          selectedMethod: state.selectedMethod,
                          onChanged: (method) {
                            _bloc.add(ProfilePaymentMethodChanged(method));
                          },
                        ),

                        if (state.selectedMethod == "UPI") ...[
                          const SizedBox(height: 18),

                          UpiDetailsCard(
                            isEditing: state.isEditing,
                            upiController: _upiController,
                            phoneController: _phoneController,
                            phoneLabel:
                                FirebaseAuth.instance.currentUser
                                    ?.displayName ??
                                'Phone Number',
                            onEdit: () {
                              _bloc.add(const ProfilePaymentEditToggled());
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Save button pinned to the bottom of the screen.
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: PaymentSaveButton(
                      onPressed: () => _bloc.add(
                        ProfilePaymentSaveRequested(
                          _upiController.text.trim(),
                          _phoneController.text.trim(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
