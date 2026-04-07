const express = require("express");
const multer = require("multer");
const { parse } = require("csv-parse/sync");
const { v4: uuidv4 } = require("uuid");
const db = require("../db");

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

router.post("/", upload.single("file"), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: "No file uploaded." });
  }

  const { originalname, mimetype, buffer } = req.file;

  // Validate file type by extension and mimetype
  const isCsvName = originalname.toLowerCase().endsWith(".csv");
  const isCsvMime = mimetype === "text/csv" || mimetype === "application/csv" || mimetype === "application/vnd.ms-excel";
  if (!isCsvName && !isCsvMime) {
    return res.status(400).json({ error: "Invalid file type. Please upload a CSV file." });
  }

  let rows;
  try {
    rows = parse(buffer.toString("utf-8"), {
      columns: true,
      skip_empty_lines: true,
      trim: true,
    });
  } catch (err) {
    return res.status(400).json({ error: "Failed to parse CSV: " + err.message });
  }

  if (rows.length === 0) {
    return res.status(400).json({ error: "CSV file is empty." });
  }

  const requiredColumns = ["review_id", "product", "review_text", "date"];
  const headers = Object.keys(rows[0]);
  const missing = requiredColumns.filter((c) => !headers.includes(c));
  if (missing.length > 0) {
    return res.status(400).json({ error: `Missing required columns: ${missing.join(", ")}` });
  }

  const upload_id = uuidv4();

  const insertUpload = db.prepare(
    "INSERT INTO uploads (upload_id, filename, row_count, status) VALUES (?, ?, ?, 'pending')"
  );
  const insertReview = db.prepare(
    "INSERT INTO reviews (upload_id, review_id, product, review_text, date) VALUES (?, ?, ?, ?, ?)"
  );

  const insertAll = db.transaction(() => {
    insertUpload.run(upload_id, originalname, rows.length);
    for (const row of rows) {
      insertReview.run(upload_id, row.review_id, row.product, row.review_text, row.date);
    }
  });

  insertAll();

  return res.json({ upload_id, count: rows.length });
});

module.exports = router;
