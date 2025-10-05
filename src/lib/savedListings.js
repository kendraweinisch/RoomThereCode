import { supabase } from './supabase';

export const savedListingService = {
  async saveListing(listingId) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('saved_listings')
      .insert({
        renter_id: user.id,
        listing_id: listingId,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async unsaveListing(listingId) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error } = await supabase
      .from('saved_listings')
      .delete()
      .eq('renter_id', user.id)
      .eq('listing_id', listingId);

    if (error) throw error;
  },

  async getSavedListings() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('saved_listings')
      .select(`
        *,
        listing:room_listings(*),
        homeowner:room_listings(homeowner:profiles!homeowner_id(*))
      `)
      .eq('renter_id', user.id)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  },

  async isListingSaved(listingId) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return false;

    const { data, error } = await supabase
      .from('saved_listings')
      .select('id')
      .eq('renter_id', user.id)
      .eq('listing_id', listingId)
      .maybeSingle();

    if (error) throw error;
    return !!data;
  },
};
