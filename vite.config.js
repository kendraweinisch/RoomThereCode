import { defineConfig } from 'vite';

export default defineConfig({
  root: '.',
  publicDir: 'public',
  build: {
    outDir: 'dist',
    rollupOptions: {
      input: {
        main: '/index.html',
        'sign-in': '/sign-in.html',
        'create-profile-homeowner': '/create-profile-homeowner.html',
        'create-profile-renter': '/create-profile-renter.html',
        'dashboard-homeowner-empty': '/dashboard-homeowner-empty.html',
        'dashboard-homeowner-full': '/dashboard-homeowner-full.html',
        'dashboard-renter-empty': '/dashboard-renter-empty.html',
        'dashboard-renter-full': '/dashboard-renter-full.html',
        'available-rooms': '/available-rooms.html',
        'messages-empty': '/messages-empty.html',
        'messages-full': '/messages-full.html',
        'get-verified': '/get-verified.html',
        'payment': '/payment.html',
        'room-application-form': '/room-application-form.html',
        'profile-homeowner-public': '/profile-homeowner-public.html',
        'public-profile-renter': '/public-profile-renter.html',
        'advanced-search': '/advanced-search.html',
        'legal': '/legal.html',
        'privacy-policy': '/privacy-policy.html',
        'terms': '/terms.html',
      },
    },
  },
  server: {
    port: 3000,
  },
});
