# Crown Security — Backend

Quick notes to run and reset the backend locally.

## Prerequisites
- Node.js (>=16 recommended)
- npm
- PostgreSQL (or use the included Docker Compose service)

The backend reads DB connection values from `backend/.env`. Example values used in this repo:

```
DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=crown_security
DB_USER=app_user
DB_PASS=app_pass
```

## Using Docker Compose (Postgres)
If you prefer running Postgres with Docker, from the repo root run (Windows cmd example):

```cmd
cd C:\Users\Admin\Downloads\Archive\projects\crown_security
docker-compose up -d
```

This repository includes a `docker-compose.yml` that exposes Postgres on `5432`.

## Reset the database (drop, create, migrate, seed)
From the `backend` folder run:

```cmd
cd C:\Users\Admin\Downloads\Archive\projects\crown_security\backend
npm run db:reset
```

- This runs the migrations and seeds. A migration has been added to create the Postgres extension `uuid-ossp` so seeders that call `uuid_generate_v4()` succeed.

## Start the backend (development)
Run the dev script (uses nodemon):

```cmd
cd C:\Users\Admin\Downloads\Archive\projects\crown_security\backend
npm run dev
```

You should see logs like `DB connected` and `API listening on :8080` when the server starts.

## Troubleshooting
- If `npm run db:reset` fails with `function uuid_generate_v4() does not exist`, ensure the `uuid-ossp` extension can be created by the DB user. The migration `migrations/20250821230720-create-uuid-extension.js` runs `CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`.
- If running on a managed DB where you cannot create extensions, ask your DBA or manually enable the extension with an admin account.
- If the extension migration fails due to permissions, you can manually run as a superuser:

```sql
-- connect with a superuser and run:
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

## Admin test user
- A default ADMIN user is seeded for testing the Admin UI.
- Default credentials:
	- Email: `admin@crown.local`
	- Password: `Pass@123`
- You can override via env vars before seeding: `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `ADMIN_NAME`, `ADMIN_PHONE`.

## Notes
- The Flutter app entrypoint is `app/crown_security/lib/main.dart`.
- Environment variables are loaded from `.env` (see `backend/.env`).

If you'd like, I can add a top-level README that documents both mobile and backend start steps together.
