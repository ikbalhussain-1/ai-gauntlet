const express = require("express");
const db = require("../db");
const { analyzeReviews } = require("../ai");

const router = express.Router();

router.post("/:upload_id", async (req, res) => {
  const { upload_id } = req.params;

  const uploadRow = db.prepare("SELECT * FROM uploads WHERE upload_id = ?").get(upload_id);
  if (!uploadRow) {
    return res.status(404).json({ error: "Upload not found." });
  }

  const reviews = db
    .prepare("SELECT review_id, review_text FROM reviews WHERE upload_id = ?")
    .all(upload_id);

  db.prepare("UPDATE uploads SET status = 'processing' WHERE upload_id = ?").run(upload_id);

  // Respond immediately so the server stays responsive; process in background
  res.json({ upload_id, status: "processing", analysed: 0 });

  try {
    const results = await analyzeReviews(reviews);

    const updateReview = db.prepare(`
      UPDATE reviews
      SET theme = ?, sentiment = ?, key_phrases = ?, analysed_at = CURRENT_TIMESTAMP
      WHERE upload_id = ? AND review_id = ?
    `);

    const updateAll = db.transaction(() => {
      for (const r of results) {
        updateReview.run(r.theme, r.sentiment, JSON.stringify(r.key_phrases), upload_id, r.review_id);
      }
    });
    updateAll();

    db.prepare("UPDATE uploads SET status = 'complete' WHERE upload_id = ?").run(upload_id);
  } catch (err) {
    db.prepare("UPDATE uploads SET status = 'error' WHERE upload_id = ?").run(upload_id);
    console.error("Analysis error:", err);
  }
});

module.exports = router;
