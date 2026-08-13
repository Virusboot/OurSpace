import 'package:flutter/material.dart';
import '../../../../core/networking/api_client.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final Function(Map<String, dynamic> recipient) onOpenChat;
  final Function(String type, Map<String, dynamic>? recipient) onStartCall;
  final VoidCallback onOpenSettings;

  const HomeScreen({
    Key? key,
    required this.user,
    required this.onOpenChat,
    required this.onStartCall,
    required this.onOpenSettings,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeTab = 0; // 0: Chats, 1: Calls
  final List<Map<String, dynamic>> _conversations = [
    {
      'id': 'c1',
      'username': '@alex_dev',
      'privateId': 'USER-98X12A',
      'lastMessage': '🔒 [Encrypted Message]',
      'time': '14:20',
      'publicKey': 'PUB-12345',
    }
  ];

  void _showNewActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12141D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Secure Action', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF10B981)),
              title: const Text('New Private Chat', style: TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () {
                Navigator.pop(ctx);
                _showSearchUserModal();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic_outlined, color: Color(0xFF10B981)),
              title: const Text('New Audio Call', style: TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () {
                Navigator.pop(ctx);
                widget.onStartCall('audio', null);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined, color: Color(0xFF10B981)),
              title: const Text('New Video Call', style: TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () {
                Navigator.pop(ctx);
                widget.onStartCall('video', null);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: Color(0xFF10B981)),
              title: const Text('Create Call Link', style: TextStyle(color: Colors.white, fontSize: 15)),
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

  void _showSearchUserModal() {
    final searchCtrl = TextEditingController();
    Map<String, dynamic>? searchResult;
    String? searchError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF12141D),
          title: const Text('Find Identity', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Enter Username or Private ID',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                onPressed: () async {
                  setStateDialog(() {
                    searchError = null;
                    searchResult = null;
                  });
                  try {
                    final res = await ApiClient.get('/users/lookup?query=${Uri.encodeComponent(searchCtrl.text.trim())}');
                    setStateDialog(() => searchResult = res);
                  } catch (e) {
                    setStateDialog(() => searchError = 'User not found');
                  }
                },
                child: const Text('Search', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              if (searchError != null) ...[
                const SizedBox(height: 8),
                Text(searchError!, style: const TextStyle(color: const Color(0xFFF43F5E), fontSize: 12)),
              ],
              if (searchResult != null) ...[
                const SizedBox(height: 12),
                ListTile(
                  tileColor: Colors.white.withOpacity(0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  title: Text(searchResult!['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(searchResult!['privateId'], style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace')),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onOpenChat(searchResult!);
                  },
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF12141D),
          title: const Text('Create Secure Call Link', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (generatedUrl == null) ...[
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Video'),
                        selected: callType == 'video',
                        onSelected: (val) => setStateDialog(() => callType = 'video'),
                        selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Audio'),
                        selected: callType == 'audio',
                        onSelected: (val) => setStateDialog(() => callType = 'audio'),
                        selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pinCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Optional Call PIN (e.g. 1234)',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                  onPressed: () async {
                    try {
                      final res = await ApiClient.post('/call-links/create', {
                        'callType': callType,
                        'durationMinutes': 60,
                        'pin': pinCtrl.text.trim().isNotEmpty ? pinCtrl.text.trim() : null,
                      });
                      setStateDialog(() {
                        generatedUrl = 'http://localhost:3000/c/${res['token']}';
                      });
                    } catch (_) {}
                  },
                  child: const Text('Generate Link', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                const Text('Link Ready!', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SelectableText(generatedUrl!, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 11)),
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
    final username = widget.user?['username'] ?? '@harsh01';
    final privateId = widget.user?['privateId'] ?? 'USER-7XK92P';

    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090A0F),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
              child: Text(username.length > 2 ? username.substring(1, 3).toUpperCase() : 'ME', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(width: 4),
                    const Icon(Icons.shield, size: 12, color: Color(0xFF10B981)),
                  ],
                ),
                Text(privateId, style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace')),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                ChoiceChip(
                  avatar: const Icon(Icons.chat_bubble_outline, size: 14, color: Color(0xFF10B981)),
                  label: const Text('Chats'),
                  selected: _activeTab == 0,
                  onSelected: (_) => setState(() => _activeTab = 0),
                  selectedColor: const Color(0xFF10B981).withOpacity(0.15),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  avatar: const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF10B981)),
                  label: const Text('Calls'),
                  selected: _activeTab == 1,
                  onSelected: (_) => setState(() => _activeTab = 1),
                  selectedColor: const Color(0xFF10B981).withOpacity(0.15),
                ),
              ],
            ),
          ),

          Expanded(
            child: _activeTab == 0
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _conversations.length,
                    itemBuilder: (ctx, idx) {
                      final item = _conversations[idx];
                      return ListTile(
                        onTap: () => widget.onOpenChat(item),
                        leading: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.06),
                          child: Text(item['username'].substring(1, 3).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(item['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(item['lastMessage'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: Text(item['time'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      );
                    },
                  )
                : Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: _showCreateCallLinkModal,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.08),
                              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.link, size: 24, color: Color(0xFF10B981)),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Create Secure Call Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      SizedBox(height: 2),
                                      Text('Generate an expiring audio/video call link to share anywhere', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Recent Private Calls', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                        const Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone_missed_outlined, size: 32, color: Colors.white24),
                                SizedBox(height: 8),
                                Text('No recent call history', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                Text('Call history is zero-knowledge and auto-disappears', style: TextStyle(color: Colors.white24, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
        onPressed: _showNewActionSheet,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
