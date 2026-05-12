# NeuroVision-AI — Database

This folder contains Prisma schema, seed scripts, and helper scripts for local development.

Prerequisites
- Node 18+ (for ts-node) or install dependencies with `npm install` in this folder
- PostgreSQL database available and `DATABASE_URL` set in environment

Setup (local)

1. From repository root, set the `DATABASE_URL` environment variable (do not commit):

```powershell
# Windows PowerShell example
$env:DATABASE_URL = "postgresql://neuro_user:strong_password@localhost:5432/neurovision_ai"
```

2. Install dependencies (inside `database`):

```bash
cd database
npm install
```

3. Generate client & run migrations (dev):

```bash
npm run generate
npm run migrate:dev
```

4. Seed demo data:

```bash
npm run seed
```

5. Run Prisma Studio:

```bash
npm run studio
```

Notes & recommendations
- Create a dedicated, least-privileged DB user for application access.
- Use a strong password and store in a safe secret manager for production.
- For CI / production use `npx prisma migrate deploy` instead of `migrate dev`.
- The `seed.ts` uses `bcryptjs` to hash demo passwords. Replace with proper secrets in production.
