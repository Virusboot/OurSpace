import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, FlatList, TextInput, Image, Modal, Alert } from 'react-native';
import { ArrowLeft, Shield, Phone, Video, Send, Image as ImageIcon, Eye, Clock, Trash2, Check, CheckCheck } from 'lucide-react-native';
import { encryptPayload, decryptPayload } from '../crypto/e2eeCrypto';
import { fetchWithAuth, socketClient } from '../services/apiService';
import { SecurityOverlay } from '../components/SecurityOverlay';

interface ChatScreenProps {
  user: any;
  recipient: any;
  onBack: () => void;
  onStartCall: (type: 'audio' | 'video', recipient: any) => void;
  onOpenImageViewer: (encryptedBlob: string, isViewOnce: boolean) => void;
}

export const ChatScreen: React.FC<ChatScreenProps> = ({
  user,
  recipient,
  onBack,
  onStartCall,
  onOpenImageViewer
}) => {
  const [messages, setMessages] = useState<any[]>([]);
  const [inputText, setInputText] = useState('');
  const [conversationId, setConversationId] = useState<string | null>(null);

  // Disappearing messages timer setting (seconds)
  const [ttlSeconds, setTtlSeconds] = useState<number>(30); // default 30s
  const [showTimerPicker, setShowTimerPicker] = useState(false);
  const [viewOnceToggle, setViewOnceToggle] = useState(false);

  useEffect(() => {
    initChat();
  }, []);

  const initChat = async () => {
    try {
      const res = await fetchWithAuth('/chat/conversation', {
        method: 'POST',
        body: JSON.stringify({ recipientId: recipient.id })
      });
      setConversationId(res.conversationId);
      loadMessages(res.conversationId);
    } catch (err: any) {
      console.error('Chat init error:', err);
    }
  };

  const loadMessages = async (convId: string) => {
    try {
      const res = await fetchWithAuth(`/chat/messages/${convId}`);
      const decrypted = await Promise.all(
        res.messages.map(async (msg: any) => {
          const text = await decryptPayload(msg.encryptedPayload, recipient.publicKey);
          return { ...msg, decryptedText: text };
        })
      );
      setMessages(decrypted);
    } catch (err) {}
  };

  const handleSend = async () => {
    if (!inputText.trim() || !conversationId) return;
    const textToSend = inputText.trim();
    setInputText('');

    const encrypted = await encryptPayload(textToSend, recipient.publicKey);

    const localMsg = {
      id: `temp_${Date.now()}`,
      conversationId,
      senderId: user.id,
      encryptedPayload: encrypted,
      decryptedText: textToSend,
      messageType: 'text',
      expiresAt: ttlSeconds > 0 ? new Date(Date.now() + ttlSeconds * 1000).toISOString() : null,
      createdAt: new Date().toISOString()
    };

    setMessages((prev) => [...prev, localMsg]);

    socketClient.send({
      type: 'chat_send',
      conversationId,
      senderId: user.id,
      recipientId: recipient.id,
      encryptedPayload: encrypted,
      messageType: 'text',
      ttlSeconds
    });
  };

  const handleSendMockImage = async () => {
    if (!conversationId) return;
    const mockImageBlob = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
    const encrypted = await encryptPayload(mockImageBlob, recipient.publicKey);

    const messageType = viewOnceToggle ? 'view_once' : 'image';

    const localMsg = {
      id: `temp_${Date.now()}`,
      conversationId,
      senderId: user.id,
      encryptedPayload: encrypted,
      decryptedText: mockImageBlob,
      messageType,
      expiresAt: ttlSeconds > 0 ? new Date(Date.now() + ttlSeconds * 1000).toISOString() : null,
      createdAt: new Date().toISOString()
    };

    setMessages((prev) => [...prev, localMsg]);

    socketClient.send({
      type: 'chat_send',
      conversationId,
      senderId: user.id,
      recipientId: recipient.id,
      encryptedPayload: encrypted,
      messageType,
      ttlSeconds
    });

    setViewOnceToggle(false);
  };

  const formatTtlLabel = (sec: number) => {
    if (sec === 0) return 'Off';
    if (sec < 60) return `${sec}s`;
    if (sec < 3600) return `${sec / 60}m`;
    return `${sec / 3600}h`;
  };

  return (
    <SecurityOverlay isSensitive={true}>
      <View style={styles.container}>
        {/* Top Header */}
        <View style={styles.header}>
          <TouchableOpacity onPress={onBack} style={styles.iconBtn}>
            <ArrowLeft size={20} color="#ffffff" />
          </TouchableOpacity>

          <View style={styles.headerCenter}>
            <Text style={styles.recipientName}>{recipient.username}</Text>
            <View style={styles.e2eeRow}>
              <Shield size={12} color="#10b981" />
              <Text style={styles.e2eeText}>End-to-End Encrypted</Text>
            </View>
          </View>

          <View style={styles.headerRight}>
            <TouchableOpacity style={styles.iconBtn} onPress={() => onStartCall('audio', recipient)}>
              <Phone size={18} color="#10b981" />
            </TouchableOpacity>

            <TouchableOpacity style={styles.iconBtn} onPress={() => onStartCall('video', recipient)}>
              <Video size={18} color="#10b981" />
            </TouchableOpacity>

            <TouchableOpacity style={styles.timerBadge} onPress={() => setShowTimerPicker(true)}>
              <Clock size={12} color="#10b981" />
              <Text style={styles.timerBadgeText}>{formatTtlLabel(ttlSeconds)}</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Message List */}
        <FlatList
          data={messages}
          keyExtractor={(item) => item.id}
          renderItem={({ item }) => {
            const isMe = item.senderId === user.id;
            return (
              <View style={[styles.bubbleWrapper, isMe ? styles.bubbleMe : styles.bubbleOther]}>
                <View style={[styles.bubble, isMe ? styles.bubbleMeBg : styles.bubbleOtherBg]}>
                  {item.messageType === 'view_once' ? (
                    <TouchableOpacity
                      style={styles.viewOnceBtn}
                      onPress={() => onOpenImageViewer(item.decryptedText || item.encryptedPayload, true)}
                    >
                      <Eye size={18} color="#10b981" />
                      <Text style={styles.viewOnceText}>View Once Image (Tap to view)</Text>
                    </TouchableOpacity>
                  ) : item.messageType === 'image' ? (
                    <TouchableOpacity onPress={() => onOpenImageViewer(item.decryptedText || item.encryptedPayload, false)}>
                      <Image source={{ uri: item.decryptedText }} style={styles.imgPreview} />
                    </TouchableOpacity>
                  ) : (
                    <Text style={styles.messageText}>{item.decryptedText}</Text>
                  )}

                  <View style={styles.metaRow}>
                    {item.expiresAt && <Clock size={10} color="#9ca3af" />}
                    <Text style={styles.metaTime}>
                      {new Date(item.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </Text>
                    {isMe && <CheckCheck size={12} color="#10b981" />}
                  </View>
                </View>
              </View>
            );
          }}
          contentContainerStyle={styles.listContent}
        />

        {/* Input Action Bar */}
        <View style={styles.inputBar}>
          <TouchableOpacity style={styles.iconBtn} onPress={handleSendMockImage}>
            <ImageIcon size={20} color={viewOnceToggle ? '#10b981' : '#9ca3af'} />
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.viewOnceToggleBtn, viewOnceToggle && styles.viewOnceToggleActive]}
            onPress={() => setViewOnceToggle(!viewOnceToggle)}
          >
            <Eye size={14} color={viewOnceToggle ? '#10b981' : '#6b7280'} />
            <Text style={[styles.viewOnceToggleText, viewOnceToggle && styles.viewOnceToggleTextActive]}>1x</Text>
          </TouchableOpacity>

          <TextInput
            placeholder="Type encrypted message..."
            placeholderTextColor="#6b7280"
            value={inputText}
            onChangeText={setInputText}
            style={styles.input}
          />

          <TouchableOpacity style={styles.sendBtn} onPress={handleSend}>
            <Send size={16} color="#000000" />
          </TouchableOpacity>
        </View>

        {/* Disappearing Timer Picker Modal */}
        <Modal visible={showTimerPicker} transparent animationType="fade">
          <TouchableOpacity style={styles.modalOverlay} activeOpacity={1} onPress={() => setShowTimerPicker(false)}>
            <View style={styles.timerModal}>
              <Text style={styles.timerModalTitle}>Disappearing Messages</Text>
              <Text style={styles.timerModalSub}>Messages auto-delete after being read</Text>

              {[
                { label: 'Off', sec: 0 },
                { label: '10 Seconds', sec: 10 },
                { label: '30 Seconds', sec: 30 },
                { label: '1 Minute', sec: 60 },
                { label: '5 Minutes', sec: 300 },
                { label: '1 Hour', sec: 3600 },
                { label: '24 Hours', sec: 86400 }
              ].map((opt) => (
                <TouchableOpacity
                  key={opt.sec}
                  style={styles.timerOption}
                  onPress={() => {
                    setTtlSeconds(opt.sec);
                    setShowTimerPicker(false);
                  }}
                >
                  <Text style={[styles.timerOptionText, ttlSeconds === opt.sec && styles.timerOptionTextActive]}>
                    {opt.label}
                  </Text>
                  {ttlSeconds === opt.sec && <Check size={16} color="#10b981" />}
                </TouchableOpacity>
              ))}
            </View>
          </TouchableOpacity>
        </Modal>
      </View>
    </SecurityOverlay>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#090a0f' },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 48,
    paddingBottom: 14,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.08)'
  },
  headerCenter: { flex: 1, marginLeft: 12 },
  recipientName: { fontSize: 16, fontWeight: 'bold', color: '#ffffff' },
  e2eeRow: { flexDirection: 'row', alignItems: 'center', gap: 4, marginTop: 2 },
  e2eeText: { fontSize: 10, color: '#10b981', fontWeight: '600' },
  headerRight: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  iconBtn: { padding: 8 },
  timerBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: 'rgba(16, 185, 129, 0.1)',
    borderWidth: 1,
    borderColor: 'rgba(16, 185, 129, 0.3)',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12
  },
  timerBadgeText: { fontSize: 11, color: '#10b981', fontWeight: 'bold' },
  listContent: { paddingHorizontal: 16, paddingVertical: 16 },
  bubbleWrapper: { marginBottom: 12, flexDirection: 'row' },
  bubbleMe: { justifyContent: 'flex-end' },
  bubbleOther: { justifyContent: 'flex-start' },
  bubble: {
    maxWidth: '80%',
    borderRadius: 16,
    padding: 12
  },
  bubbleMeBg: { backgroundColor: '#059669', borderBottomRightRadius: 4 },
  bubbleOtherBg: { backgroundColor: 'rgba(255, 255, 255, 0.08)', borderBottomLeftRadius: 4 },
  messageText: { color: '#ffffff', fontSize: 14, lineHeight: 20 },
  metaRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'flex-end', gap: 4, marginTop: 6 },
  metaTime: { fontSize: 10, color: 'rgba(255, 255, 255, 0.6)' },
  viewOnceBtn: { flexDirection: 'row', alignItems: 'center', gap: 8, paddingVertical: 4 },
  viewOnceText: { color: '#10b981', fontSize: 13, fontWeight: '600' },
  imgPreview: { width: 180, height: 180, borderRadius: 12 },
  inputBar: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255, 255, 255, 0.08)',
    gap: 8
  },
  viewOnceToggleBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
    paddingHorizontal: 6,
    paddingVertical: 4,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)'
  },
  viewOnceToggleActive: { borderColor: '#10b981', backgroundColor: 'rgba(16, 185, 129, 0.15)' },
  viewOnceToggleText: { fontSize: 11, color: '#6b7280', fontWeight: 'bold' },
  viewOnceToggleTextActive: { color: '#10b981' },
  input: {
    flex: 1,
    backgroundColor: 'rgba(255, 255, 255, 0.06)',
    borderRadius: 20,
    paddingHorizontal: 16,
    paddingVertical: 10,
    color: '#ffffff',
    fontSize: 14
  },
  sendBtn: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: '#10b981',
    justifyContent: 'center',
    alignItems: 'center'
  },
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.8)', justifyContent: 'center', alignItems: 'center', padding: 24 },
  timerModal: { backgroundColor: '#12141d', borderRadius: 20, padding: 20, width: '100%', maxWidth: 300, borderWidth: 1, borderColor: 'rgba(255, 255, 255, 0.1)' },
  timerModalTitle: { color: '#ffffff', fontWeight: 'bold', fontSize: 16 },
  timerModalSub: { color: '#6b7280', fontSize: 11, marginBottom: 16 },
  timerOption: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: 'rgba(255, 255, 255, 0.05)' },
  timerOptionText: { color: '#9ca3af', fontSize: 14 },
  timerOptionTextActive: { color: '#10b981', fontWeight: 'bold' }
});
