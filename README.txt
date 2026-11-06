LEARNING HUB MARKETPLACE — EXISTING PROJECT PACKAGE
===================================================

This package adapts the Marketplace app you uploaded to the existing Supabase
listings ownership column `user_id`. It does NOT ask you to create a new
GitHub repository or a new Supabase project.

FILES
-----
market.html
  Marketplace website. Listing ownership uses listings.user_id. Conversation
  records continue to use conversations.seller_id, because that is a separate
  table/relationship in the app.

config.js
  Put your existing Supabase Project URL and PUBLIC publishable/anon key here.
  Never put a service_role key or secret key in a browser file.

migration-existing-supabase.sql
  Narrow compatibility/security migration. It preserves existing listing
  policies and data. It sets the user_id default, adds an owner index, removes
  TRUNCATE/REFERENCES/TRIGGER privileges from authenticated on listings, and
  prepares the listing-photos storage bucket and owner-folder policies.

IMPORTANT DATABASE COMPATIBILITY NOTE
-------------------------------------
The supplied policy results confirm that public.listings has `user_id` and
`status`, and that four RLS policies already exist. The actual full column list
was not supplied, so this package does not attempt to create or rename the
remaining listing columns, profiles, conversations, messages, or reports.
The app expects the listings fields used in its forms and display:
  id, user_id, title, description, price, category, condition, region, city,
  photos, thumbs, status, created_at
It also expects the existing supporting tables/relations used by the original
Marketplace package (profiles, conversations, messages, blocks, reports) and
an Auth-linked profiles record for each user. Verify those structures against
this project's schema before enabling the related features.

INSTALLATION
------------
1. Extract this ZIP.
2. Copy market.html and config.js into the existing GitHub repository location
   where the current Marketplace page is hosted. Keep unrelated Learning Hub
   files unchanged.
3. Edit config.js. Enter the existing Supabase Project URL and PUBLIC key.
4. Review migration-existing-supabase.sql. It is designed to preserve the four
   known listings policies. Run it in Supabase SQL Editor only if the referenced
   tables/storage schema are present and the statements match your project.
5. Configure Supabase Auth URL settings to include your existing GitHub Pages
   site URL and redirect URL.
6. Commit the files and open the Marketplace page.

CONFIGURATION EXAMPLE
---------------------
window.MARKET_CONFIG = {
  url: "https://YOUR-PROJECT-REF.supabase.co",
  key: "YOUR_PUBLIC_PUBLISHABLE_OR_ANON_KEY",
  contact: ""
};

NOTES
-----
- Existing product listings count was reported as 0, so there are no listing
  rows to migrate at the time of inspection.
- Existing Auth users are not deleted or recreated by this package.
- Existing RLS policy names and expressions are preserved.
- Do not run the old setup.sql from the uploaded ZIP on the existing project:
  it creates a different listings ownership model using seller_id.
- The app sends user_id = the authenticated user's UUID when creating a listing.
- The public key is safe to use in the browser only when RLS and grants are
  correctly configured. Never expose service_role/secret keys.


INDEX.HTML / DEPLOYMENT NOTE
----------------------------
This package includes BOTH index.html and market.html. They contain the same
international marketplace application so either filename can serve as the
marketplace entry page.

IMPORTANT FOR YOUR EXISTING REPOSITORY:
Your repository already has its own root index.html for the Learning Hub. Do NOT
overwrite that homepage. Upload these marketplace files into a folder named
marketplace/ in your repository. The marketplace will then be available at:
https://ashbi12-sys.github.io/myapplication/marketplace/

Keep the existing root index.html and other Learning Hub files unchanged.
