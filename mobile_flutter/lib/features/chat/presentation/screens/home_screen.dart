import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/networking/websocket_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/widgets/app_gradient_button.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final Function(Map<String, dynamic> recipient) onOpenChat;
  final Function(String type, Map<String, dynamic>? recipient, {String? callId}) onStartCall;
  final VoidCallback onOpenSettings;

  const HomeScreen({
    Key? key,
    required this.user,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onOpenChat,
    required this.onStartCall,
    required this.onOpenSettings,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeTab = 0; // 0: Chat, 1: Calls, 2: Status, 3: Settings
  final TextEditingController _searchCtrl = TextEditingController();
  final List<Map<String, dynamic>> _conversations = [];
  StreamSubscription? _wsSubscription;
  List<Map<String, dynamic>> _onlineUsers = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _loadRecentChats();
    _fetchOnlineUsers();
    _wsSubscription = WebSocketClient().stream.listen((event) {
      if (event['type'] == 'online_users_update') {
        final usersList = event['users'] as List?;
        if (usersList != null && mounted) {
          setState(() {
            _onlineUsers = List<Map<String, dynamic>>.from(
              usersList.map((u) => Map<String, dynamic>.from(u))
            );
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchOnlineUsers() async {
    try {
      final res = await ApiClient.get('/users/online');
      if (res is List && mounted) {
        setState(() {
          _onlineUsers = (res as List).map((u) => Map<String, dynamic>.from(u as Map)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadRecentChats() async {
    final data = await SecureStorageService.read('recent_chats');
    if (data != null && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          setState(() {
            _conversations.clear();
            _conversations.addAll(List<Map<String, dynamic>>.from(decoded));
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _saveRecentChat(Map<String, dynamic> peer) async {
    // Skip saving guest users — they have no real account on the platform
    final peerId = peer['id']?.toString() ?? '';
    final privateId = peer['privateId']?.toString() ?? '';
    if (peerId.startsWith('guest_') || privateId.isEmpty) return;

    final data = await SecureStorageService.read('recent_chats');
    List<Map<String, dynamic>> list = [];
    if (data != null && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          list = List<Map<String, dynamic>>.from(decoded);
        }
      } catch (_) {}
    }
    list.removeWhere((item) => item['username'] == peer['username']);
    list.insert(0, {
      'id': peer['id'] ?? 'peer_${DateTime.now().millisecondsSinceEpoch}',
      'username': peer['username'],
      'privateId': peer['privateId'] ?? '',
      'unread': 0,
      'lastMessage': 'Click to open secure chat',
      'time': 'Just now',
    });
    await SecureStorageService.write('recent_chats', jsonEncode(list));
    _loadRecentChats();
  }



  void _showNewActionSheet() {
    final isDark = widget.isDarkMode;
    final cardBg = isDark ? const Color(0xFF14161C) : Colors.white;
    final txtColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: cardBg,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Start Secure Action', style: TextStyle(color: txtColor, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Select an encrypted action to perform', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),

            _buildSheetTile(
              icon: Icons.chat_bubble_outline_rounded,
              color: const Color(0xFF7B2FBE),
              title: 'New Encrypted Chat',
              subtitle: 'Connect with a user via unique Username or Private ID',
              onTap: () {
                Navigator.pop(ctx);
                _showSearchUserModal();
              },
            ),
            const SizedBox(height: 12),
            _buildSheetTile(
              icon: Icons.link_rounded,
              color: const Color(0xFF7B2FBE),
              title: 'Create Call Link',
              subtitle: 'Generate a guest WebRTC call link to share anywhere',
              onTap: () {
                Navigator.pop(ctx);
                _showCreateCallLinkModal();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = widget.isDarkMode;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showSearchUserModal() {
    final searchCtrl = TextEditingController();
    Map<String, dynamic>? searchResult;
    String? searchError;
    bool loading = false;
    final isDark = widget.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF14161C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.person_search_rounded, color: Color(0xFF7B2FBE), size: 24),
              const SizedBox(width: 10),
              Text('Find Someone', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchCtrl,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter name or @username (e.g. @rahul_k)',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              AppGradientButton(
                label: loading ? 'Searching...' : 'Find & Connect',
                onTap: loading
                    ? null
                    : () async {
                        setStateDialog(() {
                          loading = true;
                          searchError = null;
                          searchResult = null;
                        });
                        try {
                          final query = searchCtrl.text.trim();
                          final res = await ApiClient.get('/users/lookup?query=${Uri.encodeComponent(query)}');
                          setStateDialog(() {
                            loading = false;
                            searchResult = res;
                          });
                        } catch (e) {
                          setStateDialog(() {
                            loading = false;
                            searchError = 'Identity not found';
                          });
                        }
                      },
                isLoading: loading,
                height: 46,
              ),
              if (searchError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF43F5E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(searchError!, style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 12)),
                ),
              ],
              if (searchResult != null) ...[
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF7B2FBE).withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF7B2FBE).withValues(alpha: 0.2),
                      child: Text(searchResult!['username'].toString().substring(0, 2).toUpperCase(), style: const TextStyle(color: Color(0xFF7B2FBE), fontWeight: FontWeight.bold)),
                    ),
                    title: Text(searchResult!['username'], style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                    subtitle: Text(searchResult!['privateId'], style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace')),
                    trailing: const Icon(Icons.chat_bubble_outline, color: Color(0xFF7B2FBE)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _saveRecentChat(searchResult!);
                      widget.onOpenChat(searchResult!);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateCallLinkModal() {
    String callType = 'video';
    final pinCtrl = TextEditingController();
    String? generatedUrl;
    String? generatedCallId;
    bool loading = false;
    final isDark = widget.isDarkMode;
    final bg = isDark ? const Color(0xFF14161C) : Colors.white;
    final txtPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final txtSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF1E2028) : const Color(0xFFF1F5F9);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B2FBE).withValues(alpha: 0.18),
                  blurRadius: 40,
                  spreadRadius: 2,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── GRADIENT HEADER ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7B2FBE), Color(0xFFB5177A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_link_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create Call Link',
                            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                          ),
                          Text(
                            'Share with anyone — no account needed',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── CONTENT ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (generatedUrl == null) ...[ // — CREATION FORM —
                        // Call type selector
                        Row(
                          children: [
                            _buildCallTypeChip(
                              icon: Icons.videocam_rounded,
                              label: 'Video Call',
                              selected: callType == 'video',
                              isDark: isDark,
                              onTap: () => setStateDialog(() => callType = 'video'),
                            ),
                            const SizedBox(width: 10),
                            _buildCallTypeChip(
                              icon: Icons.mic_rounded,
                              label: 'Audio Call',
                              selected: callType == 'audio',
                              isDark: isDark,
                              onTap: () => setStateDialog(() => callType = 'audio'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Optional PIN field
                        Container(
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextField(
                            controller: pinCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            style: TextStyle(color: txtPrimary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 6),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'Optional PIN (4 digits)',
                              hintStyle: TextStyle(color: txtSub, fontSize: 13, letterSpacing: 0, fontWeight: FontWeight.normal),
                              filled: false,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              prefixIcon: Icon(Icons.lock_outline_rounded, color: const Color(0xFF7B2FBE), size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        AppGradientButton(
                          label: 'Generate Link',
                          onTap: loading ? null : () async {
                            setStateDialog(() => loading = true);
                            try {
                              final res = await ApiClient.post('/call-links/create', {
                                'callType': callType,
                                'durationMinutes': 60,
                                'pin': pinCtrl.text.trim().isNotEmpty ? pinCtrl.text.trim() : null,
                              });
                              setStateDialog(() {
                                loading = false;
                                generatedUrl = '${ApiClient.webBaseUrl}/c/${res['token']}';
                                generatedCallId = res['callId'];
                              });
                            } catch (_) {
                              setStateDialog(() {
                                loading = false;
                                generatedUrl = '${ApiClient.webBaseUrl}/c/demo_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                                generatedCallId = 'demo_${DateTime.now().millisecondsSinceEpoch}';
                              });
                            }
                          },
                          isLoading: loading,
                          height: 50,
                          icon: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                        ),

                      ] else ...[ // — LINK READY STATE —
                        // Success card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF7B2FBE).withValues(alpha: 0.08),
                                const Color(0xFFE91E8C).withValues(alpha: 0.06),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF7B2FBE).withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: [
                              // Success icon
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF7B2FBE), Color(0xFFE91E8C)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7B2FBE).withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.check_rounded, color: Colors.white, size: 26),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Link is Ready to Share!',
                                style: TextStyle(color: txtPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Valid for 60 minutes',
                                style: TextStyle(color: txtSub, fontSize: 11),
                              ),
                              const SizedBox(height: 14),

                              // URL box
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F1117) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF7B2FBE).withValues(alpha: 0.25)),
                                ),
                                child: SelectableText(
                                  generatedUrl!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF7B2FBE),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Copy button
                              AppGradientButton(
                                height: 44,
                                borderRadius: 12,
                                icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                                label: 'Copy Link',
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: generatedUrl!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                                          SizedBox(width: 8),
                                          Text('Link copied! Share it anywhere.'),
                                        ],
                                      ),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: const Color(0xFF7B2FBE),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      margin: const EdgeInsets.all(16),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        if (generatedUrl != null) ...[ 
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                  child: Text('Close', style: TextStyle(color: txtSub, fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: AppGradientButton(
                                  height: 44,
                                  borderRadius: 12,
                                  icon: const Icon(Icons.call_rounded, size: 16, color: Colors.white),
                                  label: 'Start & Join',
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    widget.onStartCall(callType, {'id': 'guest', 'username': '@waiting_for_join'}, callId: generatedCallId);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallTypeChip({
    required IconData icon,
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF7B2FBE), Color(0xFFB5177A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected
                ? null
                : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.transparent : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF7B2FBE).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: selected ? Colors.white : (isDark ? Colors.white60 : const Color(0xFF64748B))),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final filterQuery = _searchCtrl.text.trim().toLowerCase();
    final filteredConvs = _conversations.where((c) {
      final name = c['username'].toString().toLowerCase();
      final handle = (c['handle'] ?? '').toString().toLowerCase();
      final pid = (c['privateId'] ?? '').toString().toLowerCase();
      return name.contains(filterQuery) || handle.contains(filterQuery) || pid.contains(filterQuery);
    }).toList();

    final scaffoldBg = isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC);
    final headerTxt = isDark ? Colors.white : const Color(0xFF0F172A);
    final searchBg = isDark ? const Color(0xFF191B20) : const Color(0xFFEDF2F7);
    final searchTxt = isDark ? Colors.white : const Color(0xFF0F172A);
    final searchHint = isDark ? const Color(0xFF6C727F) : const Color(0xFF94A3B8);
    final cardBg = isDark ? const Color(0xFF121317) : const Color(0xFFFFFFFF);
    final itemSelectedBg = isDark ? const Color(0xFF1B1D23) : const Color(0xFFF1F5F9);
    final itemTxt = isDark ? Colors.white : const Color(0xFF0F172A);
    final itemSubtxt = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final avatarBg = isDark ? const Color(0xFF26282F) : const Color(0xFFE2E8F0);
    final avatarTxt = isDark ? Colors.white : const Color(0xFF0F172A);
    final dockPillBg = isDark ? const Color(0xFF1A1C24) : const Color(0xFFFFFFFF);
    final dockBorder = isDark ? Colors.white.withValues(alpha: 0.14) : const Color(0xFFE2E8F0);
    final dockShadow = isDark
        ? [
            BoxShadow(
              color: const Color(0xFF7B2FBE).withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ];

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // TOP HEADER WITH TITLE
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/app_logo.png',
                        height: 32,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _activeTab == 0 ? 'Chat' : (_activeTab == 1 ? 'Calls' : 'Voice Notes'),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: headerTxt,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(21),
                    child: InkWell(
                      onTap: _showNewActionSheet,
                      borderRadius: BorderRadius.circular(21),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B2FBE).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.add_rounded,
                            color: Color(0xFF7B2FBE),
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // SEARCH BAR ("Type your search...")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: searchBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(color: searchTxt, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search chats, calls & contacts...',
                    hintStyle: TextStyle(color: searchHint, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: searchHint, size: 22),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // CHAT LIST SECTION CONTAINER
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: _activeTab == 0
                          ? (() {
                              final filteredOnline = _onlineUsers.where((u) => u['id'] != widget.user?['id'] && u['username'] != widget.user?['username']).toList();
                              return Column(
                                children: [
                                  if (filteredOnline.isNotEmpty)
                                    _buildOnlineUsersSection(filteredOnline),
                                  Expanded(
                                    child: filteredConvs.isEmpty
                                        ? Center(
                                            child: SingleChildScrollView(
                                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(20),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF7B2FBE).withValues(alpha: 0.12),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(color: const Color(0xFF7B2FBE).withValues(alpha: 0.3), width: 1.5),
                                                    ),
                                                    child: const Icon(Icons.shield_outlined, size: 48, color: Color(0xFF7B2FBE)),
                                                  ),
                                                  const SizedBox(height: 20),
                                                  Text(
                                                    filterQuery.isNotEmpty ? 'No chats matching "$filterQuery"' : 'No Active Conversations',
                                                    style: TextStyle(color: itemTxt, fontSize: 18, fontWeight: FontWeight.bold),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    filterQuery.isNotEmpty
                                                        ? 'Try searching with a different name, handle, or Private ID.'
                                                        : 'Your chats are zero-knowledge and end-to-end encrypted. Tap below to start a new secure chat.',
                                                    style: TextStyle(color: itemSubtxt, fontSize: 13, height: 1.5),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  if (filterQuery.isEmpty) ...[
                                                    const SizedBox(height: 24),
                                                    AppGradientButton(
                                                      label: 'Start New Secure Chat',
                                                      onTap: _showNewActionSheet,
                                                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                                                      height: 48,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                                            itemCount: filteredConvs.length,
                                            itemBuilder: (ctx, idx) {
                                              final item = filteredConvs[idx];
                                              final unread = item['unread'] as int;
                                              final isSelected = idx == 0;

                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                decoration: BoxDecoration(
                                                  color: isSelected ? itemSelectedBg : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: ListTile(
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                                  onTap: () => widget.onOpenChat(item),
                                                  leading: CircleAvatar(
                                                    radius: 25,
                                                    backgroundColor: avatarBg,
                                                    child: (item['profileImage'] != null && File(item['profileImage']).existsSync())
                                                        ? ClipRRect(
                                                            borderRadius: BorderRadius.circular(25),
                                                            child: Image.file(
                                                              File(item['profileImage']),
                                                              width: 50,
                                                              height: 50,
                                                              fit: BoxFit.cover,
                                                            ),
                                                          )
                                                        : Text(
                                                            item['username'].toString().substring(0, 1).toUpperCase(),
                                                            style: TextStyle(color: avatarTxt, fontWeight: FontWeight.bold, fontSize: 17),
                                                          ),
                                                  ),
                                                  title: Text(
                                                    item['username'],
                                                    style: TextStyle(
                                                      color: itemTxt,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  subtitle: Padding(
                                                    padding: const EdgeInsets.only(top: 4),
                                                    child: Text(
                                                      item['lastMessage'],
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: itemSubtxt,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                  trailing: unread > 0
                                                      ? Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF7B2FBE),
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: Text(
                                                            '$unread',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        )
                                                      : null,
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              );
                            })()
                          : _buildSecondaryTabContent(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ULTRA PREMIUM FLOATING GLASSMORPHIC BOTTOM DOCK
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: cardBg, // Seamless single background matching body
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: dockPillBg,
              borderRadius: BorderRadius.circular(40), // Full round capsule
              border: Border.all(
                color: dockBorder,
                width: 1.2,
              ),
              boxShadow: dockShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Chat Tab
                _buildNavItem(
                  index: 0,
                  icon: _activeTab == 0 ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
                  label: 'Chat',
                  isSelected: _activeTab == 0,
                  onTap: () => setState(() => _activeTab = 0),
                ),
                // 2. Calls Tab
                _buildNavItem(
                  index: 1,
                  icon: _activeTab == 1 ? Icons.call_rounded : Icons.call_outlined,
                  label: 'Calls',
                  isSelected: _activeTab == 1,
                  onTap: () => setState(() => _activeTab = 1),
                ),

                // 4. Voice Notes Tab (Coming Soon)
                _buildNavItem(
                  index: 2,
                  icon: Icons.mic_none_rounded,
                  label: 'Voice',
                  isSelected: _activeTab == 2,
                  onTap: () => setState(() => _activeTab = 2),
                ),
                // 5. Settings Tab
                _buildNavItem(
                  index: 3,
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  isSelected: false,
                  onTap: widget.onOpenSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = widget.isDarkMode;
    final unselectedNav = isDark ? const Color(0xFF8E95A5) : const Color(0xFF64748B);
    final selectedText = isDark ? Colors.white : const Color(0xFF0F172A);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF7B2FBE) : unselectedNav,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedText : unselectedNav,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryTabContent() {
    final isDark = widget.isDarkMode;
    final itemBg = isDark ? const Color(0xFF1B1D23) : const Color(0xFFF1F5F9);
    final txtColor = isDark ? Colors.white : const Color(0xFF0F172A);

    if (_activeTab == 1) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            InkWell(
              onTap: _showCreateCallLinkModal,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: itemBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF7B2FBE),
                      child: Icon(Icons.link_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create Guest Call Link', style: TextStyle(color: txtColor, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          const Text('Share an audio/video call link with anyone', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF7B2FBE)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFF7B2FBE).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF7B2FBE).withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.mic_none_rounded, color: Color(0xFF7B2FBE), size: 38),
              ),
              const SizedBox(height: 18),
              Text(
                'Voice Notes Coming Soon',
                style: TextStyle(color: txtColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Encrypted voice memos and instant audio notes feature will be available in the upcoming update.',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B2FBE).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF7B2FBE).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hourglass_top_rounded, color: Color(0xFF7B2FBE), size: 14),
                    SizedBox(width: 6),
                    Text('IN DEVELOPMENT', style: TextStyle(color: Color(0xFF7B2FBE), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildOnlineUsersSection(List<Map<String, dynamic>> users) {
    final isDark = widget.isDarkMode;
    final titleColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final avatarBg = isDark ? const Color(0xFF26282F) : const Color(0xFFE2E8F0);
    final avatarTxt = isDark ? Colors.white : const Color(0xFF0F172A);
    final labelColor = isDark ? Colors.white60 : const Color(0xFF0F172A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981), // active green
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Active Now (${users.length})',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 84,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: users.length,
            itemBuilder: (ctx, idx) {
              final user = users[idx];
              final displayName = user['username'].toString().startsWith('@') 
                  ? user['username'].toString().substring(1) 
                  : user['username'].toString();
              return GestureDetector(
                onTap: () => widget.onOpenChat(user),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: avatarBg,
                            child: Text(
                              displayName.substring(0, 1).toUpperCase(),
                              style: TextStyle(color: avatarTxt, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? const Color(0xFF121317) : Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 64,
                        child: Text(
                          '@$displayName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
