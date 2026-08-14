import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  XFile? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 600, maxHeight: 600, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _profileImage = picked;
        });
      }
    } catch (_) {}
  }

  void _showImagePickerOptions() {
    final isDark = widget.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF14161C) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text('Change Profile Photo', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF0066FF), child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20)),
                title: Text('Take Photo', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF0066FF), child: Icon(Icons.photo_library_rounded, color: Colors.white, size: 20)),
                title: Text('Choose from Gallery', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_profileImage != null)
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFF43F5E), child: Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20)),
                  title: const Text('Remove Photo', style: TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _profileImage = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

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
              const Icon(Icons.lock_reset, color: Color(0xFF0066FF), size: 22),
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
                  decoration: BoxDecoration(color: const Color(0xFF0066FF).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Password changed successfully!', style: TextStyle(color: Color(0xFF0066FF), fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
                const SizedBox(height: 10),
              ] else ...[
                TextField(
                  controller: currPassCtrl,
                  obscureText: true,
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Current Password',
                    hintStyle: TextStyle(color: isDark ? Colors.grey : const Color(0xFF94A3B8)),
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
                    hintStyle: TextStyle(color: isDark ? Colors.grey : const Color(0xFF94A3B8)),
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
                    hintStyle: TextStyle(color: isDark ? Colors.grey : const Color(0xFF94A3B8)),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066FF)),
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
                child: const Text('Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

    final bgCol = isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC);
    final txtCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtxtCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final sectionHeaderCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final cardBg = isDark ? const Color(0xFF121317) : Colors.white;
    final cardBorderCol = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0);
    final cardShadows = isDark
        ? null
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ];

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: bgCol,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: txtCol, size: 20),
          onPressed: widget.onBack,
        ),
        title: Text(
          'Profile & Settings',
          style: TextStyle(color: txtCol, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.2),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile User Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border.all(color: cardBorderCol),
                borderRadius: BorderRadius.circular(20),
                boxShadow: cardShadows,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showImagePickerOptions,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: _profileImage == null
                                ? const LinearGradient(
                                    colors: [Color(0xFF0066FF), Color(0xFF0044B3)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.4), width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: _profileImage != null
                                ? Image.file(
                                    File(_profileImage!.path),
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: Text(
                                      username.replaceAll('@', '').substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          right: -3,
                          bottom: -3,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0066FF),
                              shape: BoxShape.circle,
                              border: Border.all(color: cardBg, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: TextStyle(color: txtCol, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0066FF).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            privateId,
                            style: const TextStyle(
                              color: Color(0xFF0066FF),
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code_rounded, color: Color(0xFF0066FF), size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. App Appearance & Theme Selector Tile
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cardBorderCol),
                boxShadow: cardShadows,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                    color: isDark ? Colors.amber : const Color(0xFF0066FF),
                    size: 20,
                  ),
                ),
                title: Text('App Appearance', style: TextStyle(color: txtCol, fontSize: 15, fontWeight: FontWeight.bold)),
                subtitle: Text(isDark ? 'Dark Mode Active' : 'Light Mode Active', style: TextStyle(color: subtxtCol, fontSize: 12)),
                trailing: Switch(
                  value: !isDark,
                  activeColor: const Color(0xFF0066FF),
                  onChanged: (_) => widget.onToggleTheme(),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 3. Ultra-Sleek Ghost Mode Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0066FF).withOpacity(0.12) : const Color(0xFFEFF6FF),
                border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.3), width: 1.2),
                borderRadius: BorderRadius.circular(18),
                boxShadow: cardShadows,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.visibility_off_outlined, color: Color(0xFF0066FF), size: 20),
                          SizedBox(width: 10),
                          Text('GHOST MODE', style: TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 13)),
                        ],
                      ),
                      Switch(
                        value: _ghostMode,
                        activeColor: const Color(0xFF0066FF),
                        onChanged: (val) => setState(() => _ghostMode = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enforces 30s auto-disappearing messages, view-once media, hidden notification previews, and aggressive cache wiping.',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. PRIVACY & LOCK Section
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('PRIVACY & LOCK', style: TextStyle(color: sectionHeaderCol, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cardBorderCol),
                boxShadow: cardShadows,
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    title: Text('App Lock (PIN)', style: TextStyle(color: txtCol, fontSize: 14, fontWeight: FontWeight.w600)),
                    value: _appLock,
                    activeColor: const Color(0xFF0066FF),
                    onChanged: (val) => setState(() => _appLock = val),
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    title: Text('Biometric Unlock', style: TextStyle(color: txtCol, fontSize: 14, fontWeight: FontWeight.w600)),
                    value: _biometric,
                    activeColor: const Color(0xFF0066FF),
                    onChanged: (val) => setState(() => _biometric = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 5. SECURITY & KEYS Section
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('SECURITY & KEYS', style: TextStyle(color: sectionHeaderCol, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cardBorderCol),
                boxShadow: cardShadows,
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.lock_reset, color: Color(0xFF0066FF), size: 18),
                    ),
                    title: Text('Change Password', style: TextStyle(color: txtCol, fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subtxtCol),
                    onTap: _showChangePasswordModal,
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.key_rounded, color: Color(0xFF0066FF), size: 18),
                    ),
                    title: Text('View Recovery Key', style: TextStyle(color: txtCol, fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: Text(_showRecoveryKey ? 'Hide' : 'View', style: const TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.bold, fontSize: 13)),
                    onTap: () => setState(() => _showRecoveryKey = !_showRecoveryKey),
                  ),
                  if (_showRecoveryKey)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      color: isDark ? Colors.black.withOpacity(0.5) : const Color(0xFFFEF3C7),
                      child: Text(
                        widget.recoveryKey,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.amber : const Color(0xFFB45309),
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 6. Professional Destructive Logout Button
            InkWell(
              onTap: _handleLogout,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3F1D24) : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFFF43F5E).withOpacity(0.4) : const Color(0xFFFECDD3),
                    width: 1.2,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: Color(0xFFE11D48), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Logout / Clear Identity',
                      style: TextStyle(
                        color: Color(0xFFE11D48),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
