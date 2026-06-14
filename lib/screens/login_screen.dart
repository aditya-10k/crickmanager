import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true;
  bool _obscurePassword = true;
  String _errorMsg = '';
  String _successMsg = '';

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: const Interval(0.0, 0.7)),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    setState(() {
      _errorMsg = '';
      _successMsg = '';
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = 'Please enter both username and password.');
      return;
    }

    final provider = Provider.of<GameProvider>(context, listen: false);
    if (_isLoginMode) {
      final err = await provider.login(username, password);
      if (err != null) setState(() => _errorMsg = err);
    } else {
      final err = await provider.register(username, password);
      if (err != null) {
        setState(() => _errorMsg = err);
      } else {
        setState(() {
          _successMsg = 'Registration successful! You can now log in.';
          _isLoginMode = true;
          _passwordController.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<GameProvider, bool>((p) => p.isLoading);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Animated background glow orbs
          Positioned(
            top: -80,
            left: -60,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.neonPink.withOpacity(0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: 1.1 - (_pulseAnim.value - 0.85) * 0.4,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.neonPink.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Grid lines decoration (subtle)
          CustomPaint(
            size: size,
            painter: _GridPainter(),
          ),

          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isDesktop ? 440 : 400),
                    child: Column(
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 40),
                        _buildFormCard(isLoading),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) => Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.neonPinkDim,
              border: Border.all(color: AppTheme.neonPink.withOpacity(0.6), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonPink.withOpacity(0.2 + 0.15 * _pulseAnim.value),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: child,
          ),
          child: const Icon(Icons.sports_cricket, size: 38, color: AppTheme.neonPink),
        ),
        const SizedBox(height: 20),
        Text(
          'CRICMANAGER',
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.neonPinkDim,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.neonPink.withOpacity(0.3)),
          ),
          child: Text(
            'STRATEGIC MONEYBALL CRICKET SIMULATOR',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppTheme.neonPink,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab switch
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Row(
              children: [
                _buildTab('Login', _isLoginMode),
                _buildTab('Register', !_isLoginMode),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Error / Success banners
          if (_errorMsg.isNotEmpty) _buildBanner(_errorMsg, isError: true),
          if (_successMsg.isNotEmpty) _buildBanner(_successMsg, isError: false),

          // Username
          Text('USERNAME', style: AppTheme.label),
          const SizedBox(height: 8),
          TextField(
            controller: _usernameController,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            decoration: AppTheme.inputDecoration(
              hint: 'Enter your username',
              prefix: const Icon(Icons.person_outline, color: AppTheme.textMuted, size: 18),
            ),
          ),
          const SizedBox(height: 20),

          // Password
          Text('PASSWORD', style: AppTheme.label),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            onSubmitted: isLoading ? null : (_) => _submitForm(),
            decoration: AppTheme.inputDecoration(
              hint: '••••••••',
              prefix: const Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 18),
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppTheme.textMuted,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Submit Button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: isLoading ? null : AppTheme.pinkGradient,
              color: isLoading ? AppTheme.surfaceBorder : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isLoading ? [] : AppTheme.pinkGlow,
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _isLoginMode ? 'LOGIN' : 'CREATE ACCOUNT',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Toggle
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _isLoginMode = !_isLoginMode;
                _errorMsg = '';
                _successMsg = '';
              }),
              style: TextButton.styleFrom(foregroundColor: AppTheme.neonPink),
              child: Text(
                _isLoginMode
                    ? 'New to CricManager? Register here →'
                    : 'Already have an account? Login here →',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _isLoginMode = label == 'Login';
          _errorMsg = '';
          _successMsg = '';
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.neonPink : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive ? AppTheme.pinkGlow : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBanner(String msg, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isError ? const Color(0x22F87171) : const Color(0x2234D399),
        border: Border.all(
          color: isError ? AppTheme.errorColor.withOpacity(0.4) : AppTheme.batColor.withOpacity(0.4),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? AppTheme.errorColor : AppTheme.batColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.inter(
                color: isError ? AppTheme.errorColor : AppTheme.batColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 0.5;

    const step = 50.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
