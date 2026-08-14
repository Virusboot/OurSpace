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
  int _activeTab = 0; // 0: Chat, 1: Calls, 2: Status, 3: Settings
  final TextEditingController _searchCtrl = TextEditingController();


  final List<Map<String, dynamic>> _conversations = [
    {
      'id': 'c1',
      'username': 'Salina Desuza',
      'handle': '@salina_desuza',
      'privateId': 'USER-98X12A',
      'lastMessage': 'Hi! I am waiting for you',
      'time': '5:22',
      'unread': 5,
      'isOnline': true,
      'publicKey': 'PUB-12345',
    },
    {
      'id': 'c2',
      'username': 'James Watemore',
      'handle': '@james_w',
      'privateId': 'USER-44B90Z',
      'lastMessage': 'Ok great!👍👍',
      'time': '12:45',
      'unread': 0,
      'isOnline': false,
      'publicKey': 'PUB-67890',
    },
    {
      'id': 'c3',
      'username': 'Julia Smith',
      'handle': '@julia_s',
      'privateId': 'USER-77C11Q',
      'lastMessage': 'It is gona be fun 🤨😁✌️',
      'time': 'Yesterday',
      'unread': 2,
      'isOnline': true,
      'publicKey': 'PUB-11223',
    },
    {
      'id': 'c4',
      'username': 'Alex Jazz',
      'handle': '@alex_j',
      'privateId': 'USER-88D99M',
      'lastMessage': 'Yup!',
      'time': 'Mon',
      'unread': 0,
      'isOnline': false,
      'publicKey': 'PUB-44556',
    },
  ];

  void _showNewActionSheet() {
    final isDark = widget.isDarkMode;
    final cardBg = isDark ? const Color(0xFF14161C) : Colors.white;
    final txtColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      barrierColor: Colors.black.withOpacity(0.7),
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
              color: const Color(0xFF0066FF),
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
              color: const Color(0xFF0066FF),
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
              color: const Color(0xFF0066FF),
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
              color: const Color(0xFF0066FF),
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
          backgroundColor: isDark ? const Color(0xFF14161C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.person_search_rounded, color: Color(0xFF0066FF), size: 24),
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
                    backgroundColor: const Color(0xFF0066FF),
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
                  child: Text(loading ? 'Searching...' : 'Find & Connect', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.3)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0066FF).withOpacity(0.2),
                      child: Text(searchResult!['username'].toString().substring(0, 2).toUpperCase(), style: const TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.bold)),
                    ),
                    title: Text(searchResult!['username'], style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                    subtitle: Text(searchResult!['privateId'], style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace')),
                    trailing: const Icon(Icons.chat_bubble_outline, color: Color(0xFF0066FF)),
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
          backgroundColor: isDark ? const Color(0xFF14161C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.add_link_rounded, color: Color(0xFF0066FF), size: 24),
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
                            color: callType == 'video' ? const Color(0xFF0066FF).withOpacity(0.2) : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                            border: Border.all(color: callType == 'video' ? const Color(0xFF0066FF) : Colors.transparent),
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
                            color: callType == 'audio' ? const Color(0xFF0066FF).withOpacity(0.2) : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                            border: Border.all(color: callType == 'audio' ? const Color(0xFF0066FF) : Colors.transparent),
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
                      backgroundColor: const Color(0xFF0066FF),
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
                    child: Text(loading ? 'Generating...' : 'Generate Encrypted Link', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withOpacity(0.1),
                    border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF0066FF), size: 36),
                      const SizedBox(height: 8),
                      Text('Call Link Ready!', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 10),
                      SelectableText(
                        generatedUrl!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF0066FF), fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold),
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
    final scaffoldBg = isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC);
    final headerTxt = isDark ? Colors.white : const Color(0xFF0F172A);
    final searchBg = isDark ? const Color(0xFF191B20) : const Color(0xFFEDF2F7);
    final searchTxt = isDark ? Colors.white : const Color(0xFF0F172A);
    final searchHint = isDark ? const Color(0xFF6C727F) : const Color(0xFF94A3B8);
    final cardBg = isDark ? const Color(0xFF121317) : const Color(0xFFFFFFFF);
    final handleColor = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12);
    final itemSelectedBg = isDark ? const Color(0xFF1B1D23) : const Color(0xFFF1F5F9);
    final itemTxt = isDark ? Colors.white : const Color(0xFF0F172A);
    final itemSubtxt = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final avatarBg = isDark ? const Color(0xFF26282F) : const Color(0xFFE2E8F0);
    final avatarTxt = isDark ? Colors.white : const Color(0xFF0F172A);
    final dockPillBg = isDark ? const Color(0xFF1A1C24) : const Color(0xFFFFFFFF);
    final dockBorder = isDark ? Colors.white.withOpacity(0.14) : const Color(0xFFE2E8F0);
    final dockShadow = isDark
        ? [
            BoxShadow(
              color: const Color(0xFF0066FF).withOpacity(0.20),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
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
                  Text(
                    _activeTab == 0 ? 'Chat' : (_activeTab == 1 ? 'Calls' : 'Voice Notes'),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: headerTxt,
                      letterSpacing: -0.4,
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
                    hintText: 'Type your search...',
                    hintStyle: TextStyle(color: searchHint, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: searchHint, size: 22),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

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
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: handleColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _activeTab == 0
                          ? ListView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                              itemCount: _conversations.length,
                              itemBuilder: (ctx, idx) {
                                final item = _conversations[idx];
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
                                      child: Text(
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
                                              color: const Color(0xFF0066FF),
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
                            )
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
      bottomNavigationBar: Container(
        color: cardBg, // Seamless single background matching body
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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
              // 3. Glowing Gradient Center FAB Button (+)
              GestureDetector(
                onTap: _showNewActionSheet,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0066FF), Color(0xFF0052CC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0066FF).withOpacity(0.45),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ),
              // 4. Voice Notes Tab (Coming Soon)
              _buildNavItem(
                index: 2,
                icon: _activeTab == 2 ? Icons.graphic_eq_rounded : Icons.graphic_eq_outlined,
                label: 'Voice',
                isSelected: _activeTab == 2,
                onTap: () => setState(() => _activeTab = 2),
              ),
              // 5. Profile Tab (WhatsApp style: Profile & Settings)
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
              color: isSelected ? const Color(0xFF0066FF) : unselectedNav,
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
                      backgroundColor: Color(0xFF0066FF),
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
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF0066FF)),
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
                  color: const Color(0xFF0066FF).withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.3)),
                ),
                child: const Icon(Icons.mic_none_rounded, color: Color(0xFF0066FF), size: 38),
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
                  color: const Color(0xFF0066FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hourglass_top_rounded, color: Color(0xFF0066FF), size: 14),
                    SizedBox(width: 6),
                    Text('IN DEVELOPMENT', style: TextStyle(color: Color(0xFF0066FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
