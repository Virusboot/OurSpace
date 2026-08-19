import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/widgets/app_gradient_button.dart';

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
  int _currentStep = 0; // 0: Welcome, 1: Private ID, 2: Choose Username, 3: Recovery Key, 4: Set PIN, 5: Enable Biometrics, 6: Import

  // Onboarding user state
  late String _privateId;
  final TextEditingController _privateIdController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late String _recoveryKey;
  String _enteredPin = '';
  bool _loading = false;
  String? _errorMsg;

  // Import fields
  final TextEditingController _importIdController = TextEditingController();
  final TextEditingController _importKeyController = TextEditingController();

  static const List<String> _wordList = [
    'wood', 'apple', 'river', 'sun', 'stone',
    'green', 'rocket', 'paper', 'sky', 'forest',
    'mountain', 'wave', 'cloud', 'ocean', 'wind',
    'fire', 'star', 'night', 'dream', 'light',
    'valley', 'hill', 'tree', 'flower', 'leaf',
    'rain', 'snow', 'storm', 'desert', 'lake'
  ];

  @override
  void initState() {
    super.initState();
    _generateOnboardingData();
    _usernameController.addListener(() {
      if (mounted) setState(() {});
    });
    _passwordController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _generateOnboardingData() {
    // Generate private ID - easy 4-digit code
    final rand = Random();
    _privateId = 'USER-${1000 + rand.nextInt(9000)}';
    _privateIdController.text = _privateId;

    // Generate recovery key (9 words)
    final words = <String>[];
    final copyList = List<String>.from(_wordList);
    for (int i = 0; i < 9; i++) {
      final index = rand.nextInt(copyList.length);
      words.add(copyList.removeAt(index));
    }
    _recoveryKey = words.join(' ');
  }

  @override
  void dispose() {
    _privateIdController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _importIdController.dispose();
    _importKeyController.dispose();
    super.dispose();
  }

  // Copies content to clipboard and shows snackbar
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text('$label copied to clipboard!', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: widget.isDarkMode ? const Color(0xFF121317) : Colors.white,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Keypad Tap
  void _onKeyTap(String key) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += key;
      });
      if (_enteredPin.length == 4) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _currentStep = 5; // Go to Biometrics
            });
          }
        });
      }
    }
  }

  // Keypad Backspace
  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _enableBiometricsAndComplete() async {
    try {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (canCheck) {
        final authenticated = await auth.authenticate(
          localizedReason: 'Authenticate using Face ID or Fingerprint to enable secure lock',
          options: const AuthenticationOptions(
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
        if (authenticated) {
          await SecureStorageService.write('biometric_enabled', 'true');
          await _completeRegistration();
        } else {
          setState(() {
            _errorMsg = 'Biometric authentication failed. Please try again.';
          });
        }
      } else {
        setState(() {
          _errorMsg = 'Biometrics not supported on this device.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Biometrics setup error: ${e.toString()}';
      });
    }
  }

  Future<void> _skipBiometricsAndComplete() async {
    await SecureStorageService.write('biometric_enabled', 'false');
    await _completeRegistration();
  }

  // Complete Registration (Create Account)
  Future<void> _completeRegistration() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    _privateId = _privateIdController.text.trim().toUpperCase();
    final customUser = _usernameController.text.trim();
    final username = customUser.startsWith('@') ? customUser : '@$customUser';
    final derivedEmail = '${_privateId.toLowerCase()}@ourspace.local';
    final derivedPassword = _passwordController.text.trim();

    Map<String, dynamic> userObj;
    String token;

    try {
      // Hit backend register
      final res = await ApiClient.post('/auth/register', {
        'name': username.replaceFirst('@', ''),
        'email': derivedEmail,
        'password': derivedPassword,
        'username': username,
        'privateId': _privateId,
      }).timeout(const Duration(seconds: 3));

      if (res['user'] != null) {
        userObj = Map<String, dynamic>.from(res['user']);
        userObj['password'] = derivedPassword;
        userObj['privateId'] = _privateId;
        token = res['token'] ?? 'token_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        throw Exception(res['error'] ?? 'Registration failed');
      }
    } catch (_) {
      // Local fallback
      userObj = {
        'id': 'usr_${DateTime.now().millisecondsSinceEpoch}',
        'name': username.replaceFirst('@', ''),
        'email': derivedEmail,
        'username': username,
        'privateId': _privateId,
        'password': derivedPassword,
        'createdAt': DateTime.now().toIso8601String(),
      };
      token = 'token_local_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Save user info
    final accountsJson = await SecureStorageService.read('registered_accounts');
    Map<String, dynamic> accountsMap = {};
    if (accountsJson != null && accountsJson.isNotEmpty) {
      try {
        accountsMap = Map<String, dynamic>.from(jsonDecode(accountsJson));
      } catch (_) {}
    }
    accountsMap[derivedEmail] = userObj;
    await SecureStorageService.write('registered_accounts', jsonEncode(accountsMap));
    await SecureStorageService.write('auth_token', token);
    await SecureStorageService.write('user_info', jsonEncode(userObj));
    await SecureStorageService.write('app_lock_enabled', 'true');
    await SecureStorageService.write('user_pin_hash', _enteredPin);

    if (mounted) {
      setState(() => _loading = false);
      widget.onIdentityCreated(userObj, _recoveryKey);
    }
  }

  // Import Account Flow
  Future<void> _handleImport() async {
    final privateIdInput = _importIdController.text.trim();
    final passwordInput = _importKeyController.text.trim();

    if (privateIdInput.isEmpty || passwordInput.isEmpty) {
      setState(() => _errorMsg = 'Please enter both Username/ID and Password.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    Map<String, dynamic> userObj;
    String token;

    try {
      // Attempt login via backend
      final res = await ApiClient.post('/auth/login', {
        'username': privateIdInput,
        'password': passwordInput,
      }).timeout(const Duration(seconds: 3));

      if (res['user'] != null) {
        userObj = Map<String, dynamic>.from(res['user']);
        userObj['password'] = passwordInput;
        userObj['privateId'] = res['user']['privateId'] ?? privateIdInput;
        token = res['token'] ?? 'token_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        throw Exception(res['error'] ?? 'Login failed');
      }
    } catch (_) {
      // Fallback: Check local SecureStorage
      final accountsJson = await SecureStorageService.read('registered_accounts');
      Map<String, dynamic> accountsMap = {};
      if (accountsJson != null && accountsJson.isNotEmpty) {
        try {
          accountsMap = Map<String, dynamic>.from(jsonDecode(accountsJson));
        } catch (_) {}
      }

      // Check if any registered account matches the username or private ID and password
      Map<String, dynamic>? matchingUser;
      for (final val in accountsMap.values) {
        if (val is Map) {
          final uName = (val['username'] ?? '').toString().toLowerCase();
          final pId = (val['privateId'] ?? '').toString().toLowerCase();
          final input = privateIdInput.toLowerCase();
          if ((uName == input || uName == '@$input' || pId == input) && val['password'] == passwordInput) {
            matchingUser = Map<String, dynamic>.from(val);
            break;
          }
        }
      }

      if (matchingUser != null) {
        userObj = matchingUser;
        token = 'token_local_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        // Fallback registration since it doesn't exist locally
        final cleanUsername = privateIdInput.startsWith('@') ? privateIdInput : '@$privateIdInput';
        userObj = {
          'id': 'usr_${DateTime.now().millisecondsSinceEpoch}',
          'name': privateIdInput,
          'email': '${privateIdInput.toLowerCase()}@ourspace.local',
          'username': cleanUsername,
          'privateId': privateIdInput.toUpperCase(),
          'password': passwordInput,
          'createdAt': DateTime.now().toIso8601String(),
        };
        token = 'token_local_${DateTime.now().millisecondsSinceEpoch}';
        accountsMap[userObj['email']] = userObj;
        await SecureStorageService.write('registered_accounts', jsonEncode(accountsMap));
      }
    }

    await SecureStorageService.write('auth_token', token);
    await SecureStorageService.write('user_info', jsonEncode(userObj));
    await SecureStorageService.write('app_lock_enabled', 'false');

    if (mounted) {
      setState(() => _loading = false);
      widget.onIdentityCreated(userObj, passwordInput);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final scaffoldBg = isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: _buildCurrentStepView(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildPrivateIdStep();
      case 2:
        return _buildUsernameStep();
      case 3:
        return _buildRecoveryKeyStep();
      case 4:
        return _buildSetPinStep();
      case 5:
        return _buildBiometricsStep();
      case 6:
        return _buildImportStep();
      default:
        return _buildWelcomeStep();
    }
  }

  // ==========================================
  // STEP 0: WELCOME SCREEN
  // ==========================================
  Widget _buildWelcomeStep() {
    final isDark = widget.isDarkMode;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.grey : const Color(0xFF475569);

    return Column(
      children: [
        const SizedBox(height: 100),
        // Shield Lock Icon with glow
        Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF7B2FBE).withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF7B2FBE).withValues(alpha: 0.2), width: 1.5),
            ),
            child: const Center(
              child: Icon(Icons.shield_rounded, size: 72, color: Color(0xFF7B2FBE)),
            ),
          ),
        ),
        const SizedBox(height: 48),
        Text(
          'Welcome to SecureChat',
          textAlign: TextAlign.center,
          style: TextStyle(color: titleColor, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        Text(
          'Private. Encrypted. Yours.',
          textAlign: TextAlign.center,
          style: TextStyle(color: subtitleColor, fontSize: 15, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 100),

        // Action Buttons
        AppGradientButton(
          label: 'Create New Identity',
          onTap: () => setState(() => _currentStep = 1),
          borderRadius: 28,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() {
            _errorMsg = null;
            _currentStep = 6;
          }),
          child: const Text(
            'Import Existing',
            style: TextStyle(color: Color(0xFF7B2FBE), fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 1: YOUR PRIVATE ID
  // ==========================================
  Widget _buildPrivateIdStep() {
    final isDark = widget.isDarkMode;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.grey : const Color(0xFF475569);
    final boxBg = isDark ? const Color(0xFF121317) : const Color(0xFFF1F5F9);
    final boxBorder = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Text('Your Private ID', style: TextStyle(color: titleColor, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'This is your unique private identity. Share it only with people you trust.',
          style: TextStyle(color: subtitleColor, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 48),

        // Private ID Box - Editable text field
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: boxBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: boxBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _privateIdController,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1.5,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Color(0xFF7B2FBE), size: 24),
                onPressed: () {
                  _privateId = _privateIdController.text.trim().toUpperCase();
                  _copyToClipboard(_privateId, 'Private ID');
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 120),

        // Continue Button
        AppGradientButton(
          label: 'Continue',
          onTap: () => setState(() => _currentStep = 2),
          borderRadius: 28,
        ),
      ],
    );
  }

  // ==========================================
  // STEP 2: CHOOSE USERNAME
  // ==========================================
  Widget _buildUsernameStep() {
    final isDark = widget.isDarkMode;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.grey : const Color(0xFF475569);
    final inputBg = isDark ? const Color(0xFF121317) : const Color(0xFFF1F5F9);
    final inputBorder = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);
    final usernameInput = _usernameController.text.trim();
    final isValid = usernameInput.length >= 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Text('Choose Username', style: TextStyle(color: titleColor, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'This is how others can find you.',
          style: TextStyle(color: subtitleColor, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 48),

        // Username Input field
        TextField(
          controller: _usernameController,
          style: TextStyle(color: titleColor, fontSize: 16, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF7B2FBE), size: 22),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFF7B2FBE), width: 1.5),
            ),
            hintText: 'e.g. priyanshu',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ),
        const SizedBox(height: 120),

        // Continue Button
        AppGradientButton(
          label: 'Continue',
          onTap: isValid ? () => setState(() => _currentStep = 3) : null,
          borderRadius: 28,
        ),
      ],
    );
  }

  // ==========================================
  // STEP 3: CREATE PASSWORD
  // ==========================================
  Widget _buildRecoveryKeyStep() {
    final isDark = widget.isDarkMode;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.grey : const Color(0xFF475569);
    final inputBg = isDark ? const Color(0xFF121317) : const Color(0xFFF1F5F9);
    final inputBorder = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);
    final passInput = _passwordController.text.trim();
    final isValid = passInput.length >= 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Text('Create Password', style: TextStyle(color: titleColor, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'Choose a self-made password to secure your account.',
          style: TextStyle(color: subtitleColor, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 48),

        // Password Input field
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: TextStyle(color: titleColor, fontSize: 16, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF7B2FBE), size: 22),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFF7B2FBE), width: 1.5),
            ),
            hintText: 'Minimum 6 characters',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ),
        const SizedBox(height: 120),

        // Continue Button
        AppGradientButton(
          label: 'Continue',
          onTap: isValid ? () => setState(() => _currentStep = 4) : null,
          borderRadius: 28,
        ),
      ],
    );
  }

  // ==========================================
  // STEP 4: SET PIN SCREEN
  // ==========================================
  Widget _buildSetPinStep() {
    final isDark = widget.isDarkMode;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.grey : const Color(0xFF475569);

    return Column(
      children: [
        const SizedBox(height: 30),
        Text('Set PIN', style: TextStyle(color: titleColor, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Create a 4-digit PIN', style: TextStyle(color: subtitleColor, fontSize: 14)),
        const SizedBox(height: 48),

        // Dots Progress Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (idx) {
            final active = _enteredPin.length > idx;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF7B2FBE) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: active ? const Color(0xFF7B2FBE) : (isDark ? Colors.white24 : Colors.black26), width: 2),
              ),
            );
          }),
        ),
        const SizedBox(height: 60),

        // Keypad Grid Layout
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildNumericKeypad(),
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String label, VoidCallback onTap) {
    final isDark = widget.isDarkMode;
    final color = isDark ? Colors.white : const Color(0xFF0F172A);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          height: 68,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadIcon(IconData icon, VoidCallback onTap) {
    final isDark = widget.isDarkMode;
    final color = isDark ? Colors.white : const Color(0xFF0F172A);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          height: 68,
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildKeypadButton('1', () => _onKeyTap('1'))),
            Expanded(child: _buildKeypadButton('2', () => _onKeyTap('2'))),
            Expanded(child: _buildKeypadButton('3', () => _onKeyTap('3'))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildKeypadButton('4', () => _onKeyTap('4'))),
            Expanded(child: _buildKeypadButton('5', () => _onKeyTap('5'))),
            Expanded(child: _buildKeypadButton('6', () => _onKeyTap('6'))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildKeypadButton('7', () => _onKeyTap('7'))),
            Expanded(child: _buildKeypadButton('8', () => _onKeyTap('8'))),
            Expanded(child: _buildKeypadButton('9', () => _onKeyTap('9'))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: SizedBox()),
            Expanded(child: _buildKeypadButton('0', () => _onKeyTap('0'))),
            Expanded(child: _buildKeypadIcon(Icons.backspace_rounded, _onBackspace)),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // STEP 5: ENABLE BIOMETRICS SCREEN
  // ==========================================
  Widget _buildBiometricsStep() {
    final isDark = widget.isDarkMode;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.grey : const Color(0xFF475569);

    return Column(
      children: [
        const SizedBox(height: 60),
        Text('Enable Biometrics', style: TextStyle(color: titleColor, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Unlock your app securely using Face ID', style: TextStyle(color: subtitleColor, fontSize: 14)),
        const SizedBox(height: 80),

        // Glowing Face ID Icon
        Center(
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFF7B2FBE).withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF7B2FBE).withValues(alpha: 0.2), width: 1.5),
            ),
            child: const Center(
              child: Icon(Icons.face_unlock_rounded, size: 68, color: Color(0xFF7B2FBE)),
            ),
          ),
        ),
        if (_errorMsg != null) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMsg!,
              style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 80),

        // Buttons
        AppGradientButton(
          label: _loading ? 'Completing...' : 'Enable',
          onTap: _loading ? null : _enableBiometricsAndComplete,
          isLoading: _loading,
          borderRadius: 28,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _loading ? null : _skipBiometricsAndComplete,
          child: const Text(
            'Skip',
            style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 6: IMPORT IDENTITY
  // ==========================================
  Widget _buildImportStep() {
    final isDark = widget.isDarkMode;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.grey : const Color(0xFF475569);
    final inputBg = isDark ? const Color(0xFF121317) : const Color(0xFFF1F5F9);
    final inputBorder = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Text('Import Identity', style: TextStyle(color: titleColor, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'Enter your details to restore your profile',
          style: TextStyle(color: subtitleColor, fontSize: 14),
        ),
        const SizedBox(height: 36),

        if (_errorMsg != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
              border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_errorMsg!, style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
        ],

        // Private ID / Username Field
        Text('Username or Private ID', style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: _importIdController,
          style: TextStyle(color: titleColor, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF7B2FBE), size: 20),
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: inputBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: inputBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF7B2FBE), width: 1.5)),
            hintText: 'e.g. @priyanshu or USER-1234',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        const SizedBox(height: 20),

        // Password Field
        Text('Password', style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: _importKeyController,
          obscureText: true,
          style: TextStyle(color: titleColor, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF7B2FBE), size: 20),
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: inputBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: inputBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF7B2FBE), width: 1.5)),
            hintText: 'Enter your password',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        const SizedBox(height: 60),

        // Action Buttons
        AppGradientButton(
          label: _loading ? 'Restoring...' : 'Restore Identity',
          onTap: _loading ? null : _handleImport,
          isLoading: _loading,
          borderRadius: 28,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _currentStep = 0),
            child: const Text('Back to Welcome', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
