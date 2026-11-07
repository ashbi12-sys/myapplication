LEARNING HUB MARKETPLACE — CLEANED EXISTING PROJECT PACKAGE
==========================================================

This package is designed for your EXISTING GitHub repository and EXISTING
Supabase project. It does not create a new repository or Supabase project.

WHAT WAS CLEANED UP
-------------------
- index.html and market.html now use the same canonical application code.
- Removed the conflicting old setup.sql and marketplace-setup.sql files. Those
  scripts used seller_id and could conflict with your actual listings.user_id.
- Removed the listings -> profiles embedded relationship from marketplace
  queries. Seller profiles are fetched separately by profiles.id = listings.user_id,
  so the original schema-cache relationship error no longer blocks browsing.
- Kept conversations.seller_id separate; it belongs to the conversations table.
- Added country_code and currency_code support to listings and the listing form.
- The app displays each listing in its own currency. It does NOT convert currencies.

FILES
-----
index.html                       Marketplace entry page
market.html                      Same Marketplace page (kept in sync)
config.js                        Existing Supabase URL and public anon key
migration-existing-supabase.sql  Migration for the existing database
README.txt                       This guide

INTERNATIONAL LISTINGS
----------------------
Sellers can choose a country, currency, state/province/region, and city.
Listings are searchable by country. Supported currency choices include PHP,
USD, EUR, GBP, CAD, AUD, SGD, HKD, JPY, KRW, CNY, INR, IDR, MYR, THB, VND,
AED, SAR, NZD, CHF, SEK, NOK, DKK, ZAR, BRL, and MXN.

Prices remain in the seller's selected currency. No automatic exchange-rate
conversion, payment processing, customs calculation, or shipping integration
is included in this package.

INSTALLATION
------------
1. Make a backup/download of your current GitHub repository before replacing files.
2. Extract this ZIP.
3. In your existing repository, replace the root index.html and market.html
   with the matching files from this package. Keep games.html, labs.html,
   quiz.html, records.html, shared.css, and other unrelated Learning Hub files.
4. Keep your existing config.js values. The included config.js is copied from
   your uploaded repository; do not publish a service_role or secret key.
5. Review migration-existing-supabase.sql, then run it in the EXISTING Supabase
   project's SQL Editor. It does not drop tables, listings, users, or existing
   listings RLS policies. It adds country_code and currency_code and prepares
   listing photo storage policies.
6. In Supabase Authentication > URL Configuration, ensure your GitHub Pages
   site URL and redirect URLs are allowed.
7. Commit the updated files to your existing GitHub repository and wait for
   GitHub Pages deployment.

IMPORTANT DATABASE REQUIREMENTS
-------------------------------
The current frontend expects these listings columns:
id, user_id, title, description, price, currency_code, country_code,
category, condition, region, city, photos, thumbs, status, created_at.
It also expects profiles columns: id, display_name, region, city, created_at.
Messaging and moderation features expect the existing profiles, conversations,
messages, blocks, and reports tables and the conversation foreign keys named
conversations_buyer_fk and conversations_seller_fk.

The migration deliberately does not invent missing supporting tables or alter
unknown column definitions. If your existing schema is missing one of these
requirements, that feature needs a matching migration before it can work.

SECURITY
--------
- Public visitors can browse only rows permitted by your existing SELECT RLS policy.
- Authenticated users can create/edit/delete only rows allowed by your existing
  user_id ownership policies.
- Never put a Supabase service_role or secret key in config.js.
- Keep RLS enabled. Do not run the old setup.sql from earlier packages.

INTERNATIONAL LIMITATIONS
-------------------------
International country and currency fields support global listing metadata and
browsing. This is not yet a full international commerce platform: payment
processing, escrow, FX conversion, carrier rates, customs, tax, and dispute
resolution integrations must be added separately before handling transactions.
