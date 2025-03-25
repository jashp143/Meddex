import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/auth_controller.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isSettingPin = false;
  bool _isConfirmingPin = false;
  String _errorMessage = '';
  bool _showError = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotateAnimation;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _checkIfPinExists();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Logo animations
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoRotateAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Content animations
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkIfPinExists() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPin = prefs.getString('user_pin') != null;

    setState(() {
      _isSettingPin = !hasPin;
    });
  }

  Future<void> _verifyPin() async {
    if (_pinController.text.length < 4) {
      setState(() {
        _errorMessage = 'PIN must be at least 4 digits';
        _showError = true;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('user_pin') ?? '';

    // Check if the widget is still mounted before accessing context
    if (!mounted) return;

    if (savedPin == _pinController.text) {
      // Animate before navigation
      _animateSuccess(() {
        // PIN is correct, authenticate the user
        final authController =
            Provider.of<AuthController>(context, listen: false);
        authController.login();

        // Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      });
    } else {
      // PIN is incorrect, show error
      _animateError(() {
        setState(() {
          _errorMessage = 'Incorrect PIN. Please try again.';
          _showError = true;
          _pinController.clear();
        });
      });
    }
  }

  void _confirmPin() {
    if (_pinController.text.length < 4) {
      setState(() {
        _errorMessage = 'PIN must be at least 4 digits';
        _showError = true;
      });
      return;
    }

    // Animate transition to confirm screen
    _animateTransition(() {
      setState(() {
        _isConfirmingPin = true;
        _confirmPinController.clear();
        _showError = false;
        _errorMessage = '';
      });
    });
  }

  Future<void> _savePin() async {
    if (_confirmPinController.text.length < 4) {
      setState(() {
        _errorMessage = 'PIN must be at least 4 digits';
        _showError = true;
      });
      return;
    }

    if (_pinController.text != _confirmPinController.text) {
      _animateError(() {
        setState(() {
          _errorMessage = 'PINs do not match. Try again.';
          _showError = true;
          _isConfirmingPin = false;
          _confirmPinController.clear();
        });
      });
      return;
    }

    // Animate success before proceeding
    _animateSuccess(() async {
      // Store PIN
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_pin', _pinController.text);

      // Check if the widget is still mounted before accessing context
      if (!mounted) return;

      // Get the AuthController and set authenticated to true
      final authController =
          Provider.of<AuthController>(context, listen: false);
      authController.login();

      // Navigate to home screen
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  // Animation helpers
  void _animateSuccess(VoidCallback onComplete) {
    // Success animation - can be customized
    _animationController.reverse().then((_) {
      onComplete();
    });
  }

  void _animateError(VoidCallback onComplete) {
    // Shake animation for error
    _animationController.stop();
    onComplete();
  }

  void _animateTransition(VoidCallback onComplete) {
    // Transition animation
    _animationController.reverse().then((_) {
      onComplete();
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360 || screenSize.height < 600;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          // Background decorative elements
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              reverse: true,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: bottomPadding > 0 ? bottomPadding : 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenSize.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Animated Logo
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: Transform.rotate(
                            angle: _logoRotateAnimation.value * math.pi,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.medical_services,
                                size: isSmallScreen ? 48 : 56,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),

                    // Animated content
                    FadeTransition(
                      opacity: _fadeInAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            // App name
                            Text(
                              'MedDex',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 28 : 32,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),

                            // Subtitle with gradient
                            ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                ).createShader(bounds);
                              },
                              child: Text(
                                'Medical Practice Management',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 40 : 64),

                            // PIN Card
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    // PIN instructions
                                    Text(
                                      _isSettingPin
                                          ? (_isConfirmingPin
                                              ? 'Confirm your PIN'
                                              : 'Create a PIN to secure your account')
                                          : 'Enter your PIN to continue',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: isSmallScreen ? 16 : 20),

                                    // Error message
                                    AnimatedOpacity(
                                      opacity: _showError ? 1.0 : 0.0,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: _showError
                                          ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 12),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .error
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.error_outline,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .error,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      _errorMessage,
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .error,
                                                        fontSize: 14,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : const SizedBox(height: 0),
                                    ),
                                    SizedBox(height: _showError ? 16 : 0),

                                    // PIN input field
                                    _isConfirmingPin
                                        ? _buildPinField(_confirmPinController,
                                            'Confirm PIN', true)
                                        : _buildPinField(
                                            _pinController, 'Enter PIN', false),

                                    const SizedBox(height: 24),

                                    // Action button
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _isSettingPin
                                            ? (_isConfirmingPin
                                                ? _savePin
                                                : _confirmPin)
                                            : _verifyPin,
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            vertical: isSmallScreen ? 12 : 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 3,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          foregroundColor: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                        ),
                                        child: Text(
                                          _isSettingPin
                                              ? (_isConfirmingPin
                                                  ? 'Save PIN'
                                                  : 'Next')
                                              : 'Login',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 16 : 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildPinField(
      TextEditingController controller, String hint, bool isConfirm) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 280),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2.0,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
        ),
        style: TextStyle(
          fontSize: 20,
          letterSpacing: 8,
          fontWeight: FontWeight.bold,
        ),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        obscureText: true,
        enableSuggestions: false,
        autocorrect: false,
        maxLength: 8,
        onChanged: (_) {
          if (_showError) {
            setState(() {
              _showError = false;
            });
          }
        },
        autofocus: isConfirm,
      ),
    );
  }
}
