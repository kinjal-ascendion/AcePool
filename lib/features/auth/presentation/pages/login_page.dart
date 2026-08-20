import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:acepool/features/onboarding/domain/onboarding_selection.dart';

import '../bloc/login_bloc.dart';
import '../widgets/auth_button.dart';
import '../widgets/login_header.dart';
import '../widgets/or_divider.dart';
import '../widgets/signup_text.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/sso_button.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key, this.onboardingSelection});

  final OnboardingSelection? onboardingSelection;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoginBloc>(),
      child: _LoginView(onboardingSelection: onboardingSelection),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView({this.onboardingSelection});

  final OnboardingSelection? onboardingSelection;

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    context.read<LoginBloc>().add(
          LoginSubmitted(
            username: _emailController.text.trim(),
            password: _passwordController.text,
            onboardingSelection: widget.onboardingSelection,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          context.go('/home');
        } else if (state is LoginFailure) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isLoading = state is LoginInProgress;
        final emailError =
            state is LoginFieldErrors ? state.emailError : null;
        final passwordError =
            state is LoginFieldErrors ? state.passwordError : null;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 80),
                  const LoginHeader(),
                  const SizedBox(height: 40),
                  AuthTextField(
                    label: 'Work Email',
                    controller: _emailController,
                    hintText: 'Username',
                    errorText: emailError,
                    onChanged: (_) => context
                        .read<LoginBloc>()
                        .add(const LoginFieldEdited(LoginField.email)),
                    suffixWidget: const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Text(
                        '@ascendion.com',
                        style: TextStyle(
                          color: AppColors.black54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Password',
                    controller: _passwordController,
                    hintText: 'Minimum 6 characters',
                    obscureText: true,
                    errorText: passwordError,
                    onChanged: (_) => context
                        .read<LoginBloc>()
                        .add(const LoginFieldEdited(LoginField.password)),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(fontSize: 14, color: AppColors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AuthButton(
                    onPressed: _login,
                    isLoading: isLoading,
                    label: 'Log In',
                  ),
                  const SizedBox(height: 20),
                  const OrDivider(),
                  const SizedBox(height: 20),
                  SsoButton(
                    onPressed: () => context
                        .read<LoginBloc>()
                        .add(const LoginMicrosoftRequested()),
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 12),
                  SignupText(onboardingSelection: widget.onboardingSelection),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
