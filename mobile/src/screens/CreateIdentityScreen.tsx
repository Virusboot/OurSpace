import React, { useState, useEffect } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Modal, ScrollView } from 'react-native';
import { Shield, Key, QrCode, ArrowRight, Check } from 'lucide-react-native';
import QRCode from 'react-native-qrcode-svg';
import { generateIdentityKeys, generateRecoveryKey, setSecureItem } from '../crypto/e2eeCrypto';
import { fetchWithAuth } from '../services/apiService';

interface CreateIdentityScreenProps {
  onIdentityCreated: (user: any, recoveryKey: string) => void;
}

export const CreateIdentityScreen: React.FC<CreateIdentityScreenProps> = ({ onIdentityCreated }) => {
  const [username, setUsername] = useState('@harsh01');
  const [privateId, setPrivateId] = useState('USER-7XK92P');
  const [publicKey, setPublicKey] = useState('');
  const [recoveryKey, setRecoveryKey] = useState('');
  const [showQrModal, setShowQrModal] = useState(false);
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  useEffect(() => {
    initKeys();
  }, []);

  const initKeys = async () => {
    const keys = await generateIdentityKeys();
    const recKey = await generateRecoveryKey();
    setPublicKey(keys.publicKey);
    setRecoveryKey(recKey);
    await setSecureItem('private_key', keys.privateKey);
  };

  const handleContinue = async () => {
    if (!username.trim()) return;
    setErrorMsg(null);
    setLoading(true);

    try {
      const cleanName = username.startsWith('@') ? username : `@${username}`;
      const res = await fetchWithAuth('/auth/register', {
        method: 'POST',
        body: JSON.stringify({
          username: cleanName,
          publicKey,
          recoveryKey
        })
      });

      await setSecureItem('auth_token', res.token);
      await setSecureItem('user_info', JSON.stringify(res.user));

      setLoading(false);
      onIdentityCreated(res.user, recoveryKey);
    } catch (err: any) {
      setLoading(false);
      setErrorMsg(err.message || 'Failed to create identity');
    }
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <View style={styles.header}>
        <Shield size={36} color="#10b981" />
        <Text style={styles.title}>Create Private Identity</Text>
        <Text style={styles.subtitle}>Your private key stays strictly on your device.</Text>
      </View>

      {errorMsg && (
        <View style={styles.errorBox}>
          <Text style={styles.errorText}>{errorMsg}</Text>
        </View>
      )}

      {/* Private ID Card */}
      <View style={styles.card}>
        <Text style={styles.label}>Your Private ID</Text>
        <View style={styles.idBox}>
          <Text style={styles.idText}>{privateId}</Text>
          <TouchableOpacity onPress={() => setShowQrModal(true)} style={styles.qrBtn}>
            <QrCode size={18} color="#10b981" />
          </TouchableOpacity>
        </View>
      </View>

      {/* Username Input */}
      <View style={styles.card}>
        <Text style={styles.label}>Choose Username</Text>
        <TextInput
          value={username}
          onChangeText={setUsername}
          placeholder="@username"
          placeholderTextColor="#6b7280"
          style={styles.input}
          autoCapitalize="none"
        />
      </View>

      {/* Recovery Key Banner */}
      <View style={styles.recoveryCard}>
        <View style={styles.recoveryHeader}>
          <Key size={18} color="#f59e0b" />
          <Text style={styles.recoveryTitle}>Account Recovery Key</Text>
        </View>
        <Text style={styles.recoverySubtitle}>
          Save this key safely. If you lose access, server cannot recover your account without it.
        </Text>
        <View style={styles.keyBox}>
          <Text style={styles.keyText}>{recoveryKey}</Text>
        </View>
      </View>

      <TouchableOpacity
        style={[styles.button, loading && styles.buttonDisabled]}
        onPress={handleContinue}
        disabled={loading}
        activeOpacity={0.8}
      >
        <Text style={styles.buttonText}>{loading ? 'Creating...' : 'Continue to Create PIN'}</Text>
        <ArrowRight size={18} color="#000000" />
      </TouchableOpacity>

      {/* QR Code Modal */}
      <Modal visible={showQrModal} transparent animationType="fade">
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Your Identity QR Code</Text>
            <View style={styles.qrContainer}>
              <QRCode value={`${privateId}:${username}`} size={180} backgroundColor="#ffffff" color="#000000" />
            </View>
            <Text style={styles.qrSub}>{username} • {privateId}</Text>
            <TouchableOpacity style={styles.closeBtn} onPress={() => setShowQrModal(false)}>
              <Text style={styles.closeBtnText}>Close</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    backgroundColor: '#090a0f',
    padding: 24,
    justifyContent: 'center'
  },
  header: {
    alignItems: 'center',
    marginBottom: 24
  },
  title: {
    fontSize: 22,
    fontWeight: 'bold',
    color: '#ffffff',
    marginTop: 12
  },
  subtitle: {
    fontSize: 12,
    color: '#6b7280',
    marginTop: 4
  },
  card: {
    backgroundColor: 'rgba(255, 255, 255, 0.04)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.08)',
    borderRadius: 14,
    padding: 16,
    marginBottom: 16
  },
  label: {
    fontSize: 12,
    color: '#9ca3af',
    marginBottom: 8,
    fontWeight: '600'
  },
  idBox: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: 'rgba(0, 0, 0, 0.4)',
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderRadius: 10
  },
  idText: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#10b981',
    fontFamily: 'monospace'
  },
  qrBtn: {
    padding: 4
  },
  input: {
    backgroundColor: 'rgba(0, 0, 0, 0.4)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 12,
    color: '#ffffff',
    fontSize: 15
  },
  recoveryCard: {
    backgroundColor: 'rgba(245, 158, 11, 0.06)',
    borderWidth: 1,
    borderColor: 'rgba(245, 158, 11, 0.2)',
    borderRadius: 14,
    padding: 16,
    marginBottom: 24
  },
  recoveryHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 6
  },
  recoveryTitle: {
    fontSize: 13,
    fontWeight: 'bold',
    color: '#f59e0b'
  },
  recoverySubtitle: {
    fontSize: 11,
    color: '#9ca3af',
    marginBottom: 10
  },
  keyBox: {
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    padding: 10,
    borderRadius: 8
  },
  keyText: {
    color: '#f59e0b',
    fontFamily: 'monospace',
    fontSize: 11,
    textAlign: 'center'
  },
  errorBox: {
    backgroundColor: 'rgba(244, 63, 94, 0.1)',
    borderColor: 'rgba(244, 63, 94, 0.3)',
    borderWidth: 1,
    padding: 10,
    borderRadius: 10,
    marginBottom: 16
  },
  errorText: {
    color: '#f43f5e',
    fontSize: 12,
    textAlign: 'center'
  },
  button: {
    backgroundColor: '#10b981',
    paddingVertical: 16,
    borderRadius: 14,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 8
  },
  buttonDisabled: {
    opacity: 0.5
  },
  buttonText: {
    fontSize: 15,
    fontWeight: 'bold',
    color: '#000000'
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.85)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24
  },
  modalContent: {
    backgroundColor: '#12141d',
    borderRadius: 20,
    padding: 24,
    alignItems: 'center',
    width: '100%',
    maxWidth: 320,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)'
  },
  modalTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#ffffff',
    marginBottom: 16
  },
  qrContainer: {
    padding: 16,
    backgroundColor: '#ffffff',
    borderRadius: 16,
    marginBottom: 12
  },
  qrSub: {
    fontSize: 12,
    color: '#9ca3af',
    marginBottom: 16
  },
  closeBtn: {
    paddingVertical: 10,
    paddingHorizontal: 24,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 10
  },
  closeBtnText: {
    color: '#ffffff',
    fontSize: 13,
    fontWeight: '600'
  }
});
