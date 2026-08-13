import 'package:flutter/material.dart';
import '../../../../core/storage/secure_storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final String recoveryKey;
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const SettingsScreen({
    Key? key,
    required this.user,
    required this.recoveryKey,
    required this.onBack,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _appLock = true;
  bool _biometric = true;
  bool _ghostMode = false;
  bool _showRecoveryKey = false;

  Future<void> _handleLogout() async {
    await SecureStorageService.delete('auth_token');
    await SecureStorageService.delete('user_info');
    widget.onLogout();
  }

  void _showChangePasswordModal() {
    final currPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    String? modalError;
    bool successMsg = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) => AlertDialog(
          backgroundColor: const Color(0xFF12141D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: Color(0xFF10B981), size: 22),
              SizedBox(width: 8),
              Text('Change Password', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (modalError != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF43F5E).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(modalError!, style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 12), textAlign: TextAlign.center),
                ),
                const SizedBox(height: 10),
              ],
              if (successMsg) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Password changed successfully!', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
                const SizedBox(height: 10),
              ] else ...[
                TextField(
                  controller: currPassCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Current Password',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newPassCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'New Password',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmPassCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Confirm New Password',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            if (!successMsg)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                onPressed: () {
                  if (currPassCtrl.text.isEmpty || newPassCtrl.text.isEmpty) {
                    setStateModal(() => modalError = 'Please fill all fields');
                    return;
                  }
                  if (newPassCtrl.text != confirmPassCtrl.text) {
                    setStateModal(() => modalError = 'New Passwords do not match');
                    return;
                  }
                  setStateModal(() {
                    modalError = null;
                    successMsg = true;
                  });
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    if (ctx.mounted) Navigator.pop(ctx);
                  });
                },
                child: const Text('Update', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.user?['username'] ?? '@harsh01';
    final privateId = widget.user?['privateId'] ?? 'USER-7XK92P';

    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090A0F),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: widget.onBack),
        title: const Text('Privacy & Security Settings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
                    child: Text(username.length > 2 ? username.substring(1, 3).toUpperCase() : 'ME', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(privateId, style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'monospace')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Ghost Mode Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.08),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.visibility_off_outlined, color: Color(0xFF10B981), size: 20),
                          SizedBox(width: 8),
                          Text('GHOST MODE', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13)),
                        ],
                      ),
                      Switch(
                        value: _ghostMode,
                        activeColor: const Color(0xFF10B981),
                        onChanged: (val) => setState(() => _ghostMode = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enforces 30s auto-disappearing messages, view-once media, hidden notification previews, and aggressive cache wiping.',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('PRIVACY & LOCK', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('App Lock (PIN)', style: TextStyle(color: Colors.white, fontSize: 14)),
              value: _appLock,
              activeColor: const Color(0xFF10B981),
              onChanged: (val) => setState(() => _appLock = val),
            ),
            SwitchListTile(
              title: const Text('Biometric Unlock', style: TextStyle(color: Colors.white, fontSize: 14)),
              value: _biometric,
              activeColor: const Color(0xFF10B981),
              onChanged: (val) => setState(() => _biometric = val),
            ),

            const SizedBox(height: 16),
            const Text('SECURITY & KEYS', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.lock_reset, color: Color(0xFF10B981)),
              title: const Text('Change Password', style: TextStyle(color: Colors.white, fontSize: 14)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              onTap: _showChangePasswordModal,
            ),
            ListTile(
              leading: const Icon(Icons.key, color: Colors.amber),
              title: const Text('View Recovery Key', style: TextStyle(color: Colors.white, fontSize: 14)),
              trailing: Text(_showRecoveryKey ? 'Hide' : 'View', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
              onTap: () => setState(() => _showRecoveryKey = !_showRecoveryKey),
            ),
            if (_showRecoveryKey)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black.withOpacity(0.5),
                child: Text(widget.recoveryKey, textAlign: TextAlign.center, style: const TextStyle(color: Colors.amber, fontFamily: 'monospace', fontSize: 12)),
              ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF43F5E).withOpacity(0.1),
                  side: BorderSide(color: const Color(0xFFF43F5E).withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout, color: Color(0xFFF43F5E), size: 18),
                label: const Text('Logout / Clear Identity', style: TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.bold)),
                onPressed: _handleLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
