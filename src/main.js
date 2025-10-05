import { authService } from './lib/auth';
import { profileService } from './lib/profiles';
import { listingService } from './lib/listings';
import { applicationService } from './lib/applications';
import { messageService } from './lib/messages';
import { savedListingService } from './lib/savedListings';
import { contactService } from './lib/contact';

window.RoomThere = {
  auth: authService,
  profiles: profileService,
  listings: listingService,
  applications: applicationService,
  messages: messageService,
  savedListings: savedListingService,
  contact: contactService,
};

console.log('RoomThere API initialized and available at window.RoomThere');
