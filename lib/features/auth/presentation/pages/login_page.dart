import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(email)) return 'Please enter a valid email address';
    return null;
  }

  String _mapResetError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'network-request-failed':
        return 'Network issue detected. Check your connection and try again.';
      default:
        return 'Unable to process request now. Please try again shortly.';
    }
  }

  void _showForgotPasswordSheet() {
    final resetEmailController = TextEditingController(text: _emailController.text);
    final resetFormKey = GlobalKey<FormState>();
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (stCtx, setSheetState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

            return Container(
              padding: EdgeInsets.only(
                left: 24, 
                right: 24, 
                top: 24, 
                bottom: 24 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Theme.of(ctx).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reset Password',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your email address and we will send you a secure link to reset your password.',
                    style: TextStyle(color: secondaryText, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: resetFormKey,
                    child: TextFormField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.done,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: _validateEmail,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: GlowingButton(
                      label: 'Send Reset Link',
                      icon: Icons.send_rounded,
                      isLoading: isSending,
                      onPressed: () async {
                        final isValid =
                            resetFormKey.currentState?.validate() ?? false;
                        if (!isValid) return;

                        final email = resetEmailController.text.trim();

                        setSheetState(() => isSending = true);
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                          if (!mounted) return;
                          Navigator.pop(stCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'If an account exists for this email, a reset link has been sent.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } on FirebaseAuthException catch (e) {
                          // Avoid account enumeration leaks for user-not-found.
                          if (e.code == 'user-not-found') {
                            if (!mounted) return;
                            Navigator.pop(stCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'If an account exists for this email, a reset link has been sent.',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            return;
                          }

                          if (stCtx.mounted) {
                            ScaffoldMessenger.of(stCtx).showSnackBar(
                              SnackBar(content: Text(_mapResetError(e))),
                            );
                            setSheetState(() => isSending = false);
                          }
                        } catch (e) {
                          if (stCtx.mounted) {
                            ScaffoldMessenger.of(stCtx).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                            setSheetState(() => isSending = false);
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(resetEmailController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.go('/discover');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 80),
                      // Logo & Branding
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 24,
                              spreadRadius: -8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bolt,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Charge Lanka',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Peer-to-Peer EV Charging',
                        style: TextStyle(fontSize: 16, color: secondaryText),
                      ),
                      const SizedBox(height: 48),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Email is required';
                                }
                                if (!v.contains('@')) {
                                  return 'Invalid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    );
                                  },
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password is required';
                                }
                                if (v.length < 6) {
                                  return 'Min 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordSheet,
                                child: const Text('Forgot Password?'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                return SizedBox(
                                  width: double.infinity,
                                  child: GlowingButton(
                                    label: 'Sign In',
                                    icon: Icons.login,
                                    isLoading: state is AuthLoading,
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        context.read<AuthBloc>().add(
                                          LoginRequested(
                                            email: _emailController.text.trim(),
                                            password: _passwordController.text,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          TextButton(
                            onPressed: () => context.go('/register'),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
