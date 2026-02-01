import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { Pool } from "pg";
import { v4 as uuidv4 } from "uuid";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const pool = new Pool({
  host: process.env.PG_HOST,
  port: Number(process.env.PG_PORT || 5432),
  database: process.env.PG_DB,
  user: process.env.PG_USER,
  password: String(process.env.PG_PASSWORD || ""),
});

app.get("/health", (req, res) => res.json({ ok: true }));

async function initDb() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS kiris (
      id UUID PRIMARY KEY,
      category TEXT NOT NULL,
      amount NUMERIC(12,2) NOT NULL,
      note TEXT DEFAULT '',
      tx_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS shygys (
      id UUID PRIMARY KEY,
      category TEXT NOT NULL,
      amount NUMERIC(12,2) NOT NULL,
      note TEXT DEFAULT '',
      tx_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);
}

// ---------- GET ----------
app.get("/kiris", async (req, res) => {
  const { rows } = await pool.query("SELECT * FROM kiris ORDER BY tx_date DESC");
  res.json(rows);
});

app.get("/shygys", async (req, res) => {
  const { rows } = await pool.query("SELECT * FROM shygys ORDER BY tx_date DESC");
  res.json(rows);
});

// ---------- POST ----------
app.post("/kiris", async (req, res) => {
  const id = uuidv4();
  const { category, amount, note, tx_date } = req.body;

  const { rows } = await pool.query(
    `INSERT INTO kiris (id, category, amount, note, tx_date)
     VALUES ($1,$2,$3,$4,$5)
     RETURNING *`,
    [id, category, amount, note ?? "", tx_date ?? new Date().toISOString()]
  );

  res.json(rows[0]);
});

app.post("/shygys", async (req, res) => {
  const id = uuidv4();
  const { category, amount, note, tx_date } = req.body;

  const { rows } = await pool.query(
    `INSERT INTO shygys (id, category, amount, note, tx_date)
     VALUES ($1,$2,$3,$4,$5)
     RETURNING *`,
    [id, category, amount, note ?? "", tx_date ?? new Date().toISOString()]
  );

  res.json(rows[0]);
});

// ---------- PUT (UPDATE) ----------
app.put("/kiris/:id", async (req, res) => {
  const { id } = req.params;
  const { category, amount, note, tx_date } = req.body;

  const { rows } = await pool.query(
    `UPDATE kiris
     SET category=$1, amount=$2, note=$3, tx_date=$4
     WHERE id=$5
     RETURNING *`,
    [category, amount, note ?? "", tx_date ?? new Date().toISOString(), id]
  );

  res.json(rows[0]);
});

app.put("/shygys/:id", async (req, res) => {
  const { id } = req.params;
  const { category, amount, note, tx_date } = req.body;

  const { rows } = await pool.query(
    `UPDATE shygys
     SET category=$1, amount=$2, note=$3, tx_date=$4
     WHERE id=$5
     RETURNING *`,
    [category, amount, note ?? "", tx_date ?? new Date().toISOString(), id]
  );

  res.json(rows[0]);
});

// ---------- DELETE ----------
app.delete("/kiris/:id", async (req, res) => {
  await pool.query("DELETE FROM kiris WHERE id=$1", [req.params.id]);
  res.json({ success: true });
});

app.delete("/shygys/:id", async (req, res) => {
  await pool.query("DELETE FROM shygys WHERE id=$1", [req.params.id]);
  res.json({ success: true });
});

const PORT = Number(process.env.PORT || 8080);

initDb()
  .then(() => {
    console.log("✅ DB init OK");
    app.listen(PORT, () => console.log(`🚀 Backend running on http://localhost:${PORT}`));
  })
  .catch((e) => {
    console.error("❌ DB init failed:", e);
    process.exit(1);
  });
