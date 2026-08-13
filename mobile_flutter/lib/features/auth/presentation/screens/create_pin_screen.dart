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

    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onPinComplete,
                  child: const Text('Skip for now →', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: const Icon(Icons.lock_outline, size: 32, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 16),
              Text(
                !_isConfirm ? 'Create App PIN' : 'Confirm Your PIN',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                !_isConfirm ? 'Set a 4-digit security PIN to protect app access' : 'Re-enter your 4-digit PIN',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              if (_errorMsg != null)
                Text(_errorMsg!, style: const TextStyle(color: const Color(0xFFF43F5E), fontSize: 12)),

              const SizedBox(height: 24),

              // PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < digits.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? const Color(0xFF10B981) : Colors.transparent,
                      border: Border.all(color: filled ? const Color(0xFF10B981) : Colors.white24),
                    ),
                  );
                }),
              ),
              const Spacer(),

              // Biometric switch
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.fingerprint, size: 20, color: Color(0xFF10B981)),
                        SizedBox(width: 10),
                        Text('Enable Face ID / Biometrics', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                    Switch(
                      value: _biometricEnabled,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) => setState(() => _biometricEnabled = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Keypad
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((num) => _buildKey(num)),
                  const SizedBox(),
                  _buildKey('0'),
                  IconButton(
                    icon: const Icon(Icons.backspace_outlined, color: Colors.grey),
                    onPressed: _handleDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKey(String label) {
    return InkWell(
      onTap: () => _handleKeyPress(label),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}
