import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { Mic, MicOff, Video, VideoOff, PhoneOff, Volume2, Shield } from 'lucide-react-native';
import { SecurityOverlay } from '../components/SecurityOverlay';

interface CallScreenProps {
  callType: 'audio' | 'video';
  recipient: any;
  onEndCall: () => void;
}

export const CallScreen: React.FC<CallScreenProps> = ({ callType, recipient, onEndCall }) => {
  const [micEnabled, setMicEnabled] = useState(true);
  const [camEnabled, setCamEnabled] = useState(callType === 'video');
  const [secondsElapsed, setSecondsElapsed] = useState(0);

  useEffect(() => {
    const timer = setInterval(() => {
      setSecondsElapsed((prev) => prev + 1);
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const formatTimer = (sec: number) => {
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  return (
    <SecurityOverlay isSensitive={true}>
      <View style={styles.container}>
        {/* Top Call Info */}
        <View style={styles.topBar}>
          <View style={styles.encryptedTag}>
            <Shield size={14} color="#10b981" />
            <Text style={styles.encryptedTagText}>WebRTC Encrypted</Text>
          </View>
          <Text style={styles.timerText}>{formatTimer(secondsElapsed)}</Text>
        </View>

        {/* Video / Audio Center Stage */}
        <View style={styles.centerStage}>
          {callType === 'video' ? (
            <View style={styles.videoContainer}>
              <View style={styles.remoteVideoPlaceholder}>
                <View style={styles.largeAvatar}>
                  <Text style={styles.largeAvatarText}>
                    {recipient?.username ? recipient.username.substring(1, 3).toUpperCase() : 'PEER'}
                  </Text>
                </View>
                <Text style={styles.peerNameText}>{recipient?.username || 'Peer Participant'}</Text>
                <Text style={styles.callStateSub}>Encrypted Video Stream</Text>
              </View>

              {/* Local Preview Thumbnail */}
              <View style={styles.localVideoPreview}>
                {camEnabled ? (
                  <View style={styles.localCamActive}>
                    <Text style={styles.localCamText}>YOU</Text>
                  </View>
                ) : (
                  <VideoOff size={20} color="#6b7280" />
                )}
              </View>
            </View>
          ) : (
            /* Audio Call UI */
            <View style={styles.audioContainer}>
              <View style={styles.audioAvatarPulse}>
                <Volume2 size={48} color="#10b981" />
              </View>
              <Text style={styles.audioPeerName}>{recipient?.username || 'Private Peer'}</Text>
              <Text style={styles.audioSubText}>Zero-Knowledge Audio Call</Text>
            </View>
          )}
        </View>

        {/* Bottom Call Controls */}
        <View style={styles.controlsBar}>
          <TouchableOpacity
            style={[styles.controlBtn, !micEnabled && styles.controlBtnOff]}
            onPress={() => setMicEnabled(!micEnabled)}
          >
            {micEnabled ? <Mic size={22} color="#ffffff" /> : <MicOff size={22} color="#f43f5e" />}
          </TouchableOpacity>

          {callType === 'video' && (
            <TouchableOpacity
              style={[styles.controlBtn, !camEnabled && styles.controlBtnOff]}
              onPress={() => setCamEnabled(!camEnabled)}
            >
              {camEnabled ? <Video size={22} color="#ffffff" /> : <VideoOff size={22} color="#f43f5e" />}
            </TouchableOpacity>
          )}

          <TouchableOpacity style={styles.endCallBtn} onPress={onEndCall}>
            <PhoneOff size={26} color="#ffffff" />
          </TouchableOpacity>
        </View>
      </View>
    </SecurityOverlay>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#090a0f', justifyContent: 'space-between', padding: 24 },
  topBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 32
  },
  encryptedTag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: 'rgba(16, 185, 129, 0.15)',
    borderWidth: 1,
    borderColor: 'rgba(16, 185, 129, 0.3)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20
  },
  encryptedTagText: { color: '#10b981', fontSize: 11, fontWeight: 'bold' },
  timerText: { color: '#ffffff', fontFamily: 'monospace', fontSize: 14, fontWeight: '600' },
  centerStage: { flex: 1, justifyContent: 'center', marginVertical: 20 },
  videoContainer: { flex: 1, borderRadius: 20, backgroundColor: 'rgba(255,255,255,0.03)', borderWidth: 1, borderColor: 'rgba(255,255,255,0.08)', overflow: 'hidden', justifyContent: 'center', alignItems: 'center' },
  remoteVideoPlaceholder: { alignItems: 'center' },
  largeAvatar: { width: 80, height: 80, borderRadius: 28, backgroundColor: 'rgba(16, 185, 129, 0.2)', borderWidth: 1, borderColor: '#10b981', justifyContent: 'center', alignItems: 'center', marginBottom: 12 },
  largeAvatarText: { color: '#10b981', fontSize: 24, fontWeight: 'bold' },
  peerNameText: { color: '#ffffff', fontWeight: 'bold', fontSize: 18 },
  callStateSub: { color: '#6b7280', fontSize: 12, marginTop: 4 },
  localVideoPreview: { position: 'absolute', bottom: 16, right: 16, width: 90, height: 130, borderRadius: 14, backgroundColor: '#12141d', borderWidth: 1, borderColor: 'rgba(255,255,255,0.2)', justifyContent: 'center', alignItems: 'center' },
  localCamActive: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  localCamText: { color: '#10b981', fontSize: 10, fontWeight: 'bold' },
  audioContainer: { alignItems: 'center', justifyContent: 'center' },
  audioAvatarPulse: { width: 120, height: 120, borderRadius: 40, backgroundColor: 'rgba(16, 185, 129, 0.1)', borderWidth: 1, borderColor: 'rgba(16, 185, 129, 0.3)', justifyContent: 'center', alignItems: 'center', marginBottom: 20 },
  audioPeerName: { color: '#ffffff', fontWeight: 'bold', fontSize: 22 },
  audioSubText: { color: '#6b7280', fontSize: 13, marginTop: 6 },
  controlsBar: { flexDirection: 'row', justifyContent: 'center', alignItems: 'center', gap: 24, marginBottom: 16 },
  controlBtn: { width: 56, height: 56, borderRadius: 28, backgroundColor: 'rgba(255, 255, 255, 0.1)', borderWidth: 1, borderColor: 'rgba(255, 255, 255, 0.15)', justifyContent: 'center', alignItems: 'center' },
  controlBtnOff: { backgroundColor: 'rgba(244, 63, 94, 0.15)', borderColor: 'rgba(244, 63, 94, 0.4)' },
  endCallBtn: { width: 64, height: 64, borderRadius: 32, backgroundColor: '#f43f5e', justifyContent: 'center', alignItems: 'center' }
});
