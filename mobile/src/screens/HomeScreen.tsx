import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, FlatList, Modal, TextInput, Share, Alert } from 'react-native';
import { MessageSquare, Phone, Settings, Plus, Shield, Search, Copy, Video, Mic, Link as LinkIcon, Ghost } from 'lucide-react-native';
import { fetchWithAuth } from '../services/apiService';

interface HomeScreenProps {
  user: any;
  onOpenChat: (recipient: any) => void;
  onStartCall: (type: 'audio' | 'video', recipient?: any) => void;
  onOpenSettings: () => void;
}

export const HomeScreen: React.FC<HomeScreenProps> = ({ user, onOpenChat, onStartCall, onOpenSettings }) => {
  const [activeTab, setActiveTab] = useState<'chats' | 'calls'>('chats');
  const [showNewModal, setShowNewModal] = useState(false);
  const [showSearchModal, setShowSearchModal] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResult, setSearchResult] = useState<any>(null);
  const [searchError, setSearchError] = useState<string | null>(null);

  // Call Link Generation Modal State
  const [showCallLinkModal, setShowCallLinkModal] = useState(false);
  const [linkType, setLinkType] = useState<'audio' | 'video'>('video');
  const [generatedLink, setGeneratedLink] = useState<string | null>(null);
  const [generatedPin, setGeneratedPin] = useState('');

  // Sample Chat conversations list
  const [conversations, setConversations] = useState<any[]>([
    {
      id: 'c1',
      username: '@alex_dev',
      privateId: 'USER-98X12A',
      lastMessage: '🔒 [Encrypted Message]',
      time: '14:20',
      unread: 1
    }
  ]);

  const handleSearchUser = async () => {
    if (!searchQuery.trim()) return;
    setSearchError(null);
    setSearchResult(null);
    try {
      const res = await fetchWithAuth(`/users/lookup?query=${encodeURIComponent(searchQuery.trim())}`);
      setSearchResult(res);
    } catch (err: any) {
      setSearchError('User not found');
    }
  };

  const handleCreateCallLink = async () => {
    try {
      const res = await fetchWithAuth('/call-links/create', {
        method: 'POST',
        body: JSON.stringify({
          callType: linkType,
          durationMinutes: 60,
          pin: generatedPin.trim() || undefined
        })
      });
      const fullUrl = `http://localhost:3000/c/${res.token}`;
      setGeneratedLink(fullUrl);
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to create call link');
    }
  };

  const handleShareLink = async () => {
    if (!generatedLink) return;
    try {
      await Share.share({
        message: `Join my secure private call: ${generatedLink}${generatedPin ? `\nPIN: ${generatedPin}` : ''}`
      });
    } catch (e) {}
  };

  return (
    <View style={styles.container}>
      {/* Top Header */}
      <View style={styles.header}>
        <View style={styles.userInfo}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>{user?.username?.substring(1, 3).toUpperCase() || 'ME'}</Text>
          </View>
          <View>
            <View style={styles.nameRow}>
              <Text style={styles.usernameText}>{user?.username || '@harsh01'}</Text>
              <View style={styles.e2eeBadge}>
                <Shield size={12} color="#10b981" />
              </View>
            </View>
            <Text style={styles.privateIdText}>{user?.privateId || 'USER-7XK92P'}</Text>
          </View>
        </View>

        <TouchableOpacity style={styles.settingsBtn} onPress={onOpenSettings}>
          <Settings size={20} color="#9ca3af" />
        </TouchableOpacity>
      </View>

      {/* Main Tabs */}
      <View style={styles.tabsRow}>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'chats' && styles.tabActive]}
          onPress={() => setActiveTab('chats')}
        >
          <MessageSquare size={16} color={activeTab === 'chats' ? '#10b981' : '#6b7280'} />
          <Text style={[styles.tabText, activeTab === 'chats' && styles.tabTextActive]}>Chats</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.tab, activeTab === 'calls' && styles.tabActive]}
          onPress={() => setActiveTab('calls')}
        >
          <Phone size={16} color={activeTab === 'calls' ? '#10b981' : '#6b7280'} />
          <Text style={[styles.tabText, activeTab === 'calls' && styles.tabTextActive]}>Calls</Text>
        </TouchableOpacity>
      </View>

      {/* List Content */}
      {activeTab === 'chats' ? (
        <FlatList
          data={conversations}
          keyExtractor={(item) => item.id}
          renderItem={({ item }) => (
            <TouchableOpacity style={styles.chatRow} onPress={() => onOpenChat(item)}>
              <View style={styles.rowAvatar}>
                <Text style={styles.rowAvatarText}>{item.username.substring(1, 3).toUpperCase()}</Text>
              </View>
              <View style={styles.chatMain}>
                <View style={styles.chatHeader}>
                  <Text style={styles.chatName}>{item.username}</Text>
                  <Text style={styles.chatTime}>{item.time}</Text>
                </View>
                <Text style={styles.chatMsg}>{item.lastMessage}</Text>
              </View>
            </TouchableOpacity>
          )}
          contentContainerStyle={styles.listContent}
        />
      ) : (
        /* Calls Section */
        <View style={styles.callsContainer}>
          <TouchableOpacity style={styles.createLinkCard} onPress={() => setShowCallLinkModal(true)}>
            <View style={styles.linkIconCircle}>
              <LinkIcon size={24} color="#10b981" />
            </View>
            <View style={styles.linkTextContainer}>
              <Text style={styles.linkCardTitle}>Create Secure Call Link</Text>
              <Text style={styles.linkCardSub}>Generate an expiring audio/video call link to share anywhere</Text>
            </View>
          </TouchableOpacity>

          <Text style={styles.sectionHeader}>Recent Private Calls</Text>
          <View style={styles.emptyCalls}>
            <Phone size={32} color="#374151" />
            <Text style={styles.emptyText}>No recent call history</Text>
            <Text style={styles.emptySub}>Call history is zero-knowledge and auto-disappears</Text>
          </View>
        </View>
      )}

      {/* Floating CTA Button (+ New) */}
      <TouchableOpacity style={styles.fab} onPress={() => setShowNewModal(true)} activeOpacity={0.85}>
        <Plus size={24} color="#000000" />
      </TouchableOpacity>

      {/* Action Menu Modal (+ New Options) */}
      <Modal visible={showNewModal} transparent animationType="slide">
        <TouchableOpacity style={styles.modalOverlay} activeOpacity={1} onPress={() => setShowNewModal(false)}>
          <View style={styles.actionSheet}>
            <Text style={styles.sheetTitle}>New Secure Action</Text>

            <TouchableOpacity style={styles.sheetOption} onPress={() => { setShowNewModal(false); setShowSearchModal(true); }}>
              <MessageSquare size={20} color="#10b981" />
              <Text style={styles.sheetOptionText}>New Private Chat</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.sheetOption} onPress={() => { setShowNewModal(false); onStartCall('audio'); }}>
              <Mic size={20} color="#10b981" />
              <Text style={styles.sheetOptionText}>New Audio Call</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.sheetOption} onPress={() => { setShowNewModal(false); onStartCall('video'); }}>
              <Video size={20} color="#10b981" />
              <Text style={styles.sheetOptionText}>New Video Call</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.sheetOption} onPress={() => { setShowNewModal(false); setShowCallLinkModal(true); }}>
              <LinkIcon size={20} color="#10b981" />
              <Text style={styles.sheetOptionText}>Create Call Link</Text>
            </TouchableOpacity>
          </View>
        </TouchableOpacity>
      </Modal>

      {/* User Search Modal */}
      <Modal visible={showSearchModal} transparent animationType="fade">
        <View style={styles.modalOverlay}>
          <View style={styles.searchBox}>
            <Text style={styles.searchTitle}>Find Identity</Text>
            <View style={styles.searchInputRow}>
              <TextInput
                placeholder="Enter Username or Private ID"
                placeholderTextColor="#6b7280"
                value={searchQuery}
                onChangeText={setSearchQuery}
                style={styles.searchInput}
                autoCapitalize="none"
              />
              <TouchableOpacity style={styles.searchBtn} onPress={handleSearchUser}>
                <Search size={18} color="#000000" />
              </TouchableOpacity>
            </View>

            {searchError && <Text style={styles.searchErrorText}>{searchError}</Text>}

            {searchResult && (
              <TouchableOpacity
                style={styles.resultCard}
                onPress={() => {
                  setShowSearchModal(false);
                  onOpenChat(searchResult);
                }}
              >
                <View style={styles.rowAvatar}>
                  <Text style={styles.rowAvatarText}>{searchResult.username.substring(1, 3).toUpperCase()}</Text>
                </View>
                <View>
                  <Text style={styles.chatName}>{searchResult.username}</Text>
                  <Text style={styles.privateIdText}>{searchResult.privateId}</Text>
                </View>
              </TouchableOpacity>
            )}

            <TouchableOpacity style={styles.cancelBtn} onPress={() => setShowSearchModal(false)}>
              <Text style={styles.cancelBtnText}>Cancel</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* Call Link Creation Modal */}
      <Modal visible={showCallLinkModal} transparent animationType="fade">
        <View style={styles.modalOverlay}>
          <View style={styles.searchBox}>
            <Text style={styles.searchTitle}>Create Secure Call Link</Text>

            {!generatedLink ? (
              <>
                <View style={styles.typeToggleRow}>
                  <TouchableOpacity
                    style={[styles.typeBtn, linkType === 'video' && styles.typeBtnActive]}
                    onPress={() => setLinkType('video')}
                  >
                    <Video size={16} color={linkType === 'video' ? '#10b981' : '#9ca3af'} />
                    <Text style={[styles.typeBtnText, linkType === 'video' && styles.typeBtnTextActive]}>Video</Text>
                  </TouchableOpacity>

                  <TouchableOpacity
                    style={[styles.typeBtn, linkType === 'audio' && styles.typeBtnActive]}
                    onPress={() => setLinkType('audio')}
                  >
                    <Mic size={16} color={linkType === 'audio' ? '#10b981' : '#9ca3af'} />
                    <Text style={[styles.typeBtnText, linkType === 'audio' && styles.typeBtnTextActive]}>Audio</Text>
                  </TouchableOpacity>
                </View>

                <TextInput
                  placeholder="Optional Call PIN (e.g. 1234)"
                  placeholderTextColor="#6b7280"
                  value={generatedPin}
                  onChangeText={setGeneratedPin}
                  style={styles.searchInput}
                  keyboardType="numeric"
                />

                <TouchableOpacity style={styles.genLinkBtn} onPress={handleCreateCallLink}>
                  <Text style={styles.genLinkBtnText}>Generate Link</Text>
                </TouchableOpacity>
              </>
            ) : (
              <>
                <Text style={styles.linkResultTitle}>Link Ready!</Text>
                <View style={styles.linkResultBox}>
                  <Text style={styles.linkResultUrl}>{generatedLink}</Text>
                </View>
                {generatedPin ? <Text style={styles.pinResultText}>PIN Protected: {generatedPin}</Text> : null}

                <TouchableOpacity style={styles.genLinkBtn} onPress={handleShareLink}>
                  <Copy size={16} color="#000000" />
                  <Text style={styles.genLinkBtnText}>Share Link</Text>
                </TouchableOpacity>
              </>
            )}

            <TouchableOpacity style={styles.cancelBtn} onPress={() => { setShowCallLinkModal(false); setGeneratedLink(null); }}>
              <Text style={styles.cancelBtnText}>Close</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#090a0f' },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingTop: 48,
    paddingBottom: 16,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.08)'
  },
  userInfo: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  avatar: {
    width: 44,
    height: 44,
    borderRadius: 14,
    backgroundColor: 'rgba(16, 185, 129, 0.15)',
    borderWidth: 1,
    borderColor: 'rgba(16, 185, 129, 0.4)',
    justifyContent: 'center',
    alignItems: 'center'
  },
  avatarText: { fontSize: 16, fontWeight: 'bold', color: '#10b981' },
  nameRow: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  usernameText: { fontSize: 16, fontWeight: 'bold', color: '#ffffff' },
  e2eeBadge: { padding: 2 },
  privateIdText: { fontSize: 11, color: '#6b7280', fontFamily: 'monospace' },
  settingsBtn: { padding: 8 },
  tabsRow: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    paddingVertical: 12,
    gap: 12
  },
  tab: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.04)'
  },
  tabActive: {
    backgroundColor: 'rgba(16, 185, 129, 0.15)',
    borderWidth: 1,
    borderColor: 'rgba(16, 185, 129, 0.3)'
  },
  tabText: { fontSize: 13, color: '#6b7280', fontWeight: '600' },
  tabTextActive: { color: '#10b981' },
  listContent: { paddingHorizontal: 20, paddingBottom: 100 },
  chatRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.05)',
    gap: 12
  },
  rowAvatar: {
    width: 44,
    height: 44,
    borderRadius: 14,
    backgroundColor: 'rgba(255, 255, 255, 0.06)',
    justifyContent: 'center',
    alignItems: 'center'
  },
  rowAvatarText: { color: '#ffffff', fontWeight: 'bold', fontSize: 15 },
  chatMain: { flex: 1 },
  chatHeader: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 4 },
  chatName: { color: '#ffffff', fontWeight: 'bold', fontSize: 14 },
  chatTime: { color: '#6b7280', fontSize: 11 },
  chatMsg: { color: '#9ca3af', fontSize: 12 },
  callsContainer: { paddingHorizontal: 20 },
  createLinkCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    backgroundColor: 'rgba(16, 185, 129, 0.08)',
    borderWidth: 1,
    borderColor: 'rgba(16, 185, 129, 0.25)',
    borderRadius: 16,
    padding: 16,
    marginVertical: 12
  },
  linkIconCircle: {
    width: 48,
    height: 48,
    borderRadius: 14,
    backgroundColor: 'rgba(16, 185, 129, 0.15)',
    justifyContent: 'center',
    alignItems: 'center'
  },
  linkTextContainer: { flex: 1 },
  linkCardTitle: { color: '#ffffff', fontWeight: 'bold', fontSize: 14 },
  linkCardSub: { color: '#9ca3af', fontSize: 11, marginTop: 2 },
  sectionHeader: { color: '#6b7280', fontSize: 12, fontWeight: 'bold', marginTop: 16, marginBottom: 12 },
  emptyCalls: { alignItems: 'center', justifyContent: 'center', paddingTop: 40 },
  emptyText: { color: '#9ca3af', fontWeight: 'bold', fontSize: 14, marginTop: 12 },
  emptySub: { color: '#6b7280', fontSize: 11, marginTop: 4 },
  fab: {
    position: 'absolute',
    bottom: 28,
    right: 20,
    width: 56,
    height: 56,
    borderRadius: 18,
    backgroundColor: '#10b981',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#10b981',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.4,
    shadowRadius: 12,
    elevation: 8
  },
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.8)', justifyContent: 'flex-end' },
  actionSheet: {
    backgroundColor: '#12141d',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    padding: 24,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)'
  },
  sheetTitle: { color: '#ffffff', fontWeight: 'bold', fontSize: 16, marginBottom: 16 },
  sheetOption: { flexDirection: 'row', alignItems: 'center', gap: 14, paddingVertical: 14 },
  sheetOptionText: { color: '#ffffff', fontSize: 15, fontWeight: '600' },
  searchBox: {
    backgroundColor: '#12141d',
    borderRadius: 20,
    padding: 24,
    margin: 20,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)'
  },
  searchTitle: { color: '#ffffff', fontWeight: 'bold', fontSize: 16, marginBottom: 14 },
  searchInputRow: { flexDirection: 'row', gap: 8, marginBottom: 12 },
  searchInput: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.4)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    color: '#ffffff',
    fontSize: 13
  },
  searchBtn: {
    backgroundColor: '#10b981',
    paddingHorizontal: 14,
    borderRadius: 10,
    justifyContent: 'center',
    alignItems: 'center'
  },
  searchErrorText: { color: '#f43f5e', fontSize: 12, marginVertical: 6 },
  resultCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    padding: 12,
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderRadius: 12,
    marginVertical: 10
  },
  cancelBtn: { paddingVertical: 12, alignItems: 'center', marginTop: 8 },
  cancelBtnText: { color: '#9ca3af', fontSize: 13, fontWeight: '600' },
  typeToggleRow: { flexDirection: 'row', gap: 12, marginBottom: 14 },
  typeBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    paddingVertical: 10,
    borderRadius: 10,
    backgroundColor: 'rgba(255, 255, 255, 0.05)'
  },
  typeBtnActive: { backgroundColor: 'rgba(16, 185, 129, 0.15)', borderWidth: 1, borderColor: 'rgba(16, 185, 129, 0.3)' },
  typeBtnText: { color: '#9ca3af', fontSize: 13, fontWeight: '600' },
  typeBtnTextActive: { color: '#10b981' },
  genLinkBtn: {
    backgroundColor: '#10b981',
    paddingVertical: 12,
    borderRadius: 10,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 6,
    marginTop: 12
  },
  genLinkBtnText: { color: '#000000', fontWeight: 'bold', fontSize: 14 },
  linkResultTitle: { color: '#10b981', fontWeight: 'bold', fontSize: 14, marginTop: 8 },
  linkResultBox: {
    backgroundColor: 'rgba(0,0,0,0.5)',
    padding: 12,
    borderRadius: 10,
    marginVertical: 8
  },
  linkResultUrl: { color: '#ffffff', fontSize: 11, fontFamily: 'monospace' },
  pinResultText: { color: '#f59e0b', fontSize: 11, textAlign: 'center', marginBottom: 8 }
});
