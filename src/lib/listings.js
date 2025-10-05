import { supabase } from './supabase';

export const listingService = {
  async createListing(listingData) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('room_listings')
      .insert({
        homeowner_id: user.id,
        title: listingData.title,
        description: listingData.description,
        room_type: listingData.roomType,
        bathroom_type: listingData.bathroomType,
        monthly_rent: listingData.monthlyRent,
        available_date: listingData.availableDate,
        amenities: listingData.amenities || [],
        closest_university: listingData.closestUniversity,
        distance_to_university: listingData.distanceToUniversity,
        help_discount_amount: listingData.helpDiscountAmount || 0,
        help_types_needed: listingData.helpTypesNeeded || [],
        help_description: listingData.helpDescription || null,
        photos: listingData.photos || [],
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async updateListing(listingId, updates) {
    const { data, error } = await supabase
      .from('room_listings')
      .update(updates)
      .eq('id', listingId)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async deleteListing(listingId) {
    const { error } = await supabase
      .from('room_listings')
      .delete()
      .eq('id', listingId);

    if (error) throw error;
  },

  async getListing(listingId) {
    const { data, error } = await supabase
      .from('room_listings')
      .select(`
        *,
        homeowner:profiles!homeowner_id(
          id,
          first_name,
          last_name,
          photo_url,
          is_verified,
          bio
        )
      `)
      .eq('id', listingId)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async getAllListings(filters = {}) {
    let query = supabase
      .from('room_listings')
      .select(`
        *,
        homeowner:profiles!homeowner_id(
          id,
          first_name,
          last_name,
          is_verified
        )
      `)
      .eq('is_active', true)
      .order('created_at', { ascending: false });

    if (filters.university) {
      query = query.eq('closest_university', filters.university);
    }

    if (filters.maxPrice) {
      query = query.lte('monthly_rent', filters.maxPrice);
    }

    if (filters.hasHelpDiscount !== undefined) {
      if (filters.hasHelpDiscount) {
        query = query.gt('help_discount_amount', 0);
      } else {
        query = query.eq('help_discount_amount', 0);
      }
    }

    const { data, error } = await query;
    if (error) throw error;
    return data;
  },

  async getMyListings() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('room_listings')
      .select('*')
      .eq('homeowner_id', user.id)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  },

  async incrementViewCount(listingId) {
    const { error } = await supabase.rpc('increment_listing_views', {
      listing_uuid: listingId,
    });

    if (error) throw error;
  },

  async getListingStats(homeownerId) {
    const { data: listings, error: listingsError } = await supabase
      .from('room_listings')
      .select('id, view_count')
      .eq('homeowner_id', homeownerId);

    if (listingsError) throw listingsError;

    const totalViews = listings.reduce((sum, listing) => sum + (listing.view_count || 0), 0);

    const { count: applicationsCount, error: applicationsError } = await supabase
      .from('applications')
      .select('*', { count: 'exact', head: true })
      .in('listing_id', listings.map(l => l.id));

    if (applicationsError) throw applicationsError;

    const { count: newApplicationsCount, error: newAppsError } = await supabase
      .from('applications')
      .select('*', { count: 'exact', head: true })
      .in('listing_id', listings.map(l => l.id))
      .eq('status', 'pending');

    if (newAppsError) throw newAppsError;

    return {
      totalViews,
      totalApplications: applicationsCount || 0,
      newApplications: newApplicationsCount || 0,
    };
  },
};
