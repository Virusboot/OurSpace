import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';

class CreateIdentityScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(Map<String, dynamic> user, String recoveryKey) onIdentityCreated;

  const CreateIdentityScreen({
    super.key,
    this.isDarkMode = false,
    required this.onIdentityCreated,
  });

  @override
  State<CreateIdentityScreen> createState() => _CreateIdentityScreenState();
}

class _CreateIdentityScreenState extends State<CreateIdentityScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isSignUp = true; // Default to Create Account mode
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLoginOrRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = 'Please enter Email Address and Password');
      return;
    }

    final lowerEmail = email.toLowerCase();

    // Fetch existing registered accounts from SecureStorageService
    final accountsJson = await SecureStorageService.read('registered_accounts');
    Map<String, dynamic> accountsMap = {};
    if (accountsJson != null && accountsJson.isNotEmpty) {
      try {
        accountsMap = Map<String, dynamic>.from(jsonDecode(accountsJson));
      } catch (_) {}
    }

    if (_isSignUp) {
      // REGISTRATION FLOW
      if (name.isEmpty) {
        setState(() => _errorMsg = 'Please enter your Full Name');
        return;
      }
      if (password.length < 4) {
        setState(() => _errorMsg = 'Password must be at least 4 characters long');
        return;
      }
      if (password != confirmPassword) {
        setState(() => _errorMsg = 'Passwords do not match');
        return;
      }

      // Check if email is already registered locally
      if (accountsMap.containsKey(lowerEmail)) {
        setState(() => _errorMsg = 'An account with this email already exists. Please Log In instead.');
        return;
      }

      setState(() {
        _loading = true;
        _errorMsg = null;
      });

      final customUsername = _usernameController.text.trim();
      final baseUsername = email.contains('@') ? email.split('@')[0] : email;
      final randomSuffix = (DateTime.now().millisecondsSinceEpoch % 9000 + 1000).toString();
      final username = customUsername.isNotEmpty
          ? (customUsername.startsWith('@') ? customUsername : '@$customUsername')
          : '@${baseUsername.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')}_$randomSuffix';
      final privateId = 'USER-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      Map<String, dynamic> userObj;
      String token;

      try {
        final res = await ApiClient.post('/auth/register', {
          'name': name,
          'email': lowerEmail,
          'password': password,
          'username': username,
        }).timeout(const Duration(seconds: 2));

        if (res['user'] != null) {
          userObj = Map<String, dynamic>.from(res['user']);
          userObj['password'] = password;
          token = res['token'] ?? 'token_${DateTime.now().millisecondsSinceEpoch}';
        } else {
          throw Exception(res['error'] ?? 'Registration failed');
        }
      } catch (e) {
        final errMsg = e.toString();
        if (errMsg.contains('already exists') || errMsg.contains('taken')) {
          setState(() {
            _loading = false;
            _errorMsg = 'An account with this email already exists. Please Log In instead.';
          });
          return;
        }

        // Local registration fallback
        userObj = {
          'id': 'usr_${DateTime.now().millisecondsSinceEpoch}',
          'name': name,
          'email': lowerEmail,
          'username': username,
          'privateId': privateId,
          'password': password,
          'createdAt': DateTime.now().toIso8601String(),
        };
        token = 'token_local_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Save user to registered accounts database
      accountsMap[lowerEmail] = userObj;
      await SecureStorageService.write('registered_accounts', jsonEncode(accountsMap));
      await SecureStorageService.write('auth_token', token);
      await SecureStorageService.write('user_info', jsonEncode(userObj));

      if (mounted) {
        setState(() => _loading = false);
        widget.onIdentityCreated(userObj, 'rec_key_${DateTime.now().millisecondsSinceEpoch}');
      }

    } else {
      // LOGIN FLOW
      setState(() {
        _loading = true;
        _errorMsg = null;
      });

      Map<String, dynamic>? userObj;
      String token = 'token_local_${DateTime.now().millisecondsSinceEpoch}';

      try {
        final res = await ApiClient.post('/auth/login', {
          'email': lowerEmail,
          'password': password,
        }).timeout(const Duration(seconds: 2));

        if (res['user'] != null) {
          userObj = Map<String, dynamic>.from(res['user']);
          userObj['password'] = password;
          token = res['token'] ?? 'token_${DateTime.now().millisecondsSinceEpoch}';
        } else {
          throw Exception(res['error'] ?? 'Login failed');
        }
      } catch (e) {
        // Local Login Verification Fallback
        if (!accountsMap.containsKey(lowerEmail)) {
          setState(() {
            _loading = false;
            _errorMsg = 'No account found with this email. Please Create an Account first.';
          });
          return;
        }

        final existingUser = Map<String, dynamic>.from(accountsMap[lowerEmail] as Map);
        if (existingUser['password'] != password) {
          setState(() {
            _loading = false;
            _errorMsg = 'Incorrect Password. Please try again.';
          });
          return;
        }

        userObj = existingUser;
        token = 'token_local_${DateTime.now().millisecondsSinceEpoch}';
      }

      await SecureStorageService.write('auth_token', token);
      await SecureStorageService.write('user_info', jsonEncode(userObj));

      if (mounted) {
        setState(() => _loading = false);
        widget.onIdentityCreated(userObj, 'rec_key_${DateTime.now().millisecondsSinceEpoch}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final scaffoldBg = isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC);
    final cardBorder = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0);
    final inputBg = isDark ? Colors.black.withOpacity(0.4) : const Color(0xFFF1F5F9);
    final textTitle = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? Colors.grey : const Color(0xFF64748B);
    final inputTxt = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _isSignUp ? 'Create OurSpace Account' : 'Welcome Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textTitle),
                ),
                const SizedBox(height: 6),
                Text(
                  _isSignUp
                      ? 'Fill in your details below to create your account'
                      : 'Log in with your registered Email & Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: textSub),
                ),
                const SizedBox(height: 20),

                // Mode Switcher Segmented Control (Create Account vs Log In)
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isSignUp = true;
                            _errorMsg = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _isSignUp ? const Color(0xFF0066FF) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Create Account',
                              style: TextStyle(
                                color: _isSignUp ? Colors.white : textSub,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isSignUp = false;
                            _errorMsg = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: !_isSignUp ? const Color(0xFF0066FF) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Log In',
                              style: TextStyle(
                                color: !_isSignUp ? Colors.white : textSub,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF43F5E).withOpacity(0.1),
                      border: Border.all(color: const Color(0xFFF43F5E).withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_errorMsg!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                ],

                // Full Name & Username Input Boxes (Only for Sign Up)
                if (_isSignUp) ...[
                  Text('Full Name', style: TextStyle(fontSize: 13, color: textTitle, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: inputTxt, fontSize: 14),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF0066FF), size: 20),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cardBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5)),
                      hintText: 'e.g. Rahul Kumar',
                      hintStyle: TextStyle(color: textSub, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Choose Username (Optional)', style: TextStyle(fontSize: 13, color: textTitle, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _usernameController,
                    style: TextStyle(color: inputTxt, fontSize: 14),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF0066FF), size: 20),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cardBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5)),
                      hintText: 'e.g. @rahul_k',
                      hintStyle: TextStyle(color: textSub, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Email Input Box
                Text('Email Address', style: TextStyle(fontSize: 13, color: textTitle, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailController,
                  style: TextStyle(color: inputTxt, fontSize: 14),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0066FF), size: 20),
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5)),
                    hintText: 'e.g. rahul@gmail.com',
                    hintStyle: TextStyle(color: textSub, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),

                // Password Input Box
                Text('Password', style: TextStyle(fontSize: 13, color: textTitle, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: inputTxt, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0066FF), size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: textSub,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5)),
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(color: textSub, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password (Only for Sign Up)
                if (_isSignUp) ...[
                  Text('Confirm Password', style: TextStyle(fontSize: 13, color: textTitle, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: inputTxt, fontSize: 14),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_reset_rounded, color: Color(0xFF0066FF), size: 20),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cardBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5)),
                      hintText: 'Re-enter your password',
                      hintStyle: TextStyle(color: textSub, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),

                // Big Primary Action Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _loading ? null : _handleLoginOrRegister,
                    child: Text(
                      _loading
                          ? 'Please wait...'
                          : (_isSignUp ? 'Create Account' : 'Log In to OurSpace'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Toggle Login / Sign Up Text Button at Bottom
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp ? 'Already have an account?' : "Don't have an account?",
                      style: TextStyle(color: textSub, fontSize: 13),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                          _errorMsg = null;
                        });
                      },
                      child: Text(
                        _isSignUp ? 'Log In' : 'Create Account',
                        style: const TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
