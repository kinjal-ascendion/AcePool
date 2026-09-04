import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/profile/presentation/bloc/profile_payment_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

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
    if (_bloc.state.upiId.isNotEmpty) {
      _upiController.text = _bloc.state.upiId;
    }
    if (_bloc.state.upiPhone.isNotEmpty) {
      _phoneController.text = _bloc.state.upiPhone;
    }
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
          if (!state.isEditing) {
            if (_upiController.text != state.upiId) {
              _upiController.text = state.upiId;
            }
            if (_phoneController.text != state.upiPhone) {
              _phoneController.text = state.upiPhone;
            }
          }
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
            backgroundColor: AppColors.scaffoldBackground,
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.black, size: 26),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            'Payment',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.mulish(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF000000),
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "PAYMENT METHODS",
                            style: GoogleFonts.mulish(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 15 / 14,
                              letterSpacing: 0.8,
                              color: const Color(0xFF4C515B),
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
                  Padding(
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
