import 'dart:convert';
import 'package:flutter/material.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/networking/websocket_client.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
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
  String _currentScreen = 'splash';
  Map<String, dynamic>? _user;
  String _recoveryKey = 'sample-recovery-key-1234';
  Map<String, dynamic>? _activeRecipient;
  String _activeCallType = 'video';
  String _activeImageUri = '';
  bool _activeIsViewOnce = false;

  @override
  void initState() {
    super.initState();
    _checkStoredUser();
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
    setState(() {
      _user = newUser;
      _recoveryKey = recKey;
      _currentScreen = 'create_pin';
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
      _currentScreen = 'splash';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OurSpace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0D14),
        primaryColor: const Color(0xFF10B981),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          secondary: Color(0xFF059669),
          surface: Color(0xFF141824),
        ),
      ),
      home: _buildScreen(),
    );
  }

  Widget _buildScreen() {
    switch (_currentScreen) {
      case 'splash':
        return SplashScreen(
          onContinue: () => setState(() => _currentScreen = _user != null ? 'home' : 'create_identity'),
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
          onBack: () => setState(() => _currentScreen = 'home'),
          onLogout: _handleLogout,
        );
      default:
        return SplashScreen(onContinue: () {});
    }
  }
}
