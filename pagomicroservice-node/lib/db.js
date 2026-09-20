const { Pool } = require('pg');

function normalizeConnectionString() {
  const jdbc = process.env.SUPABASE_DB_URL || process.env.DATABASE_URL;
  if (!jdbc) return undefined;
  // If comes like jdbc:postgresql://host:port/db?params -> strip jdbc:
  return jdbc.startsWith('jdbc:') ? jdbc.replace(/^jdbc:/, '') : jdbc;
}

const connectionString = normalizeConnectionString();
const hasDb = Boolean(connectionString);

const pool = hasDb
  ? new Pool({
      connectionString,
      // Allow SSL if provided by the provider (e.g., Supabase on prod)
      ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : undefined,
    })
  : null;

async function ensureSchema() {
  // Creates transactions table if it doesn't exist, matching Java entity
  if (!hasDb || !pool) return; // No-op when DB is not configured
  await pool.query(`
    CREATE TABLE IF NOT EXISTS transactions (
      id BIGSERIAL PRIMARY KEY,
      id_client BIGINT NOT NULL,
      id_card BIGINT NOT NULL,
      id_device BIGINT NOT NULL,
      amount NUMERIC NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
    );
  `);
}

module.exports = { pool, ensureSchema, hasDb };
