const request = require('supertest');
const { expect } = require('chai');
const { pool } = require('../lib/db');

// Load env for tests
require('dotenv').config();

let app;

before(async () => {
  app = require('../dev');
});

after(async () => {
  await pool.end();
});

describe('POST /api/payments', () => {
  const hasDb = Boolean(process.env.DATABASE_URL || process.env.SUPABASE_DB_URL);

  (hasDb ? it : it.skip)('creates a transaction with valid payload', async () => {
    const res = await request(app)
      .post('/api/payments')
      .send({ idClient: 1, idCard: 2, idDevice: 3, amount: 10.5 });

    expect(res.statusCode).to.equal(201);
    expect(res.body).to.have.property('id');
    expect(res.body).to.include({ idClient: 1, idCard: 2, idDevice: 3 });
    expect(res.body).to.have.property('createdAt');
  });

  it('validates missing fields', async () => {
    const res = await request(app).post('/api/payments').send({});
    expect(res.statusCode).to.equal(400);
    expect(res.body).to.have.property('idClient');
    expect(res.body).to.have.property('idCard');
    expect(res.body).to.have.property('idDevice');
    expect(res.body).to.have.property('amount');
  });
});
