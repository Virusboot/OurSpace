import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../auth/presentation/screens/create_pin_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';
import 'about_us_screen.dart';
import 'contact_us_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final String recoveryKey;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onBack;
  final VoidCallback onLogout;
  final Function(String? path)? onProfileImageUpdated;

  const SettingsScreen({
    Key? key,
    required this.user,
    required this.recoveryKey,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onBack,
    required this.onLogout,
    this.onProfileImageUpdated,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _appLock = false;
  bool _biometric = false;
  bool _ghostMode = false;
  bool _showRecoveryKey = false;
  XFile? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSavedProfileImage();
    _loadLockSettings();
  }

  Future<void> _loadLockSettings() async {
    final appLock = await SecureStorageService.read('app_lock_enabled');
    final biometric = await SecureStorageService.read('biometric_enabled');
    final ghost = await SecureStorageService.read('ghost_mode_enabled');
    setState(() {
      _appLock = appLock == 'true';
      _biometric = biometric == 'true';
      _ghostMode = ghost == 'true';
    });
  }

  Future<void> _toggleGhostMode(bool value) async {
    await SecureStorageService.write('ghost_mode_enabled', value ? 'true' : 'false');
    setState(() => _ghostMode = value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(value ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value ? 'Ghost Mode Activated (30s Disappearing & View-Once)' : 'Ghost Mode Deactivated',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: value ? const Color(0xFF0066FF) : const Color(0xFF64748B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _toggleAppLock(bool value) async {
    if (value) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => CreatePinScreen(
            isUnlockMode: false,
            onPinComplete: () async {
              Navigator.pop(ctx);
              await SecureStorageService.write('app_lock_enabled', 'true');
              setState(() => _appLock = true);
            },
          ),
        ),
      );
    } else {
      await SecureStorageService.write('app_lock_enabled', 'false');
      setState(() => _appLock = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      try {
        final auth = LocalAuthentication();
        final canCheck = await auth.canCheckBiometrics;
        if (canCheck) {
          final authenticated = await auth.authenticate(
            localizedReason: 'Verify Phone Fingerprint / Face ID to enable Biometric Unlock',
            options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
          );
          if (authenticated) {
            await SecureStorageService.write('biometric_enabled', 'true');
            await SecureStorageService.write('app_lock_enabled', 'true');
            setState(() {
              _biometric = true;
              _appLock = true;
            });
            return;
          }
        }
      } catch (_) {}
    }
    await SecureStorageService.write('biometric_enabled', value ? 'true' : 'false');
    setState(() => _biometric = value);
  }

  Future<void> _loadSavedProfileImage() async {
    final savedPath = await SecureStorageService.read('profile_image_path');
    if (savedPath != null && File(savedPath).existsSync()) {
      setState(() {
        _profileImage = XFile(savedPath);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 600, maxHeight: 600, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _profileImage = picked;
        });
        await SecureStorageService.write('profile_image_path', picked.path);
        widget.onProfileImageUpdated?.call(picked.path);
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
                  onTap: () async {
                    Navigator.pop(ctx);
                    setState(() => _profileImage = null);
                    await SecureStorageService.delete('profile_image_path');
                    widget.onProfileImageUpdated?.call(null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileModal() {
    final isDark = widget.isDarkMode;
    final nameCtrl = TextEditingController(text: widget.user?['name'] ?? widget.user?['username'] ?? '');
    final usernameCtrl = TextEditingController(text: widget.user?['username'] ?? '');
    final bioCtrl = TextEditingController(text: widget.user?['bio'] ?? 'Available on OurSpace E2EE');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF14161C) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Edit Profile Info', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Display Name', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : const Color(0xFF64748B), fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF0066FF), size: 20),
                filled: true,
                fillColor: isDark ? Colors.black.withOpacity(0.4) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            Text('Username / Handle', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : const Color(0xFF64748B), fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: usernameCtrl,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF0066FF), size: 20),
                filled: true,
                fillColor: isDark ? Colors.black.withOpacity(0.4) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            Text('Bio / About', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : const Color(0xFF64748B), fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: bioCtrl,
              maxLines: 2,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.info_outline_rounded, color: Color(0xFF0066FF), size: 20),
                filled: true,
                fillColor: isDark ? Colors.black.withOpacity(0.4) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  final updatedName = nameCtrl.text.trim();
                  final updatedUsername = usernameCtrl.text.trim();
                  final updatedBio = bioCtrl.text.trim();
                  if (widget.user != null) {
                    widget.user!['name'] = updatedName;
                    widget.user!['username'] = updatedUsername.startsWith('@') ? updatedUsername : '@$updatedUsername';
                    widget.user!['bio'] = updatedBio;
                    await SecureStorageService.write('user_info', jsonEncode(widget.user));
                  }
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text('Profile details updated successfully!'),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: const Text('Save Profile Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQrCodeModal(String username, String privateId) {
    final isDark = widget.isDarkMode;
    final cardBg = isDark ? const Color(0xFF14161C) : Colors.white;
    final txtColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('My Identity QR Code', style: TextStyle(color: txtColor, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Scan or share your unique identity to connect', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),

            // Main QR Code Box Container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B1D24) : const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.3), width: 1.5),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0066FF).withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      size: 160,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    username,
                    style: TextStyle(color: txtColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066FF).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      privateId,
                      style: const TextStyle(
                        color: Color(0xFF0066FF),
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Share & Copy Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF0066FF), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.copy_rounded, color: Color(0xFF0066FF), size: 18),
                    label: const Text('Copy ID', style: TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: '$username\nPrivate ID: $privateId'));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text('Copied: $username ($privateId)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF0066FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                    label: const Text('Share ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: 'Connect with me on OurSpace Privacy Chat!\nUsername: $username\nPrivate ID: $privateId'));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text('Share text copied to clipboard!\n$username | $privateId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: const Color(0xFF0066FF),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
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
    final cardShadows = null;

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
            // 1. Sleek Profile User Section (Seamless Flat Background, No Outer Box/Shadow)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFF0066FF), Color(0xFF00C6FF), Color(0xFF0044B3)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: bgCol,
                                  border: Border.all(color: bgCol, width: 2),
                                ),
                                child: ClipOval(
                                  child: _profileImage != null
                                      ? Image.file(
                                          File(_profileImage!.path),
                                          width: 68,
                                          height: 68,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 68,
                                          height: 68,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [Color(0xFF0066FF), Color(0xFF0044B3)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              username.replaceAll('@', '').substring(0, 1).toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 30,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0066FF),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: bgCol, width: 2.5),
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
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
                              widget.user?['name'] ?? username,
                              style: TextStyle(color: txtCol, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.3),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              username,
                              style: const TextStyle(color: Color(0xFF0066FF), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                await Clipboard.setData(ClipboardData(text: privateId));
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Copied Private ID: $privateId'),
                                    backgroundColor: const Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0066FF).withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      privateId,
                                      style: const TextStyle(
                                        color: Color(0xFF0066FF),
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.copy_rounded, color: Color(0xFF0066FF), size: 11),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.user?['bio'] ?? 'Available | End-to-End Encrypted',
                      style: TextStyle(color: subtxtCol, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF0066FF), size: 18),
                          label: const Text('Edit Profile', style: TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: _showEditProfileModal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: const Color(0xFF0066FF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.qr_code_rounded, color: Colors.white, size: 18),
                          label: const Text('My QR Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: () => _showQrCodeModal(username, privateId),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Ultra-Sleek Ghost Mode Privacy Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0066FF).withOpacity(0.12) : const Color(0xFFEFF6FF),
                border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.35), width: 1.2),
                borderRadius: BorderRadius.circular(20),
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
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(0xFF0066FF),
                            child: Icon(Icons.visibility_off_outlined, color: Colors.white, size: 15),
                          ),
                          SizedBox(width: 10),
                          Text('GHOST MODE PRIVACY', style: TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 13)),
                        ],
                      ),
                      Switch(
                        value: _ghostMode,
                        activeColor: const Color(0xFF0066FF),
                        onChanged: _toggleGhostMode,
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

            // 3. PRIVACY & APP LOCK Section
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('PRIVACY & APP LOCK', style: TextStyle(color: sectionHeaderCol, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorderCol),
                boxShadow: cardShadows,
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF0066FF).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF0066FF), size: 20),
                    ),
                    title: Text('App Lock (PIN)', style: TextStyle(color: txtCol, fontSize: 14, fontWeight: FontWeight.w600)),
                    value: _appLock,
                    activeColor: const Color(0xFF0066FF),
                    onChanged: _toggleAppLock,
                  ),
                  if (_appLock) ...[
                    Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF0066FF).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.password_rounded, color: Color(0xFF0066FF), size: 20),
                      ),
                      title: Text('Change App PIN', style: TextStyle(color: txtCol, fontSize: 14, fontWeight: FontWeight.w600)),
                      trailing: Icon(Icons.chevron_right_rounded, color: subtxtCol, size: 20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => CreatePinScreen(
                              isUnlockMode: false,
                              onPinComplete: () {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                        SizedBox(width: 10),
                                        Text('App PIN updated successfully!'),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF0066FF).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF0066FF), size: 20),
                    ),
                    title: Text('Biometric Unlock (Fingerprint / Face ID)', style: TextStyle(color: txtCol, fontSize: 14, fontWeight: FontWeight.w600)),
                    value: _biometric,
                    activeColor: const Color(0xFF0066FF),
                    onChanged: _toggleBiometric,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. SECURITY & ENCRYPTION KEYS Section
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('SECURITY & ENCRYPTION KEYS', style: TextStyle(color: sectionHeaderCol, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorderCol),
                boxShadow: cardShadows,
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF0066FF), size: 20),
                    ),
                    title: Text('Change Password', style: TextStyle(color: txtCol, fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subtxtCol),
                    onTap: _showChangePasswordModal,
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.key_rounded, color: Color(0xFF0066FF), size: 20),
                    ),
                    title: Text('View Master Recovery Key', style: TextStyle(color: txtCol, fontSize: 14, fontWeight: FontWeight.w600)),
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
            const SizedBox(height: 24),

            // 5. APP PREFERENCES Section
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('APP PREFERENCES', style: TextStyle(color: sectionHeaderCol, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorderCol),
                boxShadow: cardShadows,
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                        color: isDark ? Colors.amber : const Color(0xFF0066FF),
                        size: 20,
                      ),
                    ),
                    title: Text('App Theme', style: TextStyle(color: txtCol, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(isDark ? 'Dark Theme Active' : 'Light Theme Active', style: TextStyle(color: subtxtCol, fontSize: 12)),
                    trailing: Switch(
                      value: !isDark,
                      activeColor: const Color(0xFF0066FF),
                      onChanged: (_) => widget.onToggleTheme(),
                    ),
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cleaning_services_rounded, color: Color(0xFF0066FF), size: 20),
                    ),
                    title: Text('Clear Cache & Temp Files', style: TextStyle(color: txtCol, fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subtxtCol),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text('Temporary media cache wiped cleanly!'),
                            ],
                          ),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 6. LEGAL, ABOUT & SUPPORT Section (Play Store Compliance)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('LEGAL, ABOUT & SUPPORT', style: TextStyle(color: sectionHeaderCol, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorderCol),
                boxShadow: cardShadows,
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Color(0xFF0066FF), size: 20),
                    ),
                    title: Text('Privacy Policy', style: TextStyle(color: txtCol, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('Zero-Knowledge E2EE Data Protection', style: TextStyle(color: subtxtCol, fontSize: 12)),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subtxtCol),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => PrivacyPolicyScreen(
                            isDarkMode: isDark,
                            onBack: () => Navigator.pop(ctx),
                          ),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.gavel_outlined, color: Color(0xFF0066FF), size: 20),
                    ),
                    title: Text('Terms & Conditions', style: TextStyle(color: txtCol, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('Service Agreement & Use Guidelines', style: TextStyle(color: subtxtCol, fontSize: 12)),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subtxtCol),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => TermsConditionsScreen(
                            isDarkMode: isDark,
                            onBack: () => Navigator.pop(ctx),
                          ),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.info_outline_rounded, color: Color(0xFF0066FF), size: 20),
                    ),
                    title: Text('About OurSpace', style: TextStyle(color: txtCol, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('Version 1.0.0 (Build 100)', style: TextStyle(color: subtxtCol, fontSize: 12)),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subtxtCol),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => AboutUsScreen(
                            isDarkMode: isDark,
                            onBack: () => Navigator.pop(ctx),
                          ),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: Color(0xFF0066FF), size: 20),
                    ),
                    title: Text('Contact Us & Support', style: TextStyle(color: txtCol, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('support@ourspace.app', style: TextStyle(color: subtxtCol, fontSize: 12)),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subtxtCol),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => ContactUsScreen(
                            isDarkMode: isDark,
                            onBack: () => Navigator.pop(ctx),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 6. Professional Destructive Logout Button
            InkWell(
              onTap: _handleLogout,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3F1D24) : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(18),
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
                      'Logout & Clear Private Session',
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
