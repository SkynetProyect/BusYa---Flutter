// Local Express server for development/testing
const express = require('express');
const bodyParser = require('body-parser');
const dotenv = require('dotenv');
const paymentsHandler = require('./api/payments');

dotenv.config();

const app = express();
app.use(bodyParser.json());

// Adapter: Express -> Vercel handler signature
app.post('/api/payments', async (req, res) => paymentsHandler(req, res));

const port = process.env.PORT || 3000;

if (require.main === module) {
  app.listen(port, () => {
    console.log(`pagomicroservice-node listening on http://localhost:${port}`);
  });
}

module.exports = app;
