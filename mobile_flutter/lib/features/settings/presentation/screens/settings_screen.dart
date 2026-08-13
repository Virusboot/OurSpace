import 'package:flutter/material.dart';
import '../../../../core/storage/secure_storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final String recoveryKey;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const SettingsScreen({
    Key? key,
    required this.user,
    required this.recoveryKey,
    required this.isDarkMode,
    required this.onToggleTheme,
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
    final isDark = widget.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF141824) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.lock_reset, color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 8),
              Text('Change Password', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
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
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Current Password',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: isDark ? Colors.black.withOpacity(0.4) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newPassCtrl,
                  obscureText: true,
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'New Password',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: isDark ? Colors.black.withOpacity(0.4) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmPassCtrl,
                  obscureText: true,
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Confirm New Password',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: isDark ? Colors.black.withOpacity(0.4) : const Color(0xFFF1F5F9),
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
    final isDark = widget.isDarkMode;

    final bgCol = isDark ? const Color(0xFF0A0D14) : const Color(0xFFF8FAFC);
    final txtCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDark ? const Color(0xFF141824) : Colors.white;

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: bgCol,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: txtCol), onPressed: widget.onBack),
        title: Text('Privacy & Security Settings', style: TextStyle(color: txtCol, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                      Text(username, style: TextStyle(color: txtCol, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(privateId, style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'monospace')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // App Appearance & Theme Selector Tile
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.06)),
              ),
              child: ListTile(
                leading: Icon(
                  isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                  color: isDark ? Colors.amber : const Color(0xFF0F172A),
                ),
                title: Text('App Appearance', style: TextStyle(color: txtCol, fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: Text(isDark ? 'Dark Mode Active' : 'Light Mode Active', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: Switch(
                  value: !isDark,
                  activeColor: const Color(0xFF10B981),
                  onChanged: (_) => widget.onToggleTheme(),
                ),
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
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('App Lock (PIN)', style: TextStyle(color: txtCol, fontSize: 14)),
                    value: _appLock,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (val) => setState(() => _appLock = val),
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                  SwitchListTile(
                    title: Text('Biometric Unlock', style: TextStyle(color: txtCol, fontSize: 14)),
                    value: _biometric,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (val) => setState(() => _biometric = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text('SECURITY & KEYS', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_reset, color: Color(0xFF10B981)),
                    title: Text('Change Password', style: TextStyle(color: txtCol, fontSize: 14)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: _showChangePasswordModal,
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                  ListTile(
                    leading: const Icon(Icons.key, color: Colors.amber),
                    title: Text('View Recovery Key', style: TextStyle(color: txtCol, fontSize: 14)),
                    trailing: Text(_showRecoveryKey ? 'Hide' : 'View', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                    onTap: () => setState(() => _showRecoveryKey = !_showRecoveryKey),
                  ),
                  if (_showRecoveryKey)
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: isDark ? Colors.black.withOpacity(0.5) : const Color(0xFFFEF3C7),
                      child: Text(widget.recoveryKey, textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.amber : const Color(0xFFB45309), fontFamily: 'monospace', fontSize: 12)),
                    ),
                ],
              ),
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
