import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, Switch, Alert } from 'react-native';
import { ArrowLeft, Lock, Fingerprint, Ghost, ShieldAlert, Key, LogOut, Info, Smartphone } from 'lucide-react-native';
import { deleteSecureItem } from '../crypto/e2eeCrypto';

interface SettingsScreenProps {
  user: any;
  recoveryKey: string;
  onBack: () => void;
  onLogout: () => void;
}

export const SettingsScreen: React.FC<SettingsScreenProps> = ({ user, recoveryKey, onBack, onLogout }) => {
  const [appLockEnabled, setAppLockEnabled] = useState(true);
  const [biometricEnabled, setBiometricEnabled] = useState(true);
  const [ghostModeEnabled, setGhostModeEnabled] = useState(false);
  const [showRecoveryKey, setShowRecoveryKey] = useState(false);

  const handleLogout = async () => {
    await deleteSecureItem('auth_token');
    await deleteSecureItem('user_info');
    onLogout();
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={onBack} style={styles.backBtn}>
          <ArrowLeft size={20} color="#ffffff" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Privacy & Security Settings</Text>
      </View>

      {/* Identity Card */}
      <View style={styles.identityCard}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>{user?.username?.substring(1, 3).toUpperCase() || 'ME'}</Text>
        </View>
        <View>
          <Text style={styles.username}>{user?.username}</Text>
          <Text style={styles.privateId}>{user?.privateId}</Text>
        </View>
      </View>

      {/* Ghost Mode Card */}
      <View style={styles.ghostCard}>
        <View style={styles.ghostHeader}>
          <View style={styles.ghostLeft}>
            <Ghost size={20} color="#10b981" />
            <Text style={styles.ghostTitle}>GHOST MODE</Text>
          </View>
          <Switch
            value={ghostModeEnabled}
            onValueChange={setGhostModeEnabled}
            trackColor={{ false: '#374151', true: '#059669' }}
            thumbColor={ghostModeEnabled ? '#10b981' : '#9ca3af'}
          />
        </View>
        <Text style={styles.ghostSub}>
          Enforces 30s auto-disappearing messages, view-once media, hidden notification previews, and aggressive cache wiping.
        </Text>
      </View>

      {/* Privacy Section */}
      <Text style={styles.sectionTitle}>Privacy & Lock</Text>

      <View style={styles.settingRow}>
        <View style={styles.rowLeft}>
          <Lock size={18} color="#9ca3af" />
          <Text style={styles.rowLabel}>App Lock (PIN)</Text>
        </View>
        <Switch
          value={appLockEnabled}
          onValueChange={setAppLockEnabled}
          trackColor={{ false: '#374151', true: '#059669' }}
          thumbColor={appLockEnabled ? '#10b981' : '#9ca3af'}
        />
      </View>

      <View style={styles.settingRow}>
        <View style={styles.rowLeft}>
          <Fingerprint size={18} color="#9ca3af" />
          <Text style={styles.rowLabel}>Biometric Unlock</Text>
        </View>
        <Switch
          value={biometricEnabled}
          onValueChange={setBiometricEnabled}
          trackColor={{ false: '#374151', true: '#059669' }}
          thumbColor={biometricEnabled ? '#10b981' : '#9ca3af'}
        />
      </View>

      {/* Security Section */}
      <Text style={styles.sectionTitle}>Security & Keys</Text>

      <TouchableOpacity style={styles.settingRowBtn} onPress={() => setShowRecoveryKey(!showRecoveryKey)}>
        <View style={styles.rowLeft}>
          <Key size={18} color="#f59e0b" />
          <Text style={styles.rowLabel}>View Recovery Key</Text>
        </View>
        <Text style={styles.rowActionText}>{showRecoveryKey ? 'Hide' : 'View'}</Text>
      </TouchableOpacity>

      {showRecoveryKey && (
        <View style={styles.recoveryBox}>
          <Text style={styles.recoveryBoxText}>{recoveryKey || 'Key stored securely in Keychain'}</Text>
        </View>
      )}

      {/* About Section */}
      <Text style={styles.sectionTitle}>About</Text>

      <View style={styles.infoCard}>
        <Info size={16} color="#6b7280" />
        <Text style={styles.infoText}>
          OurSpace v1.0.0 — Zero Knowledge, End-to-End Encrypted, Zero Server Recording.
        </Text>
      </View>

      {/* Logout */}
      <TouchableOpacity style={styles.logoutBtn} onPress={handleLogout}>
        <LogOut size={18} color="#f43f5e" />
        <Text style={styles.logoutText}>Logout / Clear Identity</Text>
      </TouchableOpacity>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flexGrow: 1, backgroundColor: '#090a0f', padding: 20 },
  header: { flexDirection: 'row', alignItems: 'center', marginTop: 32, marginBottom: 20 },
  backBtn: { padding: 6, marginRight: 12 },
  headerTitle: { color: '#ffffff', fontWeight: 'bold', fontSize: 18 },
  identityCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    backgroundColor: 'rgba(255, 255, 255, 0.04)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.08)',
    borderRadius: 16,
    padding: 16,
    marginBottom: 20
  },
  avatar: {
    width: 48,
    height: 48,
    borderRadius: 16,
    backgroundColor: 'rgba(16, 185, 129, 0.15)',
    borderWidth: 1,
    borderColor: '#10b981',
    justifyContent: 'center',
    alignItems: 'center'
  },
  avatarText: { color: '#10b981', fontWeight: 'bold', fontSize: 16 },
  username: { color: '#ffffff', fontWeight: 'bold', fontSize: 16 },
  privateId: { color: '#6b7280', fontSize: 12, fontFamily: 'monospace', marginTop: 2 },
  ghostCard: {
    backgroundColor: 'rgba(16, 185, 129, 0.08)',
    borderWidth: 1,
    borderColor: 'rgba(16, 185, 129, 0.25)',
    borderRadius: 16,
    padding: 16,
    marginBottom: 24
  },
  ghostHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 },
  ghostLeft: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  ghostTitle: { color: '#10b981', fontWeight: 'bold', fontSize: 13, letterSpacing: 1 },
  ghostSub: { color: '#9ca3af', fontSize: 11, lineHeight: 16 },
  sectionTitle: { color: '#6b7280', fontSize: 12, fontWeight: 'bold', marginTop: 12, marginBottom: 8, textTransform: 'uppercase' },
  settingRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.04)',
    padding: 14,
    borderRadius: 12,
    marginBottom: 8
  },
  settingRowBtn: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.04)',
    padding: 14,
    borderRadius: 12,
    marginBottom: 8
  },
  rowLeft: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  rowLabel: { color: '#ffffff', fontSize: 14, fontWeight: '500' },
  rowActionText: { color: '#10b981', fontSize: 13, fontWeight: 'bold' },
  recoveryBox: { backgroundColor: 'rgba(0,0,0,0.5)', padding: 12, borderRadius: 10, marginBottom: 12 },
  recoveryBoxText: { color: '#f59e0b', fontSize: 12, fontFamily: 'monospace', textAlign: 'center' },
  infoCard: { flexDirection: 'row', gap: 10, backgroundColor: 'rgba(255,255,255,0.02)', padding: 14, borderRadius: 12, marginBottom: 24 },
  infoText: { color: '#6b7280', fontSize: 11, flex: 1, lineHeight: 16 },
  logoutBtn: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 8,
    backgroundColor: 'rgba(244, 63, 94, 0.1)',
    borderWidth: 1,
    borderColor: 'rgba(244, 63, 94, 0.3)',
    paddingVertical: 14,
    borderRadius: 14,
    marginBottom: 40
  },
  logoutText: { color: '#f43f5e', fontWeight: 'bold', fontSize: 14 }
});
