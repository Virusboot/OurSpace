import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Switch } from 'react-native';
import { Lock, Fingerprint, Check } from 'lucide-react-native';
import { setSecureItem } from '../crypto/e2eeCrypto';

interface CreatePINScreenProps {
  onPinComplete: () => void;
}

export const CreatePINScreen: React.FC<CreatePINScreenProps> = ({ onPinComplete }) => {
  const [pin, setPin] = useState('');
  const [confirmPin, setConfirmPin] = useState('');
  const [step, setStep] = useState<'create' | 'confirm'>('create');
  const [biometricEnabled, setBiometricEnabled] = useState(true);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const handleKeyPress = (num: string) => {
    if (step === 'create') {
      if (pin.length < 4) {
        const next = pin + num;
        setPin(next);
        if (next.length === 4) {
          setTimeout(() => setStep('confirm'), 200);
        }
      }
    } else {
      if (confirmPin.length < 4) {
        const next = confirmPin + num;
        setConfirmPin(next);
        if (next.length === 4) {
          verifyPin(pin, next);
        }
      }
    }
  };

  const handleDelete = () => {
    if (step === 'create') {
      setPin(pin.slice(0, -1));
    } else {
      setConfirmPin(confirmPin.slice(0, -1));
    }
  };

  const verifyPin = async (originalPin: string, enteredConfirmPin: string) => {
    if (originalPin === enteredConfirmPin) {
      await setSecureItem('user_pin_hash', originalPin);
      await setSecureItem('biometric_enabled', biometricEnabled ? 'true' : 'false');
      onPinComplete();
    } else {
      setErrorMsg('PINs do not match. Try again.');
      setPin('');
      setConfirmPin('');
      setStep('create');
    }
  };

  const currentDigits = step === 'create' ? pin : confirmPin;

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <View style={styles.iconCircle}>
          <Lock size={32} color="#10b981" />
        </View>
        <Text style={styles.title}>{step === 'create' ? 'Create App PIN' : 'Confirm Your PIN'}</Text>
        <Text style={styles.subtitle}>
          {step === 'create' ? 'Set a 4-digit security PIN to protect app access' : 'Re-enter your 4-digit PIN'}
        </Text>
      </View>

      {errorMsg && <Text style={styles.errorText}>{errorMsg}</Text>}

      {/* PIN Dots Indicator */}
      <View style={styles.dotsRow}>
        {[0, 1, 2, 3].map((idx) => (
          <View
            key={idx}
            style={[
              styles.dot,
              idx < currentDigits.length && styles.dotFilled
            ]}
          />
        ))}
      </View>

      {/* Biometrics Toggle */}
      <View style={styles.biometricCard}>
        <View style={styles.biometricLeft}>
          <Fingerprint size={20} color="#10b981" />
          <Text style={styles.biometricLabel}>Enable Face ID / Biometrics</Text>
        </View>
        <Switch
          value={biometricEnabled}
          onValueChange={setBiometricEnabled}
          trackColor={{ false: '#374151', true: '#059669' }}
          thumbColor={biometricEnabled ? '#10b981' : '#9ca3af'}
        />
      </View>

      {/* Keypad */}
      <View style={styles.keypad}>
        {['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((num) => (
          <TouchableOpacity key={num} style={styles.key} onPress={() => handleKeyPress(num)}>
            <Text style={styles.keyText}>{num}</Text>
          </TouchableOpacity>
        ))}
        <View style={styles.keyPlaceholder} />
        <TouchableOpacity style={styles.key} onPress={() => handleKeyPress('0')}>
          <Text style={styles.keyText}>0</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.key} onPress={handleDelete}>
          <Text style={styles.keyDelText}>⌫</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#090a0f',
    padding: 24,
    justifyContent: 'space-between'
  },
  header: {
    alignItems: 'center',
    marginTop: 32
  },
  iconCircle: {
    width: 72,
    height: 72,
    borderRadius: 24,
    backgroundColor: 'rgba(16, 185, 129, 0.1)',
    borderWidth: 1,
    borderColor: 'rgba(16, 185, 129, 0.3)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#ffffff'
  },
  subtitle: {
    fontSize: 12,
    color: '#6b7280',
    marginTop: 4,
    textAlign: 'center'
  },
  errorText: {
    color: '#f43f5e',
    fontSize: 12,
    textAlign: 'center'
  },
  dotsRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 16,
    marginVertical: 16
  },
  dot: {
    width: 16,
    height: 16,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.2)',
    backgroundColor: 'transparent'
  },
  dotFilled: {
    backgroundColor: '#10b981',
    borderColor: '#10b981'
  },
  biometricCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: 'rgba(255, 255, 255, 0.04)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.08)',
    borderRadius: 14,
    padding: 14
  },
  biometricLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10
  },
  biometricLabel: {
    fontSize: 13,
    color: '#e5e7eb',
    fontWeight: '500'
  },
  keypad: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    rowGap: 16,
    paddingHorizontal: 24,
    marginBottom: 24
  },
  key: {
    width: '28%',
    aspectRatio: 1,
    borderRadius: 50,
    backgroundColor: 'rgba(255, 255, 255, 0.06)',
    justifyContent: 'center',
    alignItems: 'center'
  },
  keyPlaceholder: {
    width: '28%',
    aspectRatio: 1
  },
  keyText: {
    fontSize: 22,
    fontWeight: 'bold',
    color: '#ffffff'
  },
  keyDelText: {
    fontSize: 18,
    color: '#9ca3af'
  }
});
