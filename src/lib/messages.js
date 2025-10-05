import { supabase } from './supabase';

export const messageService = {
  async getOrCreateConversation(otherUserId) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const [userId1, userId2] = [user.id, otherUserId].sort();

    let { data: conversation, error: fetchError } = await supabase
      .from('conversations')
      .select('*')
      .eq('user1_id', userId1)
      .eq('user2_id', userId2)
      .maybeSingle();

    if (fetchError) throw fetchError;

    if (!conversation) {
      const { data: newConversation, error: createError } = await supabase
        .from('conversations')
        .insert({
          user1_id: userId1,
          user2_id: userId2,
        })
        .select()
        .single();

      if (createError) throw createError;
      conversation = newConversation;
    }

    return conversation;
  },

  async getConversations() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('conversations')
      .select(`
        *,
        user1:profiles!conversations_user1_id_fkey(*),
        user2:profiles!conversations_user2_id_fkey(*),
        messages(
          id,
          content,
          created_at,
          is_read,
          sender_id
        )
      `)
      .or(`user1_id.eq.${user.id},user2_id.eq.${user.id}`)
      .order('last_message_at', { ascending: false });

    if (error) throw error;

    const conversationsWithPartner = data.map(conv => {
      const partner = conv.user1_id === user.id ? conv.user2 : conv.user1;
      const lastMessage = conv.messages?.sort((a, b) =>
        new Date(b.created_at) - new Date(a.created_at)
      )[0];
      const unreadCount = conv.messages?.filter(
        m => m.sender_id !== user.id && !m.is_read
      ).length || 0;

      return {
        ...conv,
        partner,
        lastMessage,
        unreadCount,
      };
    });

    return conversationsWithPartner;
  },

  async getMessages(conversationId) {
    const { data, error } = await supabase
      .from('messages')
      .select(`
        *,
        sender:profiles!sender_id(id, first_name, last_name, photo_url)
      `)
      .eq('conversation_id', conversationId)
      .order('created_at', { ascending: true });

    if (error) throw error;
    return data;
  },

  async sendMessage(conversationId, recipientId, content) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('messages')
      .insert({
        conversation_id: conversationId,
        sender_id: user.id,
        recipient_id: recipientId,
        content,
      })
      .select(`
        *,
        sender:profiles!sender_id(id, first_name, last_name, photo_url)
      `)
      .single();

    if (error) throw error;
    return data;
  },

  async markMessagesAsRead(conversationId) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error } = await supabase
      .from('messages')
      .update({ is_read: true })
      .eq('conversation_id', conversationId)
      .eq('recipient_id', user.id)
      .eq('is_read', false);

    if (error) throw error;
  },

  async getUnreadCount() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { count, error } = await supabase
      .from('messages')
      .select('*', { count: 'exact', head: true })
      .eq('recipient_id', user.id)
      .eq('is_read', false);

    if (error) throw error;
    return count || 0;
  },

  subscribeToMessages(conversationId, callback) {
    return supabase
      .channel(`messages:${conversationId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `conversation_id=eq.${conversationId}`,
        },
        callback
      )
      .subscribe();
  },

  unsubscribeFromMessages(conversationId) {
    supabase.removeChannel(`messages:${conversationId}`);
  },
};
