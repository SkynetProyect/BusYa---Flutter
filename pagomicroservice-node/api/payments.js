// Vercel Serverless Function for POST /api/payments
const Joi = require('joi');
const { pool, ensureSchema, hasDb } = require('../lib/db');

const schema = Joi.object({
  idClient: Joi.number().integer().required(),
  idCard: Joi.number().integer().required(),
  idDevice: Joi.number().integer().required(),
  amount: Joi.number().positive().greater(0).required(),
});

let nextId = 1; // in-memory fallback id counter

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const body = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : req.body || {};
    const { value, error } = schema.validate(body, { abortEarly: false, stripUnknown: true });

    if (error) {
      const errors = {};
      for (const detail of error.details) {
        const key = detail.path.join('.') || 'body';
        errors[key] = detail.message;
      }
      return res.status(400).json(errors);
    }

    const { idClient, idCard, idDevice, amount } = value;

    if (!hasDb) {
      const txn = {
        id: nextId++,
        idClient,
        idCard,
        idDevice,
        amount: amount.toString(),
        createdAt: new Date().toISOString(),
      };
      return res.status(201).json(txn);
    }

    await ensureSchema();
    const insert = `
      INSERT INTO transactions (id_client, id_card, id_device, amount)
      VALUES ($1, $2, $3, $4)
      RETURNING id, id_client AS "idClient", id_card AS "idCard", id_device AS "idDevice", amount::text AS amount, created_at AS "createdAt";
    `;

    const { rows } = await pool.query(insert, [idClient, idCard, idDevice, amount]);
    return res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
};
