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
import 'features/settings/presentation/screens/settings_screen.dart';

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

  final GlobalKey _callScreenKey = GlobalKey();
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<Map<String, dynamic>>? _wsCallSubscription;
  BuildContext? _incomingCallDialogContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wakeUpServer();
    _checkStoredUser();
    _loadThemeMode();
    _initDeepLinking();
    _initCallSignalListener();
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
      if (type == 'call_offer') {
        _handleIncomingCall(event);
      } else if (type == 'call_ended' || type == 'call_hangup') {
        _handleCallEndedByRemote(event);
      }
    });
  }

  void _handleIncomingCall(Map<String, dynamic> event) {
    if (_currentScreen == 'call') {
      WebSocketClient().send({
        'type': 'call_hangup',
        'callId': event['callId'],
        'targetId': event['senderId'],
      });
      return;
    }

    final senderUsername = event['senderUsername'] ?? '@peer';
    final callType = event['callType'] ?? 'video';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        _incomingCallDialogContext = dialogCtx;
        return AlertDialog(
          backgroundColor: _isDarkMode ? const Color(0xFF14161C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                callType == 'video' ? Icons.videocam_rounded : Icons.phone_rounded,
                color: const Color(0xFF7B2FBE),
              ),
              const SizedBox(width: 8),
              const Text('Incoming Call', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Text(
            '$senderUsername is calling you...',
            style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black87, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _incomingCallDialogContext = null;
                Navigator.pop(dialogCtx);
                WebSocketClient().send({
                  'type': 'call_hangup',
                  'callId': event['callId'],
                  'targetId': event['senderId'],
                });
              },
              child: const Text('Reject', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2FBE),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                _incomingCallDialogContext = null;
                Navigator.pop(dialogCtx);
                setState(() {
                  _activeCallType = callType;
                  _activeCallId = event['callId'];
                  _activeRecipient = {
                    'id': event['senderId'],
                    'username': senderUsername,
                  };
                  _currentScreen = 'call';
                });
              },
              child: const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _handleCallEndedByRemote(Map<String, dynamic> event) {
    if (_incomingCallDialogContext != null) {
      Navigator.of(_incomingCallDialogContext!).pop();
      _incomingCallDialogContext = null;
    }

    if (_currentScreen == 'call' && _activeCallId == event['callId']) {
      setState(() {
        _currentScreen = 'home';
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
          setState(() {
            _currentScreen = 'enter_pin';
          });
          return;
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
          onStartCall: (type, recipient, {callId}) {
            setState(() {
              _activeCallType = type;
              _activeCallId = callId ?? 'call_${DateTime.now().millisecondsSinceEpoch}';
              _activeRecipient = recipient ?? {'username': '@alex_dev'};
              _currentScreen = 'call';
            });
          },
          onOpenSettings: () => setState(() => _currentScreen = 'settings'),
        );
      case 'chat':
        return ChatScreen(
          user: _user ?? {'id': 'u1', 'username': '@harsh01'},
          recipient: _activeRecipient ?? {'id': 'u2', 'username': '@alex_dev', 'publicKey': 'PUB-12345'},
          isDarkMode: _isDarkMode,
          onBack: () => setState(() => _currentScreen = 'home'),
          onStartCall: (type, recipient, {callId}) {
            setState(() {
              _activeCallType = type;
              _activeCallId = callId ?? 'call_${DateTime.now().millisecondsSinceEpoch}';
              _activeRecipient = recipient;
              _currentScreen = 'call';
            });
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
          onProfileImageUpdated: (path) {
            setState(() {
              if (_user != null) {
                _user!['profileImage'] = path;
              }
            });
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
