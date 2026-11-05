Learning Hub - GitHub Pages package

1. Create a new GitHub repository.
2. Upload these files to the repository root (not the folder itself):
   index.html, quiz.html, labs.html, games.html, records.html, market.html
   (marketplace-setup.sql is NOT uploaded to GitHub. You paste it into Supabase.)
3. Go to Settings > Pages, choose your main branch and the root folder, then save.
4. Your site will be at https://YOUR-USERNAME.github.io/REPO-NAME/

All pages must be in the same folder so the navigation links work.

MARKETPLACE (market.html)
- Works right away in DEMO MODE: listings stay on one device.
- To share listings with every student you need a database. Free option: Supabase.
  1. Create a free project at supabase.com (region near the Philippines).
  2. SQL Editor > New query > paste marketplace-setup.sql > Run.
  3. Project Settings > API: copy the Project URL and the public (anon / publishable) key.
  4. On GitHub, edit market.html and paste them into CONFIG = { url: "...", key: "..." }. Commit.
  5. Reload the Marketplace. The banner should say "Connected".
- NEVER paste the service_role / secret key into the page.
- To remove a bad post: Supabase > Table Editor > listings > set status to "removed".

Class record: see Records > Quiz progress. Use Download CSV to keep a permanent copy.
