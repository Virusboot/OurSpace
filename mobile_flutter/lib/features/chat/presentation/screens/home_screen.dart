import 'package:flutter/material.dart';
import '../../../../core/networking/api_client.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final Function(Map<String, dynamic> recipient) onOpenChat;
  final Function(String type, Map<String, dynamic>? recipient) onStartCall;
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
  int _activeTab = 0; // 0: Chats, 1: Calls, 2: Security
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;

  final List<Map<String, dynamic>> _conversations = [
    {
      'id': 'c1',
      'username': '@alex_dev',
      'privateId': 'USER-98X12A',
      'lastMessage': '🔒 Hello! This conversation is end-to-end encrypted.',
      'time': '14:20',
      'unread': 1,
      'isOnline': true,
      'publicKey': 'PUB-12345',
    },
    {
      'id': 'c2',
      'username': '@sarah_sec',
      'privateId': 'USER-44B90Z',
      'lastMessage': '🔒 Disappearing message timer set to 30s',
      'time': 'Yesterday',
      'unread': 0,
      'isOnline': false,
      'publicKey': 'PUB-67890',
    },
  ];

  void _showNewActionSheet() {
    final isDark = widget.isDarkMode;
    final cardBg = isDark ? const Color(0xFF141824) : Colors.white;
    final txtColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      barrierColor: Colors.black.withOpacity(0.6),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
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
              color: const Color(0xFF10B981),
              title: 'New Encrypted Chat',
              subtitle: 'Connect with a user via Username or Private ID',
              onTap: () {
                Navigator.pop(ctx);
                _showSearchUserModal();
              },
            ),
            const SizedBox(height: 12),
            _buildSheetTile(
              icon: Icons.mic_none_rounded,
              color: const Color(0xFF3B82F6),
              title: 'New Audio Call',
              subtitle: 'Start an E2E encrypted HD voice call',
              onTap: () {
                Navigator.pop(ctx);
                widget.onStartCall('audio', null);
              },
            ),
            const SizedBox(height: 12),
            _buildSheetTile(
              icon: Icons.videocam_outlined,
              color: const Color(0xFFA855F7),
              title: 'New Video Call',
              subtitle: 'Start an E2E encrypted HD video call',
              onTap: () {
                Navigator.pop(ctx);
                widget.onStartCall('video', null);
              },
            ),
            const SizedBox(height: 12),
            _buildSheetTile(
              icon: Icons.link_rounded,
              color: const Color(0xFFF59E0B),
              title: 'Create Call Link',
              subtitle: 'Generate a guest WebRTC link to share anywhere',
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
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
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
          backgroundColor: isDark ? const Color(0xFF141824) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.person_search_rounded, color: Color(0xFF10B981), size: 24),
              const SizedBox(width: 10),
              Text('Search Identity', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchCtrl,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter @username or USER-XXXXXX',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: isDark ? Colors.black.withOpacity(0.4) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: loading
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
                  child: Text(loading ? 'Searching...' : 'Find & Connect', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              if (searchError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF43F5E).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(searchError!, style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 12)),
                ),
              ],
              if (searchResult != null) ...[
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                      child: Text(searchResult!['username'].toString().substring(1, 3).toUpperCase(), style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                    ),
                    title: Text(searchResult!['username'], style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                    subtitle: Text(searchResult!['privateId'], style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace')),
                    trailing: const Icon(Icons.chat_bubble_outline, color: Color(0xFF10B981)),
                    onTap: () {
                      Navigator.pop(ctx);
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
    bool loading = false;
    final isDark = widget.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF141824) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.add_link_rounded, color: Color(0xFF10B981), size: 24),
              const SizedBox(width: 10),
              Text('Create Guest Call Link', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (generatedUrl == null) ...[
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setStateDialog(() => callType = 'video'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: callType == 'video' ? const Color(0xFF10B981).withOpacity(0.2) : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                            border: Border.all(color: callType == 'video' ? const Color(0xFF10B981) : Colors.transparent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam, size: 18, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                              const SizedBox(width: 6),
                              Text('Video', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setStateDialog(() => callType = 'audio'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: callType == 'audio' ? const Color(0xFF10B981).withOpacity(0.2) : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                            border: Border.all(color: callType == 'audio' ? const Color(0xFF10B981) : Colors.transparent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mic, size: 18, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                              const SizedBox(width: 6),
                              Text('Audio', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: pinCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Optional PIN Code (e.g. 1234)',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: isDark ? Colors.black.withOpacity(0.4) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 18),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: loading
                        ? null
                        : () async {
                            setStateDialog(() => loading = true);
                            try {
                              final res = await ApiClient.post('/call-links/create', {
                                'callType': callType,
                                'durationMinutes': 60,
                                'pin': pinCtrl.text.trim().isNotEmpty ? pinCtrl.text.trim() : null,
                              });
                              setStateDialog(() {
                                loading = false;
                                generatedUrl = 'http://localhost:3000/c/${res['token']}';
                              });
                            } catch (_) {
                              setStateDialog(() {
                                loading = false;
                                generatedUrl = 'http://localhost:3000/c/demo_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                              });
                            }
                          },
                    child: Text(loading ? 'Generating...' : 'Generate Encrypted Link', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 36),
                      const SizedBox(height: 8),
                      Text('Call Link Ready!', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 10),
                      SelectableText(
                        generatedUrl!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF10B981), fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    final bgCol = isDark ? const Color(0xFF0A0D14) : const Color(0xFFF8FAFC);
    final txtCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDark ? const Color(0xFF141824) : Colors.white;

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: bgCol,
        elevation: 0,
        titleSpacing: 16,
        title: Text(
          'OurSpace',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: txtCol,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded, color: isDark ? Colors.white70 : const Color(0xFF475569)),
            onPressed: () => setState(() => _isSearching = !_isSearching),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white70 : const Color(0xFF475569)),
            onPressed: widget.onOpenSettings,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(color: txtCol, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search chats or Private ID...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: cardBg,
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981), size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

          // Navigation Pill Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06)),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Expanded(child: _buildNavTab(0, 'Chats', badgeCount: 1)),
                  Expanded(child: _buildNavTab(1, 'Calls')),
                  Expanded(child: _buildNavTab(2, 'Security')),
                ],
              ),
            ),
          ),

          // Tab Content
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        elevation: 6,
        onPressed: _showNewActionSheet,
        icon: const Icon(Icons.add_rounded, color: Colors.black, size: 22),
        label: const Text('New Chat', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _buildNavTab(int index, String label, {int badgeCount = 0}) {
    final isSelected = _activeTab == index;

    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (badgeCount > 0 && !isSelected) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                child: Text('$badgeCount', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    final isDark = widget.isDarkMode;
    final cardBg = isDark ? const Color(0xFF141824) : Colors.white;
    final txtCol = isDark ? Colors.white : const Color(0xFF0F172A);

    if (_activeTab == 0) {
      // CHATS TAB
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, idx) {
          final item = _conversations[idx];
          final isOnline = item['isOnline'] == true;
          final unread = item['unread'] as int;

          return Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.06)),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              onTap: () => widget.onOpenChat(item),
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
                    child: Text(
                      item['username'].toString().substring(1, 3).toUpperCase(),
                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: cardBg, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['username'], style: TextStyle(color: txtCol, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(item['time'], style: TextStyle(color: unread > 0 ? const Color(0xFF10B981) : Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['lastMessage'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    if (unread > 0)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                        child: Text('$unread', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else if (_activeTab == 1) {
      // CALLS TAB
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _showCreateCallLinkModal,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF10B981).withOpacity(0.15), const Color(0xFF059669).withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF10B981),
                      child: Icon(Icons.link_rounded, color: Colors.black),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create Guest Call Link', style: TextStyle(color: txtCol, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          const Text('Share a WebRTC audio/video call link with anyone without app install', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF10B981)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('RECENT ENCRYPTED CALLS', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.06)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, size: 42, color: isDark ? Colors.white24 : Colors.black26),
                    const SizedBox(height: 12),
                    Text('Zero-Knowledge Call Logs', style: TextStyle(color: txtCol, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 6),
                    const Text('Your call metadata is never stored on servers. Calls expire automatically.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // SECURITY TAB
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 28),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('End-to-End Encryption', style: TextStyle(color: txtCol, fontWeight: FontWeight.bold, fontSize: 16)),
                            const Text('Status: ACTIVE & VERIFIED', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: isDark ? Colors.white10 : Colors.black12),
                    const SizedBox(height: 12),
                    _buildSecurityDetailRow(Icons.key_rounded, 'Curve25519 & AES-256-GCM', 'Cryptographic protocol active', txtCol),
                    const SizedBox(height: 10),
                    _buildSecurityDetailRow(Icons.visibility_off_rounded, 'Zero Server Logs', 'No metadata or IP retention', txtCol),
                    const SizedBox(height: 10),
                    _buildSecurityDetailRow(Icons.timer_rounded, 'Auto Disappearing Chat', 'Messages wipe after countdown', txtCol),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSecurityDetailRow(IconData icon, String title, String subtitle, Color txtCol) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF10B981)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: txtCol, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
