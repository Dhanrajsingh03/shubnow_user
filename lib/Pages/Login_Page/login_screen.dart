import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isOtpMode = false;
  bool _isLoginMode = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _submitAuth() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();

      if (_isLoginMode) {
        ref.read(authControllerProvider.notifier).login(email: email);
      } else {
        ref.read(authControllerProvider.notifier).register(
          fullName: _nameController.text.trim(),
          email: email,
          phoneNumber: _phoneController.text.trim(),
        );
      }
    }
  }

  void _verifyOtp() {
    FocusScope.of(context).unfocus();
    if (_otpController.text.length == 6) {
      ref.read(authControllerProvider.notifier).verifyOtp(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
      );
    } else {
      _showErrorSnackBar('Enter a valid 6-digit OTP');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthError) {
        _showErrorSnackBar(next.errorMessage);
      } else if (next is AuthOtpSent) {
        setState(() => _isOtpMode = true);
      } else if (next is AuthVerified) {
        _showSuccessSnackBar('Welcome ${next.user?.fullName}!');
        context.goNamed('home');
      }
    });

    final screenHeight = MediaQuery.of(context).size.height;
    final currentKey = _isOtpMode ? 'OTP' : (_isLoginMode ? 'Login' : 'Register');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      // 🔥 Ye line ensure karti hai ki keyboard aane par app automatically adjust ho
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. Premium Fixed Gradient Header (Ye keyboard aane par glitch/shrink nahi hoga)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.45,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF7A00), Color(0xFFFF4500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),

          // 2. Scrollable Content (Keyboard aane par field automatically upar scroll hogi)
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(), // Premium bounce effect
                // 🔥 Extra padding bottom me taki scroll karne ke baad buttons keyboard ke upar aa jaye
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.02),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: const Icon(Icons.temple_hindu, size: 60, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ShubhNow',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2),
                    ),
                    const Text(
                      'Your Spiritual Journey Begins',
                      style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),

                    SizedBox(height: screenHeight * 0.04),

                    // 3. The PERFECT 3D Flipping Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: AnimatedSwitcher(
                        // 🔥 Optimal Speed: 800ms (Na bahut tej, na bahut slow)
                        duration: const Duration(milliseconds: 800),
                        // 🔥 Smooth curve jo card ko real depth deta hai
                        switchInCurve: Curves.easeInOutQuart,
                        switchOutCurve: Curves.easeInOutQuart,
                        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                          return Stack(
                            alignment: Alignment.topCenter,
                            children: <Widget>[
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          final rotate = Tween(begin: pi, end: 0.0).animate(animation);

                          return AnimatedBuilder(
                            animation: rotate,
                            child: child,
                            builder: (context, widget) {
                              final isNewWidget = child.key == ValueKey(currentKey);
                              double angle = rotate.value;

                              if (isNewWidget) {
                                if (angle > pi / 2) return const SizedBox.shrink();
                              } else {
                                if (angle > pi / 2) return const SizedBox.shrink();
                                angle = -angle;
                              }

                              return Transform(
                                transform: Matrix4.identity()
                                // 🔥 Perfect 3D Depth perspective (distortion kam kiya hai)
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(angle),
                                alignment: Alignment.center,
                                child: widget,
                              );
                            },
                          );
                        },
                        child: _buildCardContainer(
                          key: ValueKey(currentKey),
                          child: _isOtpMode ? _buildOtpForm(authState) : _buildAuthForm(authState),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({required Key key, required Widget child}) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: child,
    );
  }

  InputDecoration _modernInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: Colors.deepOrange.shade300),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.deepOrange, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    );
  }

  Widget _buildAuthForm(AuthState authState) {
    final isLoading = authState is AuthLoading;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isLoginMode ? 'Welcome Back!' : 'Create an Account',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _isLoginMode ? 'Login to continue your journey' : 'Join us for divine experiences',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          if (!_isLoginMode) ...[
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next, // Keyboard me Next button aayega
              decoration: _modernInputDecoration('Full Name', Icons.person_outline),
              validator: (v) => v!.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
          ],

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: _isLoginMode ? TextInputAction.done : TextInputAction.next,
            decoration: _modernInputDecoration('Email Address', Icons.email_outlined),
            validator: (v) => v!.isEmpty || !v.contains('@') ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 16),

          if (!_isLoginMode) ...[
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done, // Keyboard me Done button aayega
              decoration: _modernInputDecoration('Phone Number', Icons.phone_outlined),
              validator: (v) => v!.length < 10 ? 'Enter a valid 10-digit number' : null,
              onFieldSubmitted: (_) => _submitAuth(),
            ),
            const SizedBox(height: 32),
          ],

          if (_isLoginMode) const SizedBox(height: 16),

          Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [Color(0xFFFF7A00), Color(0xFFFF4500)]),
              boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: isLoading ? null : _submitAuth,
              child: isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(
                _isLoginMode ? 'Get Login OTP' : 'Register Now',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: () {
              setState(() {
                _isLoginMode = !_isLoginMode;
                _formKey.currentState?.reset();
              });
            },
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                children: [
                  TextSpan(text: _isLoginMode ? "Don't have an account? " : "Already have an account? "),
                  TextSpan(
                    text: _isLoginMode ? "Register" : "Login",
                    style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm(AuthState authState) {
    final isLoading = authState is AuthLoading;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.deepOrange),
        const SizedBox(height: 16),
        const Text('Verification', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Enter the 6-digit code sent to\n${_emailController.text}', style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5), textAlign: TextAlign.center),
        const SizedBox(height: 32),

        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.w700, color: Colors.black87),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.deepOrange, width: 2)),
          ),
          onFieldSubmitted: (_) => _verifyOtp(),
        ),
        const SizedBox(height: 32),

        Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [Color(0xFFFF7A00), Color(0xFFFF4500)]),
            boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: isLoading ? null : _verifyOtp,
            child: isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Verify & Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
          ),
        ),
        const SizedBox(height: 24),

        TextButton(
          onPressed: () {
            setState(() {
              _isOtpMode = false;
              _otpController.clear();
            });
            ref.read(authControllerProvider.notifier).resetToInitial();
          },
          child: const Text('Wrong Email? Go Back', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
        )
      ],
    );
  }
}