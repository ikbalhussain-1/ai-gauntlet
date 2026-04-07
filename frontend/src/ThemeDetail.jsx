import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { getResults } from "./api";
import Navbar from "./Navbar";

const SENTIMENT_COLORS = { Positive: "#48BB78", Negative: "#FC8181", Neutral: "#A0AEC0" };
const SENTIMENT_ICONS = { Positive: "😊", Negative: "😞", Neutral: "😐" };
const PAGE_SIZE = 5;

function getInitials(name) {
  return name.split(" ").map((w) => w[0]).join("").slice(0, 2).toUpperCase();
}

function getAvatarColor(name) {
  const colors = ["#4299E1", "#48BB78", "#ED8936", "#9F7AEA", "#F6AD55", "#FC8181", "#68D391"];
  let hash = 0;
  for (const c of name) hash = (hash + c.charCodeAt(0)) % colors.length;
  return colors[hash];
}

export default function ThemeDetail() {
  const { uploadId, theme } = useParams();
  const navigate = useNavigate();
  const decodedTheme = decodeURIComponent(theme);

  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [activeFilter, setActiveFilter] = useState("All Reviews");
  const [page, setPage] = useState(1);

  useEffect(() => {
    getResults(uploadId)
      .then((r) => setReviews(r.data.filter((rev) => rev.theme === decodedTheme)))
      .catch(() => setError("Failed to load reviews."))
      .finally(() => setLoading(false));
  }, [uploadId, decodedTheme]);

  if (loading) return <Centered><Spinner /><p style={{ color: "#718096", marginTop: 12 }}>Loading…</p></Centered>;
  if (error) return <Centered><p style={{ color: "#E53E3E" }}>{error}</p></Centered>;

  const sentimentCounts = reviews.reduce((acc, r) => {
    acc[r.sentiment] = (acc[r.sentiment] || 0) + 1;
    return acc;
  }, {});

  const positivePct = reviews.length > 0 ? Math.round(((sentimentCounts.Positive || 0) / reviews.length) * 100) : 0;
  const negativePct = reviews.length > 0 ? Math.round(((sentimentCounts.Negative || 0) / reviews.length) * 100) : 0;
  const neutralPct = 100 - positivePct - negativePct;

  // Collect all unique key phrases as filter tags
  const allPhrases = [...new Set(reviews.flatMap((r) => r.key_phrases || []))].slice(0, 4);
  const filterTags = ["All Reviews", ...allPhrases];

  const filtered = activeFilter === "All Reviews"
    ? reviews
    : reviews.filter((r) => (r.key_phrases || []).includes(activeFilter));

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const paginated = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

  // Key Intelligence: derived insights from data
  const topSentiment = Object.entries(sentimentCounts).sort((a, b) => b[1] - a[1])[0];
  const topPhrase = allPhrases[0] || "—";
  const topPhrase2 = allPhrases[1] || "—";

  return (
    <div style={s.page}>
      <Navbar uploadId={uploadId} />

      <div style={s.content}>
        {/* Back */}
        <button style={s.backBtn} onClick={() => navigate(`/dashboard/${uploadId}`)}>
          ← Back to Dashboard
        </button>

        {/* Header */}
        <h1 style={s.pageTitle}>{decodedTheme}</h1>
        <p style={s.pageSub}>
          Detailed analysis of {reviews.length} customer mentions regarding {decodedTheme.toLowerCase()}.
        </p>

        {/* Sentiment Pulse */}
        <div style={s.pulseWrap}>
          <div style={s.pulseHeader}>
            <span style={s.pulseTitle}>SENTIMENT PULSE</span>
            <span style={s.pulseCount}>{reviews.length} Reviews</span>
          </div>
          <div style={s.pulseBar}>
            <div style={{ ...s.pulseSegment, width: `${positivePct}%`, background: "#48BB78" }} />
            <div style={{ ...s.pulseSegment, width: `${neutralPct}%`, background: "#A0AEC0" }} />
            <div style={{ ...s.pulseSegment, width: `${negativePct}%`, background: "#FC8181" }} />
          </div>
          <div style={s.pulseLegend}>
            <span style={{ color: "#48BB78" }}>● {positivePct}% POSITIVE</span>
            <span style={{ color: "#A0AEC0" }}>● {neutralPct}% NEUTRAL</span>
            <span style={{ color: "#FC8181" }}>● {negativePct}% NEGATIVE</span>
          </div>
        </div>

        {/* Filter tags */}
        <div style={s.filterTags}>
          <span style={s.filterLabel}>Filter by:</span>
          {filterTags.map((tag) => (
            <button
              key={tag}
              style={{ ...s.tag, ...(activeFilter === tag ? s.tagActive : {}) }}
              onClick={() => { setActiveFilter(tag); setPage(1); }}
            >
              {tag}
            </button>
          ))}
          <select style={s.sortSelect}>
            <option>Sort: Most Recent</option>
            <option>Sort: Highest Rated</option>
          </select>
        </div>

        {/* Two-column layout */}
        <div style={s.columns}>
          {/* Reviews list */}
          <div style={s.reviewsCol}>
            {paginated.length === 0 ? (
              <p style={s.empty}>No reviews match this filter.</p>
            ) : paginated.map((r) => (
              <ReviewCard key={r.review_id} review={r} />
            ))}

            {/* Pagination */}
            <div style={s.pagination}>
              {Array.from({ length: totalPages }, (_, i) => i + 1).map((n) => (
                <button key={n} style={{ ...s.pageBtn, ...(n === page ? s.pageBtnActive : {}) }} onClick={() => setPage(n)}>
                  {n}
                </button>
              ))}
              {totalPages > 4 && <span style={{ fontSize: 13, color: "#A0AEC0" }}>… {totalPages}</span>}
              {page < totalPages && <button style={s.pageBtn} onClick={() => setPage(p => p + 1)}>›</button>}
            </div>
          </div>

          {/* Key Intelligence sidebar */}
          <div style={s.sidebar}>
            <div style={s.sideCard}>
              <p style={s.sideTitle}>Key Intelligence</p>
              <div style={s.insight}>
                <p style={s.insightLabel}>DOMINANT SENTIMENT</p>
                <p style={s.insightText}>
                  "{topPhrase}" is mentioned in {positivePct}% of {decodedTheme.toLowerCase()} reviews.
                </p>
              </div>
              <div style={s.insight}>
                <p style={s.insightLabel}>COMMON THEME</p>
                <p style={s.insightText}>
                  "{topPhrase2}" is linked to {negativePct}% of recent negative reviews.
                </p>
              </div>
              <div style={s.insight}>
                <p style={s.insightLabel}>AI RECOMMENDATION</p>
                <p style={s.insightText}>
                  Prioritise addressing "{topPhrase}" feedback to improve {decodedTheme.toLowerCase()} scores.
                </p>
              </div>
            </div>

            <div style={{ ...s.sideCard, background: "#F7FAFC", border: "1px dashed #CBD5E0" }}>
              <p style={s.sideTitle}>Need a summary?</p>
              <p style={s.insightText}>
                Generate an AI executive summary of all {reviews.length} {decodedTheme.toLowerCase()} reviews.
              </p>
              <button style={s.generateBtn}>✦ Generate Report</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function ReviewCard({ review: r }) {
  const color = getAvatarColor(r.product);
  return (
    <div style={s.reviewCard}>
      <div style={s.reviewTop}>
        <div style={s.reviewMeta}>
          <div style={{ ...s.avatar, background: color }}>{getInitials(r.product)}</div>
          <div>
            <p style={s.reviewProduct}>{r.product}</p>
            <span style={{ ...s.sentBadge, background: SENTIMENT_COLORS[r.sentiment] + "22", color: SENTIMENT_COLORS[r.sentiment] }}>
              {SENTIMENT_ICONS[r.sentiment]} {r.sentiment}
            </span>
          </div>
        </div>
        <div style={s.stars}>{"★".repeat(r.sentiment === "Positive" ? 5 : r.sentiment === "Neutral" ? 3 : 2)}{"☆".repeat(r.sentiment === "Positive" ? 0 : r.sentiment === "Neutral" ? 2 : 3)}</div>
      </div>
      <p style={s.reviewText}>{r.review_text}</p>
      {r.key_phrases?.length > 0 && (
        <div style={s.phrases}>
          {r.key_phrases.map((p) => (
            <span key={p} style={s.phrase}>{p}</span>
          ))}
        </div>
      )}
    </div>
  );
}

function Centered({ children }) {
  return <div style={{ minHeight: "100vh", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>{children}</div>;
}

function Spinner() {
  return <div style={{ width: 36, height: 36, border: "4px solid #E2E8F0", borderTop: "4px solid #4299E1", borderRadius: "50%", animation: "spin 0.8s linear infinite" }} />;
}

const s = {
  page: { minHeight: "100vh", background: "#F7F9FC" },
  content: { maxWidth: 1100, margin: "0 auto", padding: "1.5rem" },
  backBtn: { background: "none", border: "none", color: "#4299E1", fontSize: 13, fontWeight: 600, padding: "0 0 1rem", display: "block" },
  pageTitle: { fontSize: 36, fontWeight: 700, color: "#1A202C", marginBottom: 8 },
  pageSub: { fontSize: 14, color: "#718096", marginBottom: "1.25rem" },
  pulseWrap: { background: "#fff", border: "1px solid #E2E8F0", borderRadius: 10, padding: "1rem 1.25rem", marginBottom: "1.25rem" },
  pulseHeader: { display: "flex", justifyContent: "space-between", marginBottom: 8 },
  pulseTitle: { fontSize: 11, fontWeight: 700, color: "#A0AEC0", letterSpacing: 0.5 },
  pulseCount: { fontSize: 12, color: "#4299E1", fontWeight: 600 },
  pulseBar: { display: "flex", height: 8, borderRadius: 999, overflow: "hidden", marginBottom: 8 },
  pulseSegment: { height: "100%", transition: "width 0.3s" },
  pulseLegend: { display: "flex", gap: "1.5rem", fontSize: 11, fontWeight: 600 },
  filterTags: { display: "flex", gap: "0.5rem", marginBottom: "1.25rem", alignItems: "center", flexWrap: "wrap" },
  filterLabel: { fontSize: 12, color: "#A0AEC0", marginRight: 4 },
  tag: { padding: "0.35rem 0.85rem", borderRadius: 999, border: "1px solid #E2E8F0", background: "#fff", fontSize: 12, color: "#4A5568", fontWeight: 500 },
  tagActive: { background: "#EBF8FF", border: "1px solid #4299E1", color: "#4299E1", fontWeight: 600 },
  sortSelect: { marginLeft: "auto", padding: "0.35rem 0.65rem", borderRadius: 6, border: "1px solid #E2E8F0", fontSize: 12, color: "#718096", background: "#fff" },
  columns: { display: "grid", gridTemplateColumns: "1fr 300px", gap: "1.5rem", alignItems: "flex-start" },
  reviewsCol: {},
  reviewCard: { background: "#fff", borderRadius: 10, padding: "1.25rem", border: "1px solid #E2E8F0", marginBottom: "0.75rem" },
  reviewTop: { display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "0.75rem" },
  reviewMeta: { display: "flex", gap: "0.75rem", alignItems: "flex-start" },
  avatar: { width: 38, height: 38, borderRadius: "50%", color: "#fff", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13, fontWeight: 700, flexShrink: 0 },
  reviewProduct: { fontWeight: 600, fontSize: 14, color: "#1A202C", marginBottom: 4 },
  sentBadge: { display: "inline-flex", alignItems: "center", gap: 4, padding: "2px 8px", borderRadius: 999, fontSize: 11, fontWeight: 600 },
  stars: { fontSize: 14, color: "#F6AD55", letterSpacing: 1 },
  reviewText: { fontSize: 14, color: "#4A5568", lineHeight: 1.65, marginBottom: "0.75rem" },
  phrases: { display: "flex", flexWrap: "wrap", gap: 6 },
  phrase: { background: "#EBF8FF", color: "#2B6CB0", borderRadius: 999, padding: "2px 10px", fontSize: 11 },
  empty: { color: "#A0AEC0", fontSize: 14, padding: "2rem 0" },
  pagination: { display: "flex", gap: 4, paddingTop: "0.5rem" },
  pageBtn: { width: 30, height: 30, borderRadius: 6, border: "1px solid #E2E8F0", background: "#fff", fontSize: 13, color: "#4A5568" },
  pageBtnActive: { background: "#4299E1", color: "#fff", border: "1px solid #4299E1", fontWeight: 700 },
  sidebar: { display: "flex", flexDirection: "column", gap: "1rem" },
  sideCard: { background: "#fff", borderRadius: 10, padding: "1.25rem", border: "1px solid #E2E8F0" },
  sideTitle: { fontSize: 14, fontWeight: 700, color: "#1A202C", marginBottom: "1rem" },
  insight: { marginBottom: "1rem" },
  insightLabel: { fontSize: 10, fontWeight: 700, color: "#A0AEC0", letterSpacing: 0.5, marginBottom: 4 },
  insightText: { fontSize: 12, color: "#4A5568", lineHeight: 1.5 },
  generateBtn: { width: "100%", marginTop: "0.75rem", padding: "0.65rem", borderRadius: 8, background: "#1A202C", color: "#fff", border: "none", fontSize: 13, fontWeight: 600 },
};
