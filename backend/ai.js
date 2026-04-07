const Anthropic = require("@anthropic-ai/sdk");
const Groq = require("groq-sdk");

const PROVIDER = process.env.AI_PROVIDER || "mock"; // anthropic | groq | mock

const anthropicClient = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
const groqClient = new Groq({ apiKey: process.env.GROQ_API_KEY });

const ANTHROPIC_MODEL = process.env.CLAUDE_MODEL || "claude-sonnet-4-6";
const GROQ_MODEL = process.env.GROQ_MODEL || "llama-3.3-70b-versatile";

const SYSTEM_PROMPT = `You are a customer review analyst. For each review, classify it into exactly one theme from: Product Quality, Efficacy, Taste/Smell, Packaging, Delivery, Customer Service, Pricing, Other. Classify sentiment as exactly one of: Positive, Negative, Neutral. Extract 1-2 key phrases. Respond only with valid JSON.`;

const VALID_THEMES_SET = new Set([
  "Product Quality", "Efficacy", "Taste/Smell", "Packaging",
  "Delivery", "Customer Service", "Pricing", "Other",
]);
const VALID_SENTIMENTS = new Set(["Positive", "Negative", "Neutral"]);

// ─── Mock (no API key needed) ────────────────────────────────────────────────

function mockAnalyzeBatch(batch) {
  return batch.map((r) => {
    const text = r.review_text.toLowerCase();

    let theme = "Other";
    if (/taste|smell|flavou?r|bitter|aroma/.test(text)) theme = "Taste/Smell";
    else if (/packag|bottle|seal|box|leak|sturdy/.test(text)) theme = "Packaging";
    else if (/deliver|shipping|arrival|fast|slow|logistics/.test(text)) theme = "Delivery";
    else if (/price|expensive|cheap|cost|value|overpriced/.test(text)) theme = "Pricing";
    else if (/customer service|support|response|team|helpful/.test(text)) theme = "Customer Service";
    else if (/efficac|stress|sleep|energy|stamina|digestion|relief|effective/.test(text)) theme = "Efficacy";
    else if (/quality|authentic|genuine|made|flavour/.test(text)) theme = "Product Quality";

    let sentiment = "Neutral";
    if (/love|great|excellent|good|best|improve|helpful|fast|genuine|recommend|consistent/.test(text)) sentiment = "Positive";
    else if (/bitter|expensive|disappoint|damaged|slow|unpleasant|nauseous|wrong|frustrated|poor|off|overpriced/.test(text)) sentiment = "Negative";

    const words = r.review_text.replace(/[^a-zA-Z ]/g, " ").split(/\s+/).filter(w => w.length > 3);
    const key_phrases = words.slice(0, 4).reduce((acc, w, i) => {
      if (i % 2 === 0 && words[i + 1]) acc.push(`${w} ${words[i + 1]}`);
      return acc;
    }, []).slice(0, 2);

    return { review_id: r.review_id, theme, sentiment, key_phrases: key_phrases.length ? key_phrases : ["review feedback"] };
  });
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

function buildUserMessage(batch) {
  return `Analyse these ${batch.length} customer reviews and return a JSON array with one object per review in the same order. Each object must have: review_id (string, copy from input), theme (one of the valid themes), sentiment (Positive/Negative/Neutral), key_phrases (array of 1-2 strings).

Reviews:
${JSON.stringify(batch.map((r) => ({ review_id: r.review_id, review_text: r.review_text })), null, 2)}

Respond with ONLY a JSON array, no markdown, no explanation.`;
}

function normalizeItem(item, fallback) {
  return {
    review_id: item.review_id || fallback.review_id,
    theme: VALID_THEMES_SET.has(item.theme) ? item.theme : "Other",
    sentiment: VALID_SENTIMENTS.has(item.sentiment) ? item.sentiment : "Neutral",
    key_phrases: Array.isArray(item.key_phrases) ? item.key_phrases : [],
  };
}

// ─── Anthropic (Claude) ──────────────────────────────────────────────────────

async function analyzeBatchAnthropic(batch) {
  const message = await anthropicClient.messages.create({
    model: ANTHROPIC_MODEL,
    max_tokens: 2048,
    system: SYSTEM_PROMPT,
    messages: [{ role: "user", content: buildUserMessage(batch) }],
  });
  const raw = message.content[0].text.trim().replace(/^```(?:json)?\n?/, "").replace(/\n?```$/, "");
  return JSON.parse(raw).map((item, idx) => normalizeItem(item, batch[idx]));
}

// ─── Groq (Llama) ────────────────────────────────────────────────────────────

async function analyzeBatchGroq(batch) {
  const completion = await groqClient.chat.completions.create({
    model: GROQ_MODEL,
    messages: [
      { role: "system", content: SYSTEM_PROMPT },
      { role: "user", content: buildUserMessage(batch) },
    ],
    response_format: { type: "json_object" },
    max_tokens: 2048,
    temperature: 0.1,
  });
  const raw = completion.choices[0].message.content.trim();
  let parsed = JSON.parse(raw);
  // Groq json_object mode wraps arrays — unwrap if needed
  if (!Array.isArray(parsed)) {
    parsed = parsed.results || parsed.reviews || parsed.data || Object.values(parsed)[0];
  }
  return parsed.map((item, idx) => normalizeItem(item, batch[idx]));
}

// ─── Public API ──────────────────────────────────────────────────────────────

async function analyzeReviews(reviews) {
  if (PROVIDER === "mock" || process.env.MOCK_AI === "true") {
    console.log("⚠️  AI_PROVIDER=mock — using heuristic analysis");
    return mockAnalyzeBatch(reviews);
  }

  console.log(`Using AI provider: ${PROVIDER}`);
  const batchSize = 10;
  const results = [];
  for (let i = 0; i < reviews.length; i += batchSize) {
    const batch = reviews.slice(i, i + batchSize);
    const batchResults = PROVIDER === "groq"
      ? await analyzeBatchGroq(batch)
      : await analyzeBatchAnthropic(batch);
    results.push(...batchResults);
  }
  return results;
}

module.exports = { analyzeReviews };
