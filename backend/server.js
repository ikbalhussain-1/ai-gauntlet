require("dotenv").config({ path: require("path").join(__dirname, "../.env") });

const express = require("express");
const cors = require("cors");

const app = express();
const PORT = process.env.BACKEND_PORT || 8000;

app.use(cors({ origin: "http://localhost:3000" }));
app.use(express.json());

app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

app.use("/upload", require("./routes/upload"));
app.use("/analyze", require("./routes/analyze"));
app.use("/results", require("./routes/results"));
app.use("/analytics", require("./routes/analytics"));

app.listen(PORT, () => {
  console.log(`Backend running on http://localhost:${PORT}`);
});

module.exports = app;
