import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { Shield } from 'lucide-react-native';

interface SplashScreenProps {
  onContinue: () => void;
}

export const SplashScreen: React.FC<SplashScreenProps> = ({ onContinue }) => {
  return (
    <View style={styles.container}>
      <View style={styles.content}>
        <View style={styles.logoBadge}>
          <Shield size={48} color="#10b981" />
        </View>

        <Text style={styles.title}>Private Communication</Text>

        <View style={styles.mottoContainer}>
          <Text style={styles.mottoItem}>CHAT.</Text>
          <Text style={styles.mottoItem}>CALL.</Text>
          <Text style={[styles.mottoItem, styles.mottoHighlight]}>DISAPPEAR.</Text>
        </View>

        <Text style={styles.subtitle}>
          Zero knowledge. End-to-end encrypted. No phone number or email required.
        </Text>
      </View>

      <TouchableOpacity style={styles.button} onPress={onContinue} activeOpacity={0.8}>
        <Text style={styles.buttonText}>Get Started</Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#090a0f',
    justifyContent: 'space-between',
    paddingHorizontal: 24,
    paddingVertical: 48
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center'
  },
  logoBadge: {
    width: 96,
    height: 96,
    borderRadius: 28,
    backgroundColor: 'rgba(16, 185, 129, 0.1)',
    borderWidth: 1,
    borderColor: 'rgba(16, 185, 129, 0.3)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 24
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#ffffff',
    marginBottom: 12
  },
  mottoContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginVertical: 12
  },
  mottoItem: {
    fontSize: 16,
    fontWeight: '800',
    color: '#9ca3af',
    letterSpacing: 2
  },
  mottoHighlight: {
    color: '#10b981'
  },
  subtitle: {
    fontSize: 13,
    color: '#6b7280',
    textAlign: 'center',
    maxWidth: 280,
    marginTop: 8
  },
  button: {
    backgroundColor: '#10b981',
    paddingVertical: 16,
    borderRadius: 14,
    alignItems: 'center'
  },
  buttonText: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#000000'
  }
});
