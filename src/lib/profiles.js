import { supabase } from './supabase';

export const profileService = {
  async getProfile(userId) {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async updateProfile(userId, updates) {
    const { data, error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', userId)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async createRenterProfile(profileId, renterData) {
    const { data, error } = await supabase
      .from('renter_profiles')
      .insert({
        profile_id: profileId,
        occupation_type: renterData.occupationType,
        school_or_employer: renterData.schoolOrEmployer,
        personal_description: renterData.personalDescription,
        user_references: renterData.references || null,
        desired_move_in_date: renterData.desiredMoveInDate,
        preferred_lease_length: renterData.preferredLeaseLength,
        preferences: renterData.preferences || {},
        help_types_offered: renterData.helpTypesOffered || [],
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async getRenterProfile(profileId) {
    const { data, error } = await supabase
      .from('renter_profiles')
      .select('*')
      .eq('profile_id', profileId)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async updateRenterProfile(profileId, updates) {
    const { data, error } = await supabase
      .from('renter_profiles')
      .update(updates)
      .eq('profile_id', profileId)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async createHomeownerProfile(profileId, homeownerData) {
    const { data, error } = await supabase
      .from('homeowner_profiles')
      .insert({
        profile_id: profileId,
        address: homeownerData.address,
        city: homeownerData.city,
        state: homeownerData.state,
        zip_code: homeownerData.zipCode,
        has_pets: homeownerData.hasPets || false,
        pet_details: homeownerData.petDetails || null,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async getHomeownerProfile(profileId) {
    const { data, error } = await supabase
      .from('homeowner_profiles')
      .select('*')
      .eq('profile_id', profileId)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async updateHomeownerProfile(profileId, updates) {
    const { data, error } = await supabase
      .from('homeowner_profiles')
      .update(updates)
      .eq('profile_id', profileId)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async getFullProfile(userId) {
    const profile = await this.getProfile(userId);
    if (!profile) return null;

    let extendedProfile = null;
    if (profile.user_type === 'renter') {
      extendedProfile = await this.getRenterProfile(userId);
    } else if (profile.user_type === 'homeowner') {
      extendedProfile = await this.getHomeownerProfile(userId);
    }

    return {
      ...profile,
      extendedProfile,
    };
  },
};
