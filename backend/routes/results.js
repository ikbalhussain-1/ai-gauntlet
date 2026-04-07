const express = require("express");
const db = require("../db");

const router = express.Router();

router.get("/:upload_id", (req, res) => {
  const { upload_id } = req.params;

  const uploadRow = db.prepare("SELECT * FROM uploads WHERE upload_id = ?").get(upload_id);
  if (!uploadRow) {
    return res.status(404).json({ error: "Upload not found." });
  }

  const rows = db
    .prepare(
      "SELECT review_id, product, review_text, date, theme, sentiment, key_phrases FROM reviews WHERE upload_id = ?"
    )
    .all(upload_id);

  const results = rows.map((r) => ({
    ...r,
    key_phrases: r.key_phrases ? JSON.parse(r.key_phrases) : [],
  }));

  return res.json(results);
});

module.exports = router;
