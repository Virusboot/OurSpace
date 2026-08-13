import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, AppState, AppStateStatus } from 'react-native';
import { ShieldAlert } from 'lucide-react-native';

interface SecurityOverlayProps {
  children: React.ReactNode;
  isSensitive?: boolean;
}

export const SecurityOverlay: React.FC<SecurityOverlayProps> = ({ children, isSensitive = true }) => {
  const [isAppActive, setIsAppActive] = useState(true);

  useEffect(() => {
    const subscription = AppState.addEventListener('change', (nextAppState: AppStateStatus) => {
      setIsAppActive(nextAppState === 'active');
    });

    return () => {
      subscription.remove();
    };
  }, []);

  return (
    <View style={styles.container}>
      {children}
      {/* Privacy screen blur/overlay when app moves to background or loses secure focus */}
      {isSensitive && !isAppActive && (
        <View style={styles.overlay}>
          <View style={styles.card}>
            <ShieldAlert size={48} color="#10b981" />
            <Text style={styles.title}>Protected View</Text>
            <Text style={styles.subtitle}>Privacy lock active while app is in background.</Text>
          </View>
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#090a0f' },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: '#090a0f',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 9999
  },
  card: {
    alignItems: 'center',
    padding: 24,
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)'
  },
  title: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#ffffff',
    marginTop: 12
  },
  subtitle: {
    fontSize: 12,
    color: '#9ca3af',
    marginTop: 4,
    textAlign: 'center'
  }
});
