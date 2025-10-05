# RoomThere Backend Documentation

## Overview

This is a complete backend implementation for the RoomThere platform - an intergenerational housing platform that connects homeowners (typically seniors) with renters (graduate students and young professionals).

## Tech Stack

- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth (email/password)
- **Client Library**: @supabase/supabase-js
- **Real-time**: Supabase Realtime (for messaging)

## Database Schema

### Tables

1. **profiles** - Core user profiles for both homeowners and renters
2. **renter_profiles** - Extended profile data for renters
3. **homeowner_profiles** - Extended profile data for homeowners
4. **room_listings** - Available room listings
5. **applications** - Rental applications from renters
6. **conversations** - Message conversation threads
7. **messages** - Individual messages between users
8. **saved_listings** - Saved rooms for renters
9. **contact_submissions** - Contact form submissions
10. **problem_reports** - Problem/safety reports

### Key Features

- **Row Level Security (RLS)** enabled on all tables
- Users can only access their own data
- Homeowners can view renter profiles who applied to their listings
- Automatic timestamp updates with triggers
- Message conversation timestamps auto-update
- Listing view count tracking

## API Services

All services are available via the global `window.RoomThere` object or can be imported directly.

### Authentication Service (`auth.js`)

```javascript
import { authService } from './lib/auth';

// Sign up a new user
await authService.signUp(email, password, {
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  userType: 'renter', // or 'homeowner'
  phone: '555-1234'
});

// Sign in
await authService.signIn(email, password);

// Sign out
await authService.signOut();

// Get current user
const user = await authService.getCurrentUser();

// Get session
const session = await authService.getSession();

// Listen to auth changes
authService.onAuthStateChange((event, session) => {
  console.log('Auth event:', event, session);
});
```

### Profile Service (`profiles.js`)

```javascript
import { profileService } from './lib/profiles';

// Get user profile
const profile = await profileService.getProfile(userId);

// Update profile
await profileService.updateProfile(userId, {
  first_name: 'Jane',
  bio: 'Graduate student at UCSD'
});

// Create renter profile
await profileService.createRenterProfile(userId, {
  occupationType: 'grad-student',
  schoolOrEmployer: 'UC San Diego',
  personalDescription: 'Quiet, clean, and responsible',
  desiredMoveInDate: '2025-09-01',
  preferredLeaseLength: '12 months',
  preferences: { pets: false, smoking: false },
  helpTypesOffered: ['grocery-shopping', 'technology-help']
});

// Create homeowner profile
await profileService.createHomeownerProfile(userId, {
  address: '123 Main St',
  city: 'San Diego',
  state: 'CA',
  zipCode: '92101',
  hasPets: true,
  petDetails: { type: 'dog', breed: 'Golden Retriever' }
});

// Get full profile (includes extended profile)
const fullProfile = await profileService.getFullProfile(userId);
```

### Listing Service (`listings.js`)

```javascript
import { listingService } from './lib/listings';

// Create a new listing
const listing = await listingService.createListing({
  title: 'Cozy Room in North Park',
  description: 'Private room with shared bathroom',
  roomType: 'private',
  bathroomType: 'shared',
  monthlyRent: 850,
  availableDate: '2025-09-01',
  amenities: ['wifi', 'parking', 'laundry'],
  closestUniversity: 'SDSU',
  distanceToUniversity: '1.2 miles',
  helpDiscountAmount: 100,
  helpTypesNeeded: ['grocery-shopping'],
  helpDescription: 'Light help with weekly grocery shopping',
  photos: []
});

// Get all active listings with filters
const listings = await listingService.getAllListings({
  university: 'SDSU',
  maxPrice: 1000,
  hasHelpDiscount: true
});

// Get specific listing
const listing = await listingService.getListing(listingId);

// Get my listings (homeowner only)
const myListings = await listingService.getMyListings();

// Update listing
await listingService.updateListing(listingId, {
  monthly_rent: 900,
  is_active: true
});

// Delete listing
await listingService.deleteListing(listingId);

// Increment view count
await listingService.incrementViewCount(listingId);

// Get listing statistics
const stats = await listingService.getListingStats(homeownerId);
// Returns: { totalViews, totalApplications, newApplications }
```

### Application Service (`applications.js`)

```javascript
import { applicationService } from './lib/applications';

// Create application (renter only)
const application = await applicationService.createApplication(
  listingId,
  'I am very interested in this room...'
);

// Update application status (homeowner only)
await applicationService.updateApplicationStatus(applicationId, 'accepted');

// Get my applications (renter)
const myApplications = await applicationService.getMyApplications();

// Get applications for my listings (homeowner)
const applications = await applicationService.getApplicationsForMyListings();

// Get applications for specific listing
const listingApps = await applicationService.getApplicationsForListing(listingId);
```

### Message Service (`messages.js`)

```javascript
import { messageService } from './lib/messages';

// Get or create conversation
const conversation = await messageService.getOrCreateConversation(otherUserId);

// Get all conversations
const conversations = await messageService.getConversations();
// Returns conversations with partner info and unread count

// Get messages in a conversation
const messages = await messageService.getMessages(conversationId);

// Send a message
const message = await messageService.sendMessage(
  conversationId,
  recipientId,
  'Hello! I am interested in your room.'
);

// Mark messages as read
await messageService.markMessagesAsRead(conversationId);

// Get unread message count
const unreadCount = await messageService.getUnreadCount();

// Subscribe to new messages (real-time)
const subscription = messageService.subscribeToMessages(conversationId, (payload) => {
  console.log('New message:', payload.new);
});

// Unsubscribe from messages
messageService.unsubscribeFromMessages(conversationId);
```

### Saved Listing Service (`savedListings.js`)

```javascript
import { savedListingService } from './lib/savedListings';

// Save a listing
await savedListingService.saveListing(listingId);

// Unsave a listing
await savedListingService.unsaveListing(listingId);

// Get all saved listings
const savedListings = await savedListingService.getSavedListings();

// Check if listing is saved
const isSaved = await savedListingService.isListingSaved(listingId);
```

### Contact Service (`contact.js`)

```javascript
import { contactService } from './lib/contact';

// Submit contact form
await contactService.submitContactForm({
  name: 'John Doe',
  email: 'john@example.com',
  userType: 'renter',
  subject: 'Question about the platform',
  message: 'I have a question...'
});

// Submit problem report
await contactService.submitProblemReport({
  name: 'John Doe',
  email: 'john@example.com',
  issueType: 'safety',
  subject: 'Safety concern',
  description: 'I want to report...'
});
```

## Using the API in HTML

The API is automatically available via the global `window.RoomThere` object:

```html
<script type="module" src="/src/main.js"></script>
<script>
  // Wait for the API to load
  window.addEventListener('load', async () => {
    try {
      // Sign in
      await window.RoomThere.auth.signIn('user@example.com', 'password');

      // Get listings
      const listings = await window.RoomThere.listings.getAllListings();
      console.log('Listings:', listings);

      // Get current user profile
      const user = await window.RoomThere.auth.getCurrentUser();
      const profile = await window.RoomThere.profiles.getProfile(user.id);
      console.log('Profile:', profile);
    } catch (error) {
      console.error('Error:', error);
    }
  });
</script>
```

## Environment Variables

The following environment variables are required (already configured in `.env`):

```env
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

## Security

- **Row Level Security (RLS)** is enabled on all tables
- Users can only access their own data
- Homeowners can only manage their own listings
- Renters can only create applications for their own account
- Messages are only visible to sender and recipient
- Public forms (contact, problem reports) can be submitted without authentication

## Database Functions

### `increment_listing_views(listing_uuid)`

Safely increments the view count for a listing.

```sql
SELECT increment_listing_views('listing-uuid-here');
```

## Triggers

- `update_updated_at_column` - Auto-updates `updated_at` timestamp on all relevant tables
- `update_conversation_on_new_message` - Updates conversation's `last_message_at` when new message is sent

## Getting Started

1. Ensure your `.env` file has the correct Supabase credentials
2. Run `npm install` to install dependencies
3. Run `npm run build` to build the project
4. The API services are ready to use!

## Example User Flow

### Renter Journey

```javascript
// 1. Sign up
await RoomThere.auth.signUp('renter@example.com', 'password', {
  firstName: 'Alex',
  lastName: 'Johnson',
  email: 'renter@example.com',
  userType: 'renter'
});

// 2. Complete renter profile
await RoomThere.profiles.createRenterProfile(userId, {
  occupationType: 'grad-student',
  schoolOrEmployer: 'SDSU',
  personalDescription: 'Responsible graduate student',
  desiredMoveInDate: '2025-09-01',
  preferredLeaseLength: '12 months'
});

// 3. Browse listings
const listings = await RoomThere.listings.getAllListings();

// 4. Save interesting listings
await RoomThere.savedListings.saveListing(listingId);

// 5. Apply to a listing
await RoomThere.applications.createApplication(listingId, 'I am interested...');

// 6. Message homeowner
const conversation = await RoomThere.messages.getOrCreateConversation(homeownerId);
await RoomThere.messages.sendMessage(conversation.id, homeownerId, 'Hello!');
```

### Homeowner Journey

```javascript
// 1. Sign up
await RoomThere.auth.signUp('homeowner@example.com', 'password', {
  firstName: 'Margaret',
  lastName: 'Robinson',
  email: 'homeowner@example.com',
  userType: 'homeowner'
});

// 2. Complete homeowner profile
await RoomThere.profiles.createHomeownerProfile(userId, {
  address: '123 Park Blvd',
  city: 'San Diego',
  state: 'CA',
  zipCode: '92101',
  hasPets: false
});

// 3. Create listing
await RoomThere.listings.createListing({
  title: 'Cozy Room Near SDSU',
  description: 'Private room in quiet neighborhood',
  roomType: 'private',
  bathroomType: 'shared',
  monthlyRent: 850,
  availableDate: '2025-09-01',
  closestUniversity: 'SDSU',
  distanceToUniversity: '1.2 miles',
  helpDiscountAmount: 100,
  helpTypesNeeded: ['grocery-shopping']
});

// 4. View applications
const applications = await RoomThere.applications.getApplicationsForMyListings();

// 5. Accept/reject applications
await RoomThere.applications.updateApplicationStatus(appId, 'accepted');

// 6. Message renters
const conversations = await RoomThere.messages.getConversations();
```

## Support

For issues or questions, please contact RoomThere support or file an issue in the repository.
