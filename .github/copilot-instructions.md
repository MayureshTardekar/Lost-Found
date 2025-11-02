### Lost & Found — Copilot Instructions

This file gives short, actionable guidance for AI coding agents working on this repository so they can be productive immediately.

- Project type: small Express-based Node.js web app that was migrated to a client-side/localStorage prototype. The server exists (server.js) but most DB logic is commented out and client-side `script.js` now uses localStorage as the primary data source.

- Key files:

  - `server.js` — Express server that serves static HTML and some API endpoints; still wired for session-based auth, multer file uploads, and MySQL queries.
  - `script.js` — Client-side app logic using `localStorage` as the authoritative data source for users, items, auth state, and sample data initialization.
  - `db.js` and `schema.sql` — Database connection and schema are present but commented out; they show the original MySQL schema and connection code.
  - `package.json` — start/dev scripts: `npm start` (node server.js) and `npm run dev` (nodemon).
  - `uploads/` — folder for multer file uploads. `server.js` serves this directory via static middleware (`express.static(__dirname)`).

- High-level architecture / why things are the way they are:

  - Originally a server-backed Express + MySQL app (see `db.js` & `schema.sql`). At some point the project shifted to a purely client-side demo using `localStorage` (see `script.js`). Both modes co-exist in the repo:
    - Server-side: `server.js` exposes pages and APIs and expects a working MySQL `db` module.
    - Client-side: `script.js` provides full UX backed by `localStorage` and sample data. Frontend pages (HTML files) call into `script.js` and do not require a running DB.
  - When editing code, be careful to preserve both modes or clearly convert the repo to a single mode. The current runnable demo (without DB) is the `localStorage` mode.

- Developer workflows (how to run & debug):

  - Quick demo (no DB):
    1. Install deps: `npm install`
    2. Start server: `npm run dev` (requires nodemon) or `npm start`.
    3. Open `http://localhost:3000` in a browser. The frontend will seed localStorage automatically via `script.js`.
  - Server + MySQL (not currently wired):
    - `db.js` contains commented connection details. To re-enable server-backed DB mode:
      1. Restore `db.js` connection block and fill in MySQL credentials.
      2. Import `schema.sql` into a MySQL instance to create `users` and `items` tables.
      3. Start the server (`npm start`). `server.js` API routes will then use MySQL.

- Project-specific conventions & patterns:

  - Dual-mode data layer: expect two sources of truth — the commented server-side MySQL code and the active client-side `localStorage` logic in `script.js`. Before making changes that affect data persistence, decide which mode you're targeting and document it in the pull request.
  - Sessions vs localStorage: `server.js` uses `express-session` and sets `req.session.userId` on login; `script.js` uses `localStorage.currentUser`. They are separate; do not assume changes to one automatically affect the other.
  - File uploads: `server.js` uses `multer` to write files into `uploads/` and saves `/uploads/<filename>` into the DB. The frontend `localStorage` items do not store image paths; UI uses placeholder images in `displayItems()`.
  - Static serving: `app.use(express.static(__dirname))` means all top-level files (HTML/JS/CSS) are served from project root. When adding static assets, put them at the top-level or adjust the static middleware.

- Integration points & external dependencies:

  - Express server (`server.js`) depends on `express`, `express-session`, `bcryptjs`, `multer`, and optionally `mysql2` if `db.js` is re-enabled.
  - `package.json` lists `ejs` but templates are not used — HTML files are static. Check before adding EJS templates; no view engine is currently configured.

- Typical small tasks and examples (copy-editable patterns):

  - Add a new API endpoint that returns filtered items:
    - Edit `server.js`; follow existing pattern for `/api/items` and use `db.query(...)` when DB mode is enabled. For local demo, modify `script.js` and add a client-side filtering function used by the pages.
  - Re-enable DB-backed login:
    - Uncomment and configure `db.js`.
    - Ensure passwords stored in DB are bcrypt hashes (existing `server.js` uses `bcrypt.compare` and `bcrypt.hash`).
  - Add image support to the client mode:
    - Update `script.js`'s `initializeData()` to include `image_url` fields and change `displayItems()` to use `item.image_url` when present.

- Tests & linting:

  - There are no automated tests or linters configured. Keep changes small and test manually by running `npm run dev` and using the browser console. Prefer adding small unitable modules before adding tests.

- Safety & merge guidance for AI agents:
  - Don't remove the commented `db.js` and `schema.sql` unless the repository owner asked to permanently drop server-backed mode.
  - If you change persistence (switching fully to MySQL or fully to localStorage), update `README.md` (create if missing) to explain the chosen mode and how to run the app.
  - Keep sessions vs localStorage differences visible in code comments and PR descriptions.

If anything here is unclear or you'd like the file to be expanded with specific coding conventions (naming, formatting, commit message style), tell me which sections to iterate on.
