import 'package:acepool/di/injection.dart';
import 'package:acepool/features/profile/presentation/bloc/profile_payment_bloc.dart';
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
  bool _detailsHydrated = false;

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
          }

          if (!_detailsHydrated &&
              (state.upiId.isNotEmpty || state.upiPhone.isNotEmpty)) {
            _detailsHydrated = true;
            _upiController.text = state.upiId;
            _phoneController.text = state.upiPhone;
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
                      onEdit: () {
                        _bloc.add(const ProfilePaymentEditToggled());
                      },
                    ),
                  ],

                  const SizedBox(height: 40),

                  PaymentSaveButton(
                    onPressed: () => _bloc.add(
                      ProfilePaymentSaveRequested(
                        _upiController.text.trim(),
                        _phoneController.text.trim(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
