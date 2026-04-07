const express = require("express");
const db = require("../db");

const router = express.Router();

router.get("/:upload_id", (req, res) => {
  const { upload_id } = req.params;

  const uploadRow = db.prepare("SELECT * FROM uploads WHERE upload_id = ?").get(upload_id);
  if (!uploadRow) {
    return res.status(404).json({ error: "Upload not found." });
  }

  const themeRows = db
    .prepare(
      "SELECT theme, COUNT(*) as count FROM reviews WHERE upload_id = ? AND theme IS NOT NULL GROUP BY theme"
    )
    .all(upload_id);

  const sentimentRows = db
    .prepare(
      "SELECT sentiment, COUNT(*) as count FROM reviews WHERE upload_id = ? AND sentiment IS NOT NULL GROUP BY sentiment"
    )
    .all(upload_id);

  const totalRow = db
    .prepare("SELECT COUNT(*) as total FROM reviews WHERE upload_id = ?")
    .get(upload_id);

  const theme_distribution = {};
  for (const row of themeRows) {
    theme_distribution[row.theme] = row.count;
  }

  const sentiment_breakdown = { Positive: 0, Negative: 0, Neutral: 0 };
  for (const row of sentimentRows) {
    if (row.sentiment in sentiment_breakdown) {
      sentiment_breakdown[row.sentiment] = row.count;
    }
  }

  return res.json({
    theme_distribution,
    sentiment_breakdown,
    total_reviews: totalRow.total,
  });
});

module.exports = router;
