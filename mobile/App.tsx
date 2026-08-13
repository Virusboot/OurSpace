import React, { useState, useEffect } from 'react';
import { View, StyleSheet } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { SplashScreen } from './src/screens/SplashScreen';
import { CreateIdentityScreen } from './src/screens/CreateIdentityScreen';
import { CreatePINScreen } from './src/screens/CreatePINScreen';
import { HomeScreen } from './src/screens/HomeScreen';
import { ChatScreen } from './src/screens/ChatScreen';
import { SecureImageViewer } from './src/screens/SecureImageViewer';
import { CallScreen } from './src/screens/CallScreen';
import { SettingsScreen } from './src/screens/SettingsScreen';
import { getSecureItem } from './src/crypto/e2eeCrypto';
import { socketClient } from './src/services/apiService';

export default function App() {
  const [screen, setScreen] = useState<'splash' | 'create_identity' | 'create_pin' | 'home' | 'chat' | 'call' | 'settings' | 'image_viewer'>('splash');
  const [user, setUser] = useState<any>(null);
  const [recoveryKey, setRecoveryKey] = useState<string>('sample-recovery-key-1234');
  const [activeRecipient, setActiveRecipient] = useState<any>(null);
  const [activeCallType, setActiveCallType] = useState<'audio' | 'video'>('video');
  const [activeImageUri, setActiveImageUri] = useState<string>('');
  const [activeIsViewOnce, setActiveIsViewOnce] = useState<boolean>(false);

  useEffect(() => {
    checkIdentity();
  }, []);

  const checkIdentity = async () => {
    try {
      const stored = await getSecureItem('user_info');
      if (stored) {
        const parsed = JSON.parse(stored);
        setUser(parsed);
        socketClient.connect();
        setScreen('home');
      }
    } catch (e) {}
  };

  const handleIdentityCreated = (newUser: any, recKey: string) => {
    setUser(newUser);
    setRecoveryKey(recKey);
    setScreen('create_pin');
  };

  const handlePinComplete = () => {
    socketClient.connect();
    setScreen('home');
  };

  const handleLogout = () => {
    setUser(null);
    socketClient.disconnect();
    setScreen('splash');
  };

  return (
    <View style={styles.container}>
      <StatusBar style="light" />

      {screen === 'splash' && (
        <SplashScreen onContinue={() => setScreen(user ? 'home' : 'create_identity')} />
      )}

      {screen === 'create_identity' && (
        <CreateIdentityScreen onIdentityCreated={handleIdentityCreated} />
      )}

      {screen === 'create_pin' && (
        <CreatePINScreen onPinComplete={handlePinComplete} />
      )}

      {screen === 'home' && (
        <HomeScreen
          user={user}
          onOpenChat={(recipient) => {
            setActiveRecipient(recipient);
            setScreen('chat');
          }}
          onStartCall={(type, recipient) => {
            setActiveCallType(type);
            setActiveRecipient(recipient || { username: '@alex_dev' });
            setScreen('call');
          }}
          onOpenSettings={() => setScreen('settings')}
        />
      )}

      {screen === 'chat' && (
        <ChatScreen
          user={user}
          recipient={activeRecipient || { id: 'u2', username: '@alex_dev', publicKey: 'PUB-12345' }}
          onBack={() => setScreen('home')}
          onStartCall={(type, recipient) => {
            setActiveCallType(type);
            setActiveRecipient(recipient);
            setScreen('call');
          }}
          onOpenImageViewer={(imageUri, isViewOnce) => {
            setActiveImageUri(imageUri);
            setActiveIsViewOnce(isViewOnce);
            setScreen('image_viewer');
          }}
        />
      )}

      {screen === 'image_viewer' && (
        <SecureImageViewer
          imageUri={activeImageUri}
          isViewOnce={activeIsViewOnce}
          onClose={() => setScreen('chat')}
        />
      )}

      {screen === 'call' && (
        <CallScreen
          callType={activeCallType}
          recipient={activeRecipient}
          onEndCall={() => setScreen('home')}
        />
      )}

      {screen === 'settings' && (
        <SettingsScreen
          user={user}
          recoveryKey={recoveryKey}
          onBack={() => setScreen('home')}
          onLogout={handleLogout}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#090a0f'
  }
});
