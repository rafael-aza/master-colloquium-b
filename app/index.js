const express = require('express');
const mysql = require('mysql2/promise');

const app = express();
const port = process.env.PORT || 4000;

// Liveness probe used by the ALB target group health check.
app.get('/health', (req, res) => res.status(200).send('OK'));

// Root route proves the full 3-tier chain: ALB -> EC2 -> RDS.
app.get('/', async (req, res) => {
  try {
    const conn = await mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PWD,
      database: process.env.DB_NAME,
    });
    const [rows] = await conn.query('SELECT NOW() AS db_time, VERSION() AS db_version');
    await conn.end();
    res.json({
      status: 'connected',
      tier: 'app -> database',
      db_time: rows[0].db_time,
      db_version: rows[0].db_version,
    });
  } catch (err) {
    res.status(500).json({ status: 'db_error', error: err.message });
  }
});

if (require.main === module) {
  app.listen(port, () => {
    console.log(`3-tier demo app listening on port ${port}`);
  });
}

module.exports = app;
