import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/networking/api_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/networking/websocket_client.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/identity/presentation/screens/create_identity_screen.dart';
import 'features/auth/presentation/screens/create_pin_screen.dart';
import 'features/chat/presentation/screens/home_screen.dart';
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/media/presentation/screens/secure_image_viewer_screen.dart';
import 'features/calls/presentation/screens/call_screen.dart';
import 'features/calls/presentation/screens/incoming_call_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'core/notifications/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const SecureChatApp());
}

class SecureChatApp extends StatefulWidget {
  const SecureChatApp({Key? key}) : super(key: key);

  @override
  State<SecureChatApp> createState() => _SecureChatAppState();
}

class _SecureChatAppState extends State<SecureChatApp> with WidgetsBindingObserver {
  String _currentScreen = 'loading';
  String? _savedScreenBeforeLock;
  Map<String, dynamic>? _user;
  String _recoveryKey = 'sample-recovery-key-1234';
  Map<String, dynamic>? _activeRecipient;
  String _activeCallType = 'video';
  String? _activeCallId;
  String _activeImageUri = '';
  bool _activeIsViewOnce = false;
  bool _isDarkMode = false;
  Map<String, dynamic>? _incomingCallData;

  final GlobalKey _callScreenKey = GlobalKey();
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<Map<String, dynamic>>? _wsCallSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wakeUpServer();
    _checkStoredUser();
    _loadThemeMode();
    _initDeepLinking();
    _initNotifications();
    _initCallSignalListener();
  }

  void _initNotifications() async {
    await NotificationService().initialize(
      onNotificationSelected: (payload) {
        if (!mounted) return;
        final type = payload['type'];
        if (type == 'chat') {
          final conversationId = payload['conversationId'];
          final senderName = payload['senderName'];
          setState(() {
            _activeRecipient = {
              'username': senderName,
              'conversationId': conversationId,
            };
            _currentScreen = 'chat';
          });
        } else if (type == 'call') {
          final callId = payload['callId'];
          final callerName = payload['callerName'];
          final callType = payload['callType'];
          final senderId = payload['senderId'];
          setState(() {
            _incomingCallData = {
              'callId': callId,
              'callerUsername': callerName,
              'callType': callType,
              'senderId': senderId,
            };
            _currentScreen = 'incoming_call';
          });
        }
      },
    );
  }

  void _wakeUpServer() async {
    // Send a non-blocking request to the server root to wake it up if it is sleeping on Render
    try {
      await ApiClient.get('/');
    } catch (_) {}
  }

  void _initCallSignalListener() {
    _wsCallSubscription?.cancel();
    _wsCallSubscription = WebSocketClient().stream.listen((event) {
      if (!mounted) return;
      final type = event['type'];
      if (type == 'chat_receive') {
        _handleIncomingChatMessage(event);
      } else if (type == 'call_offer' || type == 'call_invite') {
        _handleIncomingCall(event);
      } else if (type == 'call_ended' || type == 'call_hangup') {
        _handleCallEndedByRemote(event);
      } else if (type == 'call_failed') {
        _handleCallFailed(event);
      }
    });
  }

  void _handleIncomingChatMessage(Map<String, dynamic> event) {
    final msg = event['message'] ?? event;
    final senderName = msg['senderUsername'] ?? msg['senderId'] ?? 'Someone';
    final text = msg['text'] ?? 'Sent you an encrypted message';
    final conversationId = msg['conversationId'] ?? '';

    // If user is currently looking at this exact chat screen, don't trigger notification
    if (_currentScreen == 'chat' &&
        _activeRecipient != null &&
        (_activeRecipient!['username'] == senderName || _activeRecipient!['id'] == msg['senderId'])) {
      return;
    }

    NotificationService().showMessageNotification(
      senderName: senderName,
      messageText: text,
      conversationId: conversationId,
    );
  }

  void _handleIncomingCall(Map<String, dynamic> event) {
    if (_currentScreen == 'call' || _currentScreen == 'incoming_call') {
      WebSocketClient().send({
        'type': 'call_hangup',
        'callId': event['callId'],
        'targetId': event['senderId'],
      });
      return;
    }

    final callId = event['callId'] ?? 'call_${DateTime.now().millisecondsSinceEpoch}';
    final senderUsername = event['senderUsername'] ?? '@peer';
    final callType = event['callType'] ?? 'video';
    final senderId = event['senderId'] ?? '';

    // Trigger high-priority call notification
    NotificationService().showIncomingCallNotification(
      callId: callId,
      callerName: senderUsername,
      callType: callType,
      senderId: senderId,
    );

    // Show full-screen WhatsApp/Telegram style Incoming Call screen
    setState(() {
      _incomingCallData = {
        'callId': callId,
        'callerUsername': senderUsername,
        'callType': callType,
        'senderId': senderId,
      };
      _currentScreen = 'incoming_call';
    });
  }

  void _handleCallFailed(Map<String, dynamic> event) {
    NotificationService().cancelNotification(999);
    if (_currentScreen == 'call' && _activeCallId == event['callId']) {
      setState(() {
        _currentScreen = 'home';
        _activeCallId = null;
      });
      final target = event['targetUsername'] ?? 'User';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$target is currently offline or unavailable.'),
          backgroundColor: const Color(0xFFF43F5E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleCallEndedByRemote(Map<String, dynamic> event) {
    NotificationService().cancelNotification(999);

    if (_currentScreen == 'incoming_call' &&
        _incomingCallData != null &&
        _incomingCallData!['callId'] == event['callId']) {
      setState(() {
        _incomingCallData = null;
        _currentScreen = 'home';
      });
    } else if (_currentScreen == 'call' && _activeCallId == event['callId']) {
      setState(() {
        _currentScreen = 'home';
        _activeCallId = null;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    _wsCallSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WebSocketClient().ensureConnected();
    }
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _lockAppIfEnabled();
    }
  }

  Future<void> _lockAppIfEnabled() async {
    if (_user == null) return;
    final appLock = await SecureStorageService.read('app_lock_enabled');
    if (appLock == 'true') {
      if (_currentScreen != 'enter_pin' &&
          _currentScreen != 'loading' &&
          _currentScreen != 'onboarding' &&
          _currentScreen != 'create_identity' &&
          _currentScreen != 'create_pin') {
        setState(() {
          _savedScreenBeforeLock = _currentScreen;
          _currentScreen = 'enter_pin';
        });
      }
    }
  }

  Future<void> _loadThemeMode() async {
    final theme = await SecureStorageService.read('theme_mode');
    if (theme != null) {
      setState(() {
        _isDarkMode = theme == 'dark';
      });
    }
  }

  Future<void> _toggleTheme() async {
    final nextMode = !_isDarkMode;
    setState(() {
      _isDarkMode = nextMode;
    });
    await SecureStorageService.write('theme_mode', nextMode ? 'dark' : 'light');
  }

  Future<void> _checkStoredUser() async {
    final startTime = DateTime.now();
    final stored = await SecureStorageService.read('user_info');
    final savedImg = await SecureStorageService.read('profile_image_path');
    final appLock = await SecureStorageService.read('app_lock_enabled');

    // Smooth timing: ensure at least 600ms splash display so transition feels seamless
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    if (elapsed < 600) {
      await Future.delayed(Duration(milliseconds: 600 - elapsed));
    }

    // Remove native splash screen smoothly
    FlutterNativeSplash.remove();

    if (stored != null) {
      try {
        final parsed = jsonDecode(stored) as Map<String, dynamic>;
        if (savedImg != null) {
          parsed['profileImage'] = savedImg;
        }
        _user = parsed;

        if (appLock == 'true') {
          // Only lock if a PIN was actually set
          final storedPin = await SecureStorageService.read('user_pin_hash');
          if (storedPin != null && storedPin.isNotEmpty) {
            setState(() {
              _currentScreen = 'enter_pin';
            });
            return;
          }
        }

        setState(() {
          _currentScreen = 'home';
        });
        WebSocketClient().connect();
        return;
      } catch (_) {}
    }

    // If user is not logged in, show onboarding
    setState(() {
      _currentScreen = 'onboarding';
    });
  }

  void _initDeepLinking() async {
    // Handle links when app is running (foreground/background)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Deep link stream error: $err');
    });

    // Handle initial link (cold start)
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          _handleDeepLink(initialUri);
        });
      }
    } catch (e) {
      debugPrint('Error getting initial deep link: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received Deep Link: $uri');
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'c') {
      final token = uri.pathSegments[1];
      _resolveCallLink(token);
    } else if (uri.scheme == 'ourspace' && uri.host == 'c' && uri.pathSegments.isNotEmpty) {
      final token = uri.pathSegments[0];
      _resolveCallLink(token);
    } else if (uri.scheme == 'ourspace' && uri.pathSegments.isNotEmpty) {
      final token = uri.pathSegments.last;
      _resolveCallLink(token);
    } else if (uri.pathSegments.contains('c')) {
      final idx = uri.pathSegments.indexOf('c');
      if (idx + 1 < uri.pathSegments.length) {
        final token = uri.pathSegments[idx + 1];
        _resolveCallLink(token);
      }
    }
  }

  Future<void> _resolveCallLink(String token, {String? pin}) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7B2FBE)),
        ),
      ),
    );

    try {
      final res = await ApiClient.post('/call-links/resolve/$token', {
        if (pin != null) 'pin': pin,
      });

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading
      }

      if (res['valid'] == true) {
        if (_user == null || _currentScreen == 'enter_pin' || _currentScreen == 'onboarding' || _currentScreen == 'create_pin') {
          _showDeepLinkError('Authentication Required', 'Please log in or unlock your app before joining call links.');
          return;
        }
        setState(() {
          _activeCallType = res['callType'] ?? 'video';
          _activeCallId = res['callId'];
          _activeRecipient = {
            'id': res['hostId'] ?? 'peer',
            'username': '@host_user',
          };
          _currentScreen = 'call';
        });
      } else {
        _showDeepLinkError('Invalid Call Link', 'This call link is no longer valid or has expired.');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading
      }

      final errStr = e.toString();
      if (errStr.contains('PIN_REQUIRED')) {
        _promptForCallPin(token);
      } else {
        _showDeepLinkError('Call Link Error', errStr.replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<bool> _ensureCallPermissions(String callType) async {
    try {
      var micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        micStatus = await Permission.microphone.request();
      }

      bool camGranted = true;
      if (callType == 'video') {
        var camStatus = await Permission.camera.status;
        if (!camStatus.isGranted) {
          camStatus = await Permission.camera.request();
        }
        camGranted = camStatus.isGranted;
      }

      if (micStatus.isGranted && camGranted) {
        return true;
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera and Microphone permissions are required to make calls.'),
          backgroundColor: Color(0xFFF43F5E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }

  void _promptForCallPin(String token) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF121317) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Call PIN Required',
          style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This secure call link is password protected.',
              style: TextStyle(color: _isDarkMode ? Colors.grey : const Color(0xFF475569), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'Enter call PIN',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: _isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF7B2FBE), size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _resolveCallLink(token, pin: pinController.text);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B2FBE), Color(0xFFE91E8C)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Join Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeepLinkError(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF121317) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: TextStyle(color: _isDarkMode ? Colors.grey : const Color(0xFF475569)),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B2FBE), Color(0xFFE91E8C)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleIdentityCreated(Map<String, dynamic> newUser, String recKey) {
    WebSocketClient().connect();
    setState(() {
      _user = newUser;
      _recoveryKey = recKey;
      _currentScreen = 'home';
    });
  }

  void _handlePinComplete() {
    WebSocketClient().connect();
    setState(() {
      _currentScreen = _savedScreenBeforeLock ?? 'home';
      _savedScreenBeforeLock = null;
    });
  }

  void _handleLogout() async {
    WebSocketClient().disconnect();
    await SecureStorageService.delete('user_info');
    setState(() {
      _user = null;
      _currentScreen = 'create_identity';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OurSpace',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // CLEAN LIGHT THEME (OurSpace Purple-Pink Brand System)
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: const Color(0xFF7B2FBE),
        cardColor: const Color(0xFFFFFFFF),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF7B2FBE),
          secondary: Color(0xFFE91E8C),
          surface: Color(0xFFFFFFFF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAFC),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
          titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      // MATCHING DARK THEME SYSTEM (Pitch Black + OurSpace Purple-Pink System)
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFF7B2FBE),
        cardColor: const Color(0xFF121317),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7B2FBE),
          secondary: Color(0xFFE91E8C),
          surface: Color(0xFF121317),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),

      home: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: KeyedSubtree(
              key: ValueKey<String>(_currentScreen == 'call' ? 'home' : _currentScreen),
              child: _currentScreen == 'call' ? const SizedBox() : _buildScreen(),
            ),
          ),
          if (_activeCallId != null && _currentScreen == 'call')
            Positioned.fill(
              child: CallScreen(
                key: _callScreenKey,
                callType: _activeCallType,
                recipient: _activeRecipient,
                callId: _activeCallId,
                user: _user,
                isDarkMode: _isDarkMode,
                isPipMode: false,
                onMinimize: () => setState(() => _currentScreen = 'home'),
                onEndCall: () {
                  WebSocketClient().send({'type': 'call_hangup', 'callId': _activeCallId});
                  setState(() { _activeCallId = null; _currentScreen = 'home'; });
                },
              ),
            ),
          if (_activeCallId != null && _currentScreen != 'call' && _currentScreen != 'enter_pin' && _currentScreen != 'create_pin')
            Positioned(
              right: 20,
              bottom: 100,
              width: 120,
              height: 180,
              child: GestureDetector(
                onTap: () => setState(() => _currentScreen = 'call'),
                child: CallScreen(
                  key: _callScreenKey,
                  callType: _activeCallType,
                  recipient: _activeRecipient,
                  callId: _activeCallId,
                  user: _user,
                  isDarkMode: _isDarkMode,
                  isPipMode: true,
                  onEndCall: () {
                    WebSocketClient().send({'type': 'call_hangup', 'callId': _activeCallId});
                    setState(() => _activeCallId = null);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScreen() {
    switch (_currentScreen) {
      case 'loading':
      case 'splash':
        return SplashScreen(onContinue: () {});
      case 'onboarding':
        return OnboardingScreen(
          isDarkMode: _isDarkMode,
          onFinish: () => setState(() => _currentScreen = 'create_identity'),
        );
      case 'create_identity':
        return CreateIdentityScreen(
          isDarkMode: _isDarkMode,
          onIdentityCreated: _handleIdentityCreated,
        );
      case 'create_pin':
        return CreatePinScreen(
          isUnlockMode: false,
          isDarkMode: _isDarkMode,
          onPinComplete: _handlePinComplete,
        );
      case 'enter_pin':
        return CreatePinScreen(
          isUnlockMode: true,
          isDarkMode: _isDarkMode,
          onPinComplete: _handlePinComplete,
        );
      case 'home':
        return HomeScreen(
          user: _user,
          isDarkMode: _isDarkMode,
          onToggleTheme: _toggleTheme,
          onOpenChat: (recipient) {
            setState(() {
              _activeRecipient = recipient;
              _currentScreen = 'chat';
            });
          },
          onStartCall: (type, recipient, {callId}) async {
            final hasPerm = await _ensureCallPermissions(type);
            if (!hasPerm) return;

            // If a callId was given directly (incoming call), use it
            if (callId != null) {
              setState(() {
                _activeCallType = type;
                _activeCallId = callId;
                _activeRecipient = recipient ?? {'username': '@user'};
                _currentScreen = 'call';
              });
              return;
            }
            // Generate a real call link/room via API
            try {
              final res = await ApiClient.post('/call-links/create', {
                'callType': type,
                'durationMinutes': 60,
              });
              final token = res['token'] ?? res['callId'];
              final generatedCallId = res['callId'] ?? 'call_${DateTime.now().millisecondsSinceEpoch}';
              if (mounted) {
                setState(() {
                  _activeCallType = type;
                  _activeCallId = generatedCallId;
                  _activeRecipient = recipient ?? {'username': '@user'};
                  _currentScreen = 'call';
                });
                // Send the call link to the recipient via WebSocket
                if (recipient != null) {
                  WebSocketClient().send({
                    'type': 'call_invite',
                    'callId': generatedCallId,
                    'callType': type,
                    'token': token,
                    'targetUserId': recipient['id'],
                    'targetUsername': recipient['username'],
                    'targetPrivateId': recipient['privateId'],
                    'callerUsername': _user?['username'] ?? '@user',
                    'senderId': _user?['id'],
                    'senderProfileImage': _user?['profileImage'],
                  });
                }
              }
            } catch (e) {
              // Fallback: use a local room ID
              final fallbackId = 'call_${DateTime.now().millisecondsSinceEpoch}';
              if (mounted) {
                setState(() {
                  _activeCallType = type;
                  _activeCallId = fallbackId;
                  _activeRecipient = recipient ?? {'username': '@user'};
                  _currentScreen = 'call';
                });
                if (recipient != null) {
                  WebSocketClient().send({
                    'type': 'call_invite',
                    'callId': fallbackId,
                    'callType': type,
                    'targetUserId': recipient['id'],
                    'targetUsername': recipient['username'],
                    'targetPrivateId': recipient['privateId'],
                    'callerUsername': _user?['username'] ?? '@user',
                    'senderId': _user?['id'],
                    'senderProfileImage': _user?['profileImage'],
                  });
                }
              }
            }
          },
          onOpenSettings: () => setState(() => _currentScreen = 'settings'),
        );
      case 'chat':
        return ChatScreen(
          user: _user ?? {'id': 'u1', 'username': '@harsh01'},
          recipient: _activeRecipient ?? {'id': 'u2', 'username': '@alex_dev', 'publicKey': 'PUB-12345'},
          isDarkMode: _isDarkMode,
          onBack: () => setState(() => _currentScreen = 'home'),
          onStartCall: (type, recipient, {callId}) async {
            final hasPerm = await _ensureCallPermissions(type);
            if (!hasPerm) return;

            if (callId != null) {
              setState(() {
                _activeCallType = type;
                _activeCallId = callId;
                _activeRecipient = recipient;
                _currentScreen = 'call';
              });
              return;
            }
            try {
              final res = await ApiClient.post('/call-links/create', {
                'callType': type,
                'durationMinutes': 60,
              });
              final token = res['token'] ?? res['callId'];
              final generatedCallId = res['callId'] ?? 'call_${DateTime.now().millisecondsSinceEpoch}';
              if (mounted) {
                setState(() {
                  _activeCallType = type;
                  _activeCallId = generatedCallId;
                  _activeRecipient = recipient;
                  _currentScreen = 'call';
                });
                WebSocketClient().send({
                  'type': 'call_invite',
                  'callId': generatedCallId,
                  'callType': type,
                  'token': token,
                  'targetUserId': recipient['id'],
                  'targetUsername': recipient['username'],
                  'targetPrivateId': recipient['privateId'],
                  'callerUsername': _user?['username'] ?? '@user',
                  'senderId': _user?['id'],
                  'senderProfileImage': _user?['profileImage'],
                });
              }
            } catch (e) {
              final fallbackId = 'call_${DateTime.now().millisecondsSinceEpoch}';
              if (mounted) {
                setState(() {
                  _activeCallType = type;
                  _activeCallId = fallbackId;
                  _activeRecipient = recipient;
                  _currentScreen = 'call';
                });
                WebSocketClient().send({
                  'type': 'call_invite',
                  'callId': fallbackId,
                  'callType': type,
                  'targetUserId': recipient['id'],
                  'targetUsername': recipient['username'],
                  'targetPrivateId': recipient['privateId'],
                  'callerUsername': _user?['username'] ?? '@user',
                  'senderId': _user?['id'],
                  'senderProfileImage': _user?['profileImage'],
                });
              }
            }
          },
          onOpenImageViewer: (imageUri, isViewOnce) {
            setState(() {
              _activeImageUri = imageUri;
              _activeIsViewOnce = isViewOnce;
              _currentScreen = 'image_viewer';
            });
          },
        );
      case 'image_viewer':
        return SecureImageViewerScreen(
          imageUri: _activeImageUri,
          isViewOnce: _activeIsViewOnce,
          isDarkMode: _isDarkMode,
          onClose: () => setState(() => _currentScreen = 'chat'),
        );
      case 'incoming_call':
        if (_incomingCallData == null) {
          return HomeScreen(
            user: _user,
            isDarkMode: _isDarkMode,
            onToggleTheme: _toggleTheme,
            onOpenChat: (recipient) {
              setState(() {
                _activeRecipient = recipient;
                _currentScreen = 'chat';
              });
            },
            onStartCall: (type, recipient, {callId}) async {},
            onOpenSettings: () => setState(() => _currentScreen = 'settings'),
          );
        }
        return IncomingCallScreen(
          callId: _incomingCallData!['callId'] ?? '',
          callerUsername: _incomingCallData!['callerUsername'] ?? '@peer',
          callType: _incomingCallData!['callType'] ?? 'video',
          senderId: _incomingCallData!['senderId'] ?? '',
          senderProfileImage: _incomingCallData!['senderProfileImage'],
          onAccept: () {
            setState(() {
              _activeCallType = _incomingCallData!['callType'] ?? 'video';
              _activeCallId = _incomingCallData!['callId'];
              _activeRecipient = {
                'id': _incomingCallData!['senderId'],
                'username': _incomingCallData!['callerUsername'],
              };
              _incomingCallData = null;
              _currentScreen = 'call';
            });
          },
          onDecline: () {
            setState(() {
              _incomingCallData = null;
              _currentScreen = 'home';
            });
          },
        );
      case 'call':
        return const SizedBox();
      case 'settings':
        return SettingsScreen(
          user: _user,
          recoveryKey: _recoveryKey,
          isDarkMode: _isDarkMode,
          onToggleTheme: _toggleTheme,
          onBack: () => setState(() => _currentScreen = 'home'),
          onLogout: _handleLogout,
          onProfileImageUpdated: (base64Img) async {
            setState(() {
              if (_user != null) {
                _user!['profileImage'] = base64Img;
              }
            });
            if (_user != null) {
              await SecureStorageService.write('user_info', jsonEncode(_user));
              WebSocketClient().send({
                'type': 'profile_update',
                'senderId': _user!['id'],
                'senderUsername': _user!['username'],
                'profileImage': base64Img,
              });
            }
          },
        );
      default:
        return OnboardingScreen(
          isDarkMode: _isDarkMode,
          onFinish: () => setState(() => _currentScreen = 'create_identity'),
        );
    }
  }
}
