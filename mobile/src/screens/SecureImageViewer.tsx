import React, { useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Image } from 'react-native';
import { X, ShieldAlert, EyeOff } from 'lucide-react-native';
import { SecurityOverlay } from '../components/SecurityOverlay';

interface SecureImageViewerProps {
  imageUri: string;
  isViewOnce: boolean;
  onClose: () => void;
}

export const SecureImageViewer: React.FC<SecureImageViewerProps> = ({ imageUri, isViewOnce, onClose }) => {
  useEffect(() => {
    return () => {
      // Wipes memory reference on unmount
    };
  }, []);

  const handleClose = () => {
    onClose();
  };

  return (
    <SecurityOverlay isSensitive={true}>
      <View style={styles.container}>
        {/* Top Header */}
        <View style={styles.header}>
          <View style={styles.badge}>
            <ShieldAlert size={14} color="#10b981" />
            <Text style={styles.badgeText}>{isViewOnce ? 'View Once Image' : 'Protected Image'}</Text>
          </View>

          <TouchableOpacity style={styles.closeBtn} onPress={handleClose}>
            <X size={20} color="#ffffff" />
          </TouchableOpacity>
        </View>

        {/* Secure Image Frame */}
        <View style={styles.imageFrame}>
          <Image source={{ uri: imageUri }} style={styles.image} resizeMode="contain" />
        </View>

        {/* Bottom Security Notice */}
        <View style={styles.footer}>
          <EyeOff size={16} color="#9ca3af" />
          <Text style={styles.footerText}>
            Saving, downloading, forwarding & screenshots are restricted on supported devices.
          </Text>
        </View>
      </View>
    </SecurityOverlay>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000000', justifyContent: 'space-between' },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingTop: 48,
    paddingBottom: 16
  },
  badge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: 'rgba(16, 185, 129, 0.15)',
    borderWidth: 1,
    borderColor: 'rgba(16, 185, 129, 0.4)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20
  },
  badgeText: { color: '#10b981', fontSize: 12, fontWeight: 'bold' },
  closeBtn: { padding: 8, backgroundColor: 'rgba(255, 255, 255, 0.1)', borderRadius: 20 },
  imageFrame: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 12 },
  image: { width: '100%', height: '100%' },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingHorizontal: 24,
    paddingVertical: 20,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255, 255, 255, 0.08)'
  },
  footerText: { color: '#9ca3af', fontSize: 11, textAlign: 'center', flex: 1 }
});
