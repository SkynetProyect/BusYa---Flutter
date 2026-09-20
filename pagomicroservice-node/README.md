# Pago Microservice (Node.js)

Node.js reimplementation of the Spring Boot payment microservice for easy deploy on Vercel. Provides `POST /api/payments` to create a transaction record.

## Environment

- `DATABASE_URL`: Postgres connection string (preferred)
- `SUPABASE_DB_URL`: Optional jdbc-style URL; if used, the `jdbc:` prefix is stripped automatically.
- `DB_SSL`: Set to `true` if your Postgres requires SSL.

See `.env.example`.

## Run locally

```bash
cd pagomicroservice-node
cp .env.example .env # fill your DB connection string
npm install
npm run dev
# POST http://localhost:3000/api/payments
```

## Test

```bash
npm test
```

## Deploy to Vercel

- Push this folder as its own repo, or set project Root Directory to `pagomicroservice-node` in Vercel.
- Add environment variables in Vercel Project Settings (same as above).
- Deploy; Vercel will detect serverless function at `api/payments.js`.
