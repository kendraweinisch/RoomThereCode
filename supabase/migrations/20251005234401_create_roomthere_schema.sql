/*
  # RoomThere Database Schema

  ## Overview
  Complete database schema for RoomThere - an intergenerational housing platform connecting
  homeowners (seniors) with renters (graduate students and young professionals).

  ## New Tables Created
  
  ### 1. `profiles`
  User profile information for both homeowners and renters
  - `id` (uuid, FK to auth.users)
  - `user_type` (text) - 'homeowner' or 'renter'
  - `first_name`, `last_name` (text)
  - `email` (text)
  - `phone` (text, optional)
  - `photo_url` (text, optional)
  - `bio` (text, optional)
  - `is_verified` (boolean) - background check status
  - `created_at`, `updated_at` (timestamptz)

  ### 2. `renter_profiles`
  Extended profile data specific to renters
  - `id` (uuid, primary key)
  - `profile_id` (uuid, FK to profiles)
  - `occupation_type` (text) - 'grad-student' or 'young-professional'
  - `school_or_employer` (text)
  - `personal_description` (text)
  - `user_references` (text, optional)
  - `desired_move_in_date` (date)
  - `preferred_lease_length` (text)
  - `preferences` (jsonb) - lifestyle preferences
  - `help_types_offered` (jsonb) - assistance they can provide

  ### 3. `homeowner_profiles`
  Extended profile data specific to homeowners
  - `id` (uuid, primary key)
  - `profile_id` (uuid, FK to profiles)
  - `address` (text)
  - `city` (text)
  - `state` (text)
  - `zip_code` (text)
  - `has_pets` (boolean)
  - `pet_details` (jsonb, optional)

  ### 4. `room_listings`
  Available room listings created by homeowners
  - `id` (uuid, primary key)
  - `homeowner_id` (uuid, FK to profiles)
  - `title` (text)
  - `description` (text)
  - `room_type` (text) - 'private' or 'studio'
  - `bathroom_type` (text) - 'private' or 'shared'
  - `monthly_rent` (numeric)
  - `available_date` (date)
  - `amenities` (jsonb)
  - `closest_university` (text)
  - `distance_to_university` (text)
  - `help_discount_amount` (numeric, optional)
  - `help_types_needed` (jsonb, optional)
  - `help_description` (text, optional)
  - `photos` (jsonb)
  - `is_active` (boolean)
  - `view_count` (integer)

  ### 5. `applications`
  Rental applications from renters to homeowners
  - `id` (uuid, primary key)
  - `listing_id` (uuid, FK to room_listings)
  - `renter_id` (uuid, FK to profiles)
  - `status` (text) - 'pending', 'accepted', 'rejected'
  - `message` (text)
  - `created_at`, `updated_at` (timestamptz)

  ### 6. `messages`
  Direct messages between users
  - `id` (uuid, primary key)
  - `sender_id` (uuid, FK to profiles)
  - `recipient_id` (uuid, FK to profiles)
  - `content` (text)
  - `is_read` (boolean)
  - `created_at` (timestamptz)

  ### 7. `conversations`
  Conversation threads between two users
  - `id` (uuid, primary key)
  - `user1_id` (uuid, FK to profiles)
  - `user2_id` (uuid, FK to profiles)
  - `last_message_at` (timestamptz)
  - `created_at` (timestamptz)

  ### 8. `saved_listings`
  Renters can save listings for later
  - `id` (uuid, primary key)
  - `renter_id` (uuid, FK to profiles)
  - `listing_id` (uuid, FK to room_listings)
  - `created_at` (timestamptz)

  ### 9. `contact_submissions`
  Contact form submissions from the website
  - `id` (uuid, primary key)
  - `name` (text)
  - `email` (text)
  - `user_type` (text, optional)
  - `subject` (text)
  - `message` (text)
  - `created_at` (timestamptz)

  ### 10. `problem_reports`
  Problem/safety reports from users
  - `id` (uuid, primary key)
  - `reporter_email` (text)
  - `reporter_name` (text)
  - `issue_type` (text)
  - `subject` (text)
  - `description` (text)
  - `created_at` (timestamptz)

  ## Security (RLS Policies)
  
  All tables have Row Level Security enabled with appropriate policies:
  - Users can only read/update their own profiles
  - Homeowners can manage their own listings
  - Renters can view active listings
  - Messages are only visible to sender and recipient
  - Applications are visible to involved parties only

*/

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- PROFILES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  user_type text NOT NULL CHECK (user_type IN ('homeowner', 'renter')),
  first_name text NOT NULL,
  last_name text NOT NULL,
  email text NOT NULL,
  phone text,
  photo_url text,
  bio text,
  is_verified boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ============================================================================
-- RENTER PROFILES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS renter_profiles (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
  occupation_type text NOT NULL CHECK (occupation_type IN ('grad-student', 'young-professional')),
  school_or_employer text NOT NULL,
  personal_description text NOT NULL,
  user_references text,
  desired_move_in_date date NOT NULL,
  preferred_lease_length text NOT NULL,
  preferences jsonb DEFAULT '{}'::jsonb,
  help_types_offered jsonb DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE renter_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own renter profile"
  ON renter_profiles FOR SELECT
  TO authenticated
  USING (profile_id = auth.uid());

CREATE POLICY "Users can insert own renter profile"
  ON renter_profiles FOR INSERT
  TO authenticated
  WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can update own renter profile"
  ON renter_profiles FOR UPDATE
  TO authenticated
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Homeowners can view renter profiles"
  ON renter_profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type = 'homeowner'
    )
  );

-- ============================================================================
-- HOMEOWNER PROFILES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS homeowner_profiles (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
  address text NOT NULL,
  city text NOT NULL,
  state text NOT NULL,
  zip_code text NOT NULL,
  has_pets boolean DEFAULT false,
  pet_details jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE homeowner_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own homeowner profile"
  ON homeowner_profiles FOR SELECT
  TO authenticated
  USING (profile_id = auth.uid());

CREATE POLICY "Users can insert own homeowner profile"
  ON homeowner_profiles FOR INSERT
  TO authenticated
  WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can update own homeowner profile"
  ON homeowner_profiles FOR UPDATE
  TO authenticated
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

-- ============================================================================
-- ROOM LISTINGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS room_listings (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  homeowner_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text NOT NULL,
  room_type text NOT NULL CHECK (room_type IN ('private', 'studio')),
  bathroom_type text NOT NULL CHECK (bathroom_type IN ('private', 'shared')),
  monthly_rent numeric(10, 2) NOT NULL CHECK (monthly_rent >= 0),
  available_date date NOT NULL,
  amenities jsonb DEFAULT '[]'::jsonb,
  closest_university text NOT NULL,
  distance_to_university text NOT NULL,
  help_discount_amount numeric(10, 2) DEFAULT 0 CHECK (help_discount_amount >= 0),
  help_types_needed jsonb DEFAULT '[]'::jsonb,
  help_description text,
  photos jsonb DEFAULT '[]'::jsonb,
  is_active boolean DEFAULT true,
  view_count integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE room_listings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active listings"
  ON room_listings FOR SELECT
  TO authenticated
  USING (is_active = true);

CREATE POLICY "Homeowners can view own listings"
  ON room_listings FOR SELECT
  TO authenticated
  USING (homeowner_id = auth.uid());

CREATE POLICY "Homeowners can insert own listings"
  ON room_listings FOR INSERT
  TO authenticated
  WITH CHECK (homeowner_id = auth.uid());

CREATE POLICY "Homeowners can update own listings"
  ON room_listings FOR UPDATE
  TO authenticated
  USING (homeowner_id = auth.uid())
  WITH CHECK (homeowner_id = auth.uid());

CREATE POLICY "Homeowners can delete own listings"
  ON room_listings FOR DELETE
  TO authenticated
  USING (homeowner_id = auth.uid());

-- ============================================================================
-- APPLICATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS applications (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  listing_id uuid NOT NULL REFERENCES room_listings(id) ON DELETE CASCADE,
  renter_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  message text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(listing_id, renter_id)
);

ALTER TABLE applications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Renters can view own applications"
  ON applications FOR SELECT
  TO authenticated
  USING (renter_id = auth.uid());

CREATE POLICY "Homeowners can view applications for their listings"
  ON applications FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM room_listings
      WHERE room_listings.id = applications.listing_id
      AND room_listings.homeowner_id = auth.uid()
    )
  );

CREATE POLICY "Renters can insert own applications"
  ON applications FOR INSERT
  TO authenticated
  WITH CHECK (renter_id = auth.uid());

CREATE POLICY "Homeowners can update applications for their listings"
  ON applications FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM room_listings
      WHERE room_listings.id = applications.listing_id
      AND room_listings.homeowner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM room_listings
      WHERE room_listings.id = applications.listing_id
      AND room_listings.homeowner_id = auth.uid()
    )
  );

-- ============================================================================
-- CONVERSATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS conversations (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user1_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  user2_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  last_message_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  CHECK (user1_id < user2_id),
  UNIQUE(user1_id, user2_id)
);

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own conversations"
  ON conversations FOR SELECT
  TO authenticated
  USING (user1_id = auth.uid() OR user2_id = auth.uid());

CREATE POLICY "Users can create conversations"
  ON conversations FOR INSERT
  TO authenticated
  WITH CHECK (user1_id = auth.uid() OR user2_id = auth.uid());

CREATE POLICY "Users can update own conversations"
  ON conversations FOR UPDATE
  TO authenticated
  USING (user1_id = auth.uid() OR user2_id = auth.uid())
  WITH CHECK (user1_id = auth.uid() OR user2_id = auth.uid());

-- ============================================================================
-- MESSAGES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS messages (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  recipient_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content text NOT NULL,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view messages in their conversations"
  ON messages FOR SELECT
  TO authenticated
  USING (sender_id = auth.uid() OR recipient_id = auth.uid());

CREATE POLICY "Users can send messages"
  ON messages FOR INSERT
  TO authenticated
  WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Users can update read status of received messages"
  ON messages FOR UPDATE
  TO authenticated
  USING (recipient_id = auth.uid())
  WITH CHECK (recipient_id = auth.uid());

-- ============================================================================
-- SAVED LISTINGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS saved_listings (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  renter_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  listing_id uuid NOT NULL REFERENCES room_listings(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(renter_id, listing_id)
);

ALTER TABLE saved_listings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Renters can view own saved listings"
  ON saved_listings FOR SELECT
  TO authenticated
  USING (renter_id = auth.uid());

CREATE POLICY "Renters can insert own saved listings"
  ON saved_listings FOR INSERT
  TO authenticated
  WITH CHECK (renter_id = auth.uid());

CREATE POLICY "Renters can delete own saved listings"
  ON saved_listings FOR DELETE
  TO authenticated
  USING (renter_id = auth.uid());

-- ============================================================================
-- CONTACT SUBMISSIONS TABLE (Public)
-- ============================================================================
CREATE TABLE IF NOT EXISTS contact_submissions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  email text NOT NULL,
  user_type text,
  subject text NOT NULL,
  message text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE contact_submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can submit contact forms"
  ON contact_submissions FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- ============================================================================
-- PROBLEM REPORTS TABLE (Public)
-- ============================================================================
CREATE TABLE IF NOT EXISTS problem_reports (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_email text NOT NULL,
  reporter_name text NOT NULL,
  issue_type text NOT NULL,
  subject text NOT NULL,
  description text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE problem_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can submit problem reports"
  ON problem_reports FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_profiles_user_type ON profiles(user_type);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);

CREATE INDEX IF NOT EXISTS idx_room_listings_homeowner ON room_listings(homeowner_id);
CREATE INDEX IF NOT EXISTS idx_room_listings_active ON room_listings(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_room_listings_university ON room_listings(closest_university);
CREATE INDEX IF NOT EXISTS idx_room_listings_rent ON room_listings(monthly_rent);

CREATE INDEX IF NOT EXISTS idx_applications_listing ON applications(listing_id);
CREATE INDEX IF NOT EXISTS idx_applications_renter ON applications(renter_id);
CREATE INDEX IF NOT EXISTS idx_applications_status ON applications(status);

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_recipient ON messages(recipient_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_conversations_users ON conversations(user1_id, user2_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message ON conversations(last_message_at DESC);

CREATE INDEX IF NOT EXISTS idx_saved_listings_renter ON saved_listings(renter_id);
CREATE INDEX IF NOT EXISTS idx_saved_listings_listing ON saved_listings(listing_id);

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers for updated_at
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_renter_profiles_updated_at
  BEFORE UPDATE ON renter_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_homeowner_profiles_updated_at
  BEFORE UPDATE ON homeowner_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_room_listings_updated_at
  BEFORE UPDATE ON room_listings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_applications_updated_at
  BEFORE UPDATE ON applications
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to update conversation last_message_at
CREATE OR REPLACE FUNCTION update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations
  SET last_message_at = NEW.created_at
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_conversation_on_new_message
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_timestamp();

-- Function to increment listing view count
CREATE OR REPLACE FUNCTION increment_listing_views(listing_uuid uuid)
RETURNS void AS $$
BEGIN
  UPDATE room_listings
  SET view_count = view_count + 1
  WHERE id = listing_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
