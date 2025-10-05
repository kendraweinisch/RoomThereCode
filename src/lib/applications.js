import { supabase } from './supabase';

export const applicationService = {
  async createApplication(listingId, message) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('applications')
      .insert({
        listing_id: listingId,
        renter_id: user.id,
        message: message || null,
        status: 'pending',
      })
      .select(`
        *,
        listing:room_listings(*),
        renter:profiles!renter_id(*)
      `)
      .single();

    if (error) throw error;
    return data;
  },

  async updateApplicationStatus(applicationId, status) {
    const { data, error } = await supabase
      .from('applications')
      .update({ status })
      .eq('id', applicationId)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async getMyApplications() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('applications')
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

  async getApplicationsForMyListings() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('applications')
      .select(`
        *,
        listing:room_listings!inner(*),
        renter:profiles!renter_id(*),
        renter_profile:renter_profiles!applications_renter_id_fkey(*)
      `)
      .eq('listing.homeowner_id', user.id)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  },

  async getApplicationsForListing(listingId) {
    const { data, error } = await supabase
      .from('applications')
      .select(`
        *,
        renter:profiles!renter_id(*),
        renter_profile:renter_profiles!applications_renter_id_fkey(*)
      `)
      .eq('listing_id', listingId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  },
};
