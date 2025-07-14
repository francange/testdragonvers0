import 'package:flutter/material.dart';
import '../controller/auth_controller.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthController _authController = AuthController();

  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;

  static const Color primaryColor = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      setState(() {
        _emailError = _authController.validateEmail(_emailController.text.trim());
      });
    });
    _passwordController.addListener(() {
      setState(() {
        _passwordError = _authController.validatePassword(_passwordController.text);
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailError = _authController.validateEmail(email);
    final passwordError = _authController.validatePassword(password);

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _errorMessage = null;
    });

    if (emailError != null || passwordError != null) return;

    setState(() {
      _isLoading = true;
    });

    final error = await _authController.register(email, password);

    setState(() {
      _isLoading = false;
      _errorMessage = error;
    });

    if (error == null && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboardsales');
    }
  }

  InputDecoration _inputDecoration(String label, {String? errorText}) {
    return InputDecoration(
      labelText: label,
      errorText: errorText,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: TextStyle(color: primaryColor.withOpacity(0.8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(primary: primaryColor),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Registrarse'),
          backgroundColor: Colors.white,
          foregroundColor: primaryColor,
          elevation: 1,
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add_alt, size: 90, color: primaryColor.withOpacity(0.8)),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: primaryColor,
                  decoration: _inputDecoration('Correo electrónico', errorText: _emailError),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  cursorColor: primaryColor,
                  decoration: _inputDecoration('Contraseña', errorText: _passwordError).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: primaryColor.withOpacity(0.8),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        shadowColor: primaryColor.withOpacity(0.5),
                      ),
                      child: const Text('Registrarse', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
