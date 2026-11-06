MARKETPLACE (PHILIPPINES) - SETUP GUIDE
=======================================
This is a SEPARATE website from the school Learning Hub. Put it in its OWN GitHub repository.

Who can see it?
- Browsing is public: anyone in the Philippines (or anywhere) who has the link can see the items.
- To post, add photos, or chat, a person must make a free account (email + password).

FILES
- index.html   the whole app
- config.js    your database settings (you edit this one)
- setup.sql    the database tables, rules and photo storage (you paste this into Supabase)

STEP 1 - GITHUB (new repository)
1. On GitHub, create a NEW repository, for example "marketplace".
2. Upload index.html and config.js to the repository root.
3. Settings > Pages > choose the main branch and root folder > Save.
4. Your site will be at https://YOUR-USERNAME.github.io/marketplace/
   (Open it now. It will say "Connect your database". That is normal.)

STEP 2 - SUPABASE PROJECT
1. supabase.com > sign in with GitHub > New organization > New project.
2. Save the database password. Region: Southeast Asia (Singapore).

STEP 3 - DATABASE
1. Left menu > SQL Editor > New query.
2. Paste ALL of setup.sql and press Run. It should say "Success".
   (It is safe to run again if something went wrong.)

STEP 4 - LOGIN SETTINGS
1. Authentication > Sign In / Providers > Email: make sure Email is enabled.
2. For an easy start, turn OFF "Confirm email". Users can then sign up and use the site right away.
   (If you keep it ON, Supabase sends a confirmation email. The built-in email sender has a low
   limit, so set up your own SMTP before a real launch.)
3. Authentication > URL Configuration:
   Site URL = your website address, e.g. https://YOUR-USERNAME.github.io/marketplace/
   Add the same address under Redirect URLs. (Needed for password reset links.)

STEP 5 - CONNECT THE WEBSITE
1. Project Settings > API Keys: copy the Project URL and the PUBLISHABLE key (starts with sb_publishable_).
   (If you only see "anon", that works too.)  NEVER use the secret or service_role key.
2. On GitHub open config.js > pencil icon > paste the url and key between the quotes.
   Add your email in contact so users can report problems. Commit changes.
3. Wait 1 minute and reload the site. The "Connect your database" screen is gone.

STEP 6 - TRY IT
- Sign up, post an item with photos, then open the site in another browser/phone, sign up as
  another person, and message the seller.

MODERATION (you are the admin)
- See reports: Table Editor > reports.
- Hide a bad listing: Table Editor > listings > set status to "removed".
- Ban a user: Table Editor > profiles > set is_banned to true.
- Delete a user completely: Authentication > Users > delete.

GOOD TO KNOW
- Chat checks for new messages every few seconds. There are no push notifications.
- To change an item's photos, remove the item and post it again.
- The free Supabase plan has limits on storage and bandwidth, and a free project can pause after
  about a week of no use (restore it in the dashboard). Check Supabase's pricing page.
- No payments happen on the site. Tell users to meet in public places and never send money first.
- You are running a public service that stores personal data (emails, names, photos, chats).
  Keep the privacy notice, answer deletion requests, and ask your school or a legal adviser
  about the Philippine Data Privacy Act if this will be used widely.
