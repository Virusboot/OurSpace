import 'dart:convert';
import 'package:flutter/material.dart';
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
  runApp(const SecureChatApp());
}

class SecureChatApp extends StatefulWidget {
  const SecureChatApp({Key? key}) : super(key: key);

  @override
  State<SecureChatApp> createState() => _SecureChatAppState();
}

class _SecureChatAppState extends State<SecureChatApp> {
  String _currentScreen = 'onboarding';
  Map<String, dynamic>? _user;
  String _recoveryKey = 'sample-recovery-key-1234';
  Map<String, dynamic>? _activeRecipient;
  String _activeCallType = 'video';
  String _activeImageUri = '';
  bool _activeIsViewOnce = false;
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _checkStoredUser();
    _loadThemeMode();
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
    final stored = await SecureStorageService.read('user_info');
    if (stored != null) {
      try {
        final parsed = jsonDecode(stored) as Map<String, dynamic>;
        setState(() {
          _user = parsed;
          _currentScreen = 'home';
        });
        WebSocketClient().connect();
      } catch (_) {}
    }
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
      _currentScreen = 'home';
    });
  }

  void _handleLogout() {
    WebSocketClient().disconnect();
    setState(() {
      _user = null;
      _currentScreen = 'onboarding';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OurSpace',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // CLEAN LIGHT THEME (OurSpace Royal Blue System)
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: const Color(0xFF0066FF),
        cardColor: const Color(0xFFFFFFFF),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0066FF),
          secondary: Color(0xFF0066FF),
          surface: Color(0xFFFFFFFF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAFC),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
          titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      // MATCHING DARK THEME SYSTEM (Pitch Black + Royal Blue System)
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFF0066FF),
        cardColor: const Color(0xFF121317),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0066FF),
          secondary: Color(0xFF0066FF),
          surface: Color(0xFF121317),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),

      home: _buildScreen(),
    );
  }

  Widget _buildScreen() {
    switch (_currentScreen) {
      case 'splash':
        return SplashScreen(
          onContinue: () => setState(() => _currentScreen = _user != null ? 'home' : 'onboarding'),
        );
      case 'onboarding':
        return OnboardingScreen(
          onFinish: () => setState(() => _currentScreen = 'create_identity'),
        );
      case 'create_identity':
        return CreateIdentityScreen(
          onIdentityCreated: _handleIdentityCreated,
        );
      case 'create_pin':
        return CreatePinScreen(
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
          onStartCall: (type, recipient) {
            setState(() {
              _activeCallType = type;
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
          onStartCall: (type, recipient) {
            setState(() {
              _activeCallType = type;
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
          onClose: () => setState(() => _currentScreen = 'chat'),
        );
      case 'call':
        return CallScreen(
          callType: _activeCallType,
          recipient: _activeRecipient,
          onEndCall: () => setState(() => _currentScreen = 'home'),
        );
      case 'settings':
        return SettingsScreen(
          user: _user,
          recoveryKey: _recoveryKey,
          isDarkMode: _isDarkMode,
          onToggleTheme: _toggleTheme,
          onBack: () => setState(() => _currentScreen = 'home'),
          onLogout: _handleLogout,
        );
      default:
        return OnboardingScreen(
          onFinish: () => setState(() => _currentScreen = 'create_identity'),
        );
    }
  }
}
