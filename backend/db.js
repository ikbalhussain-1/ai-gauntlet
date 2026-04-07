const Database = require("better-sqlite3");
const path = require("path");

const dbPath = process.env.DATABASE_URL
  ? process.env.DATABASE_URL.replace("sqlite:///", "")
  : path.join(__dirname, "../reviews.db");

const db = new Database(dbPath);

db.exec(`
  CREATE TABLE IF NOT EXISTS uploads (
    upload_id TEXT PRIMARY KEY,
    filename TEXT,
    row_count INTEGER,
    status TEXT DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS reviews (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    upload_id TEXT NOT NULL,
    review_id TEXT,
    product TEXT,
    review_text TEXT,
    date TEXT,
    theme TEXT,
    sentiment TEXT,
    key_phrases TEXT,
    analysed_at DATETIME,
    FOREIGN KEY (upload_id) REFERENCES uploads(upload_id)
  );
`);

module.exports = db;
