import 'package:flutter/material.dart';
import '../../../../core/storage/secure_storage_service.dart';

class CreatePinScreen extends StatefulWidget {
  final VoidCallback onPinComplete;

  const CreatePinScreen({super.key, required this.onPinComplete});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirm = false;
  bool _biometricEnabled = true;
  String? _errorMsg;

  void _handleKeyPress(String digit) {
    setState(() {
      _errorMsg = null;
      if (!_isConfirm) {
        if (_pin.length < 4) {
          _pin += digit;
          if (_pin.length == 4) {
            Future.delayed(const Duration(milliseconds: 200), () {
              setState(() => _isConfirm = true);
            });
          }
        }
      } else {
        if (_confirmPin.length < 4) {
          _confirmPin += digit;
          if (_confirmPin.length == 4) {
            _verifyPin();
          }
        }
      }
    });
  }

  void _handleDelete() {
    setState(() {
      if (!_isConfirm) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_confirmPin.isNotEmpty) _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      }
    });
  }

  Future<void> _verifyPin() async {
    if (_pin == _confirmPin) {
      await SecureStorageService.write('user_pin_hash', _pin);
      await SecureStorageService.write('biometric_enabled', _biometricEnabled ? 'true' : 'false');
      widget.onPinComplete();
    } else {
      setState(() {
        _errorMsg = 'PINs do not match. Try again.';
        _pin = '';
        _confirmPin = '';
        _isConfirm = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final digits = _isConfirm ? _confirmPin : _pin;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC);
    final textTitle = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? Colors.grey : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF121317) : const Color(0xFFFFFFFF);
    final cardBorder = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0);
    final dotUnfilledBorder = isDark ? Colors.white24 : const Color(0xFFCBD5E1);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onPinComplete,
                  child: const Text('Skip for now →', style: TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                !_isConfirm ? 'Create App PIN' : 'Confirm Your PIN',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textTitle),
              ),
              const SizedBox(height: 4),
              Text(
                !_isConfirm ? 'Set a 4-digit security PIN to protect app access' : 'Re-enter your 4-digit PIN',
                style: TextStyle(fontSize: 12, color: textSub),
              ),
              const SizedBox(height: 12),

              if (_errorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(_errorMsg!, style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 12)),
                ),

              // PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < digits.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? const Color(0xFF0066FF) : Colors.transparent,
                      border: Border.all(color: filled ? const Color(0xFF0066FF) : dotUnfilledBorder),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Biometric switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border.all(color: cardBorder),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fingerprint, size: 20, color: Color(0xFF0066FF)),
                        const SizedBox(width: 10),
                        Text('Enable Face ID / Biometrics', style: TextStyle(color: textTitle, fontSize: 13)),
                      ],
                    ),
                    Switch(
                      value: _biometricEnabled,
                      activeColor: const Color(0xFF0066FF),
                      onChanged: (val) => setState(() => _biometricEnabled = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Keypad
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 1.6,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((num) => _buildKey(num, isDark)),
                    const SizedBox(),
                    _buildKey('0', isDark),
                    IconButton(
                      icon: Icon(Icons.backspace_outlined, color: textSub),
                      onPressed: _handleDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKey(String label, bool isDark) {
    final keyBg = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0);
    final keyTxt = isDark ? Colors.white : const Color(0xFF0F172A);

    return InkWell(
      onTap: () => _handleKeyPress(label),
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          color: keyBg,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: keyTxt)),
        ),
      ),
    );
  }
}
