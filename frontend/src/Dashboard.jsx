import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell,
  PieChart, Pie, Legend,
} from "recharts";
import { getResults, getAnalytics } from "./api";
import Navbar from "./Navbar";

const THEME_COLORS = {
  "Product Quality": "#4299E1",
  "Efficacy": "#48BB78",
  "Taste/Smell": "#ED8936",
  "Packaging": "#9F7AEA",
  "Delivery": "#F6AD55",
  "Customer Service": "#FC8181",
  "Pricing": "#68D391",
  "Other": "#A0AEC0",
};

const SENTIMENT_COLORS = { Positive: "#48BB78", Negative: "#FC8181", Neutral: "#A0AEC0" };
const SENTIMENT_ICONS = { Positive: "😊", Negative: "😞", Neutral: "😐" };
const PAGE_SIZE = 10;

export default function Dashboard() {
  const { uploadId } = useParams();
  const navigate = useNavigate();
  const [reviews, setReviews] = useState([]);
  const [analytics, setAnalytics] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [themeFilter, setThemeFilter] = useState("All");
  const [sentimentFilter, setSentimentFilter] = useState("All");
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);

  useEffect(() => {
    Promise.all([getResults(uploadId), getAnalytics(uploadId)])
      .then(([r, a]) => { setReviews(r.data); setAnalytics(a.data); })
      .catch(() => setError("Failed to load results. Please try again."))
      .finally(() => setLoading(false));
  }, [uploadId]);

  if (loading) return <Centered><Spinner /><p style={{ color: "#718096", marginTop: 12 }}>Loading results…</p></Centered>;
  if (error) return <Centered><p style={{ color: "#E53E3E" }}>{error}</p></Centered>;

  const themeData = Object.entries(analytics.theme_distribution)
    .map(([name, value]) => ({ name, value }))
    .sort((a, b) => b.value - a.value);
  const sentimentData = Object.entries(analytics.sentiment_breakdown).map(([name, value]) => ({ name, value }));
  const positiveCount = analytics.sentiment_breakdown.Positive || 0;
  const positivePct = analytics.total_reviews > 0 ? Math.round((positiveCount / analytics.total_reviews) * 100) : 0;
  const topTheme = themeData[0]?.name || "—";

  const filtered = reviews.filter((r) => {
    if (themeFilter !== "All" && r.theme !== themeFilter) return false;
    if (sentimentFilter !== "All" && r.sentiment !== sentimentFilter) return false;
    if (search && !r.review_text.toLowerCase().includes(search.toLowerCase()) &&
        !r.product.toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const paginated = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);
  const themes = ["All", ...Object.keys(analytics.theme_distribution)];
  const today = new Date().toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" });

  const handleThemeClick = (name) => navigate(`/theme/${uploadId}/${encodeURIComponent(name)}`);

  return (
    <div style={s.page}>
      <Navbar uploadId={uploadId} />

      <div style={s.content}>
        {/* Page header */}
        <div style={s.pageHeader}>
          <div>
            <h1 style={s.pageTitle}>Dashboard</h1>
            <p style={s.pageMeta}>{analytics.total_reviews} reviews analysed · {today}</p>
          </div>
          <button style={s.exportBtn}>⬇ Export Report</button>
        </div>

        {/* Summary cards */}
        <div style={s.cards}>
          <Card label="Total Reviews" value={analytics.total_reviews} sub="uploaded" />
          <Card label="Positive Sentiment" value={`${positivePct}%`} sub="of all reviews" color="#48BB78" />
          <Card label="Most Common Theme" value={topTheme} sub={`${themeData[0]?.value || 0} reviews`} small />
        </div>

        {/* Charts */}
        <div style={s.charts}>
          <div style={s.chartBox}>
            <h3 style={s.chartTitle}>Theme Distribution</h3>
            <ResponsiveContainer width="100%" height={240}>
              <BarChart data={themeData} layout="vertical" margin={{ left: 8, right: 24 }}>
                <XAxis type="number" hide />
                <YAxis type="category" dataKey="name" width={130} tick={{ fontSize: 12, fill: "#718096" }} />
                <Tooltip formatter={(v) => [v, "Reviews"]} />
                <Bar dataKey="value" radius={4} cursor="pointer" onClick={(d) => handleThemeClick(d.name)}>
                  {themeData.map((entry) => (
                    <Cell key={entry.name} fill={THEME_COLORS[entry.name] || "#4299E1"} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>

          <div style={s.chartBox}>
            <h3 style={s.chartTitle}>Sentiment Breakdown</h3>
            <div style={{ position: "relative" }}>
              <ResponsiveContainer width="100%" height={240}>
                <PieChart>
                  <Pie data={sentimentData} dataKey="value" nameKey="name" innerRadius={65} outerRadius={95}>
                    {sentimentData.map((entry) => (
                      <Cell key={entry.name} fill={SENTIMENT_COLORS[entry.name] || "#A0AEC0"} />
                    ))}
                  </Pie>
                  <Legend iconType="circle" iconSize={10} />
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
              <div style={s.donutCenter}>
                <span style={s.donutPct}>{positivePct}%</span>
                <span style={s.donutLabel}>Positive</span>
              </div>
            </div>
          </div>
        </div>

        {/* Filter bar */}
        <div style={s.filterBar}>
          <div style={s.searchWrap}>
            <span style={s.searchIcon}>🔍</span>
            <input
              style={s.searchInput}
              placeholder="Search across reviews…"
              value={search}
              onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            />
          </div>
          <select style={s.select} value={themeFilter} onChange={(e) => { setThemeFilter(e.target.value); setPage(1); }}>
            {themes.map((t) => <option key={t} value={t}>{t === "All" ? "All Themes" : t}</option>)}
          </select>
          <select style={s.select} value={sentimentFilter} onChange={(e) => { setSentimentFilter(e.target.value); setPage(1); }}>
            {["All", "Positive", "Negative", "Neutral"].map((s) => <option key={s} value={s}>{s === "All" ? "All Sentiments" : s}</option>)}
          </select>
          {(themeFilter !== "All" || sentimentFilter !== "All" || search) && (
            <button style={s.clearBtn} onClick={() => { setThemeFilter("All"); setSentimentFilter("All"); setSearch(""); setPage(1); }}>
              ✕ Clear
            </button>
          )}
        </div>

        {/* Table */}
        <div style={s.tableWrap}>
          <table style={s.table}>
            <thead>
              <tr style={s.thead}>
                {["Product", "Review Text", "Theme", "Sentiment", "Key Phrases"].map((h) => (
                  <th key={h} style={s.th}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {paginated.length === 0 ? (
                <tr><td colSpan={5} style={s.empty}>No reviews match your filters.</td></tr>
              ) : paginated.map((r, i) => (
                <tr key={r.review_id} style={{ ...s.tr, background: i % 2 === 0 ? "#fff" : "#FAFAFA" }}>
                  <td style={{ ...s.td, fontWeight: 600, whiteSpace: "nowrap" }}>{r.product}</td>
                  <td style={{ ...s.td, maxWidth: 320 }}>
                    <span title={r.review_text}>{r.review_text.length > 90 ? r.review_text.slice(0, 90) + "…" : r.review_text}</span>
                  </td>
                  <td style={s.td}>
                    <span style={{ ...s.badge, background: (THEME_COLORS[r.theme] || "#4299E1") + "22", color: THEME_COLORS[r.theme] || "#4299E1" }}>
                      {r.theme}
                    </span>
                  </td>
                  <td style={s.td}>
                    <span style={{ ...s.sentBadge, background: SENTIMENT_COLORS[r.sentiment] + "22", color: SENTIMENT_COLORS[r.sentiment] }}>
                      {SENTIMENT_ICONS[r.sentiment]} {r.sentiment}
                    </span>
                  </td>
                  <td style={{ ...s.td, color: "#718096", fontSize: 12 }}>{(r.key_phrases || []).join(", ")}</td>
                </tr>
              ))}
            </tbody>
          </table>

          {/* Pagination */}
          <div style={s.pagination}>
            <span style={s.pageInfo}>
              Showing {Math.min((page - 1) * PAGE_SIZE + 1, filtered.length)}–{Math.min(page * PAGE_SIZE, filtered.length)} of {filtered.length}
            </span>
            <div style={s.pageButtons}>
              <button style={s.pageBtn} disabled={page === 1} onClick={() => setPage(p => p - 1)}>‹</button>
              {Array.from({ length: totalPages }, (_, i) => i + 1).map((n) => (
                <button key={n} style={{ ...s.pageBtn, ...(n === page ? s.pageBtnActive : {}) }} onClick={() => setPage(n)}>
                  {n}
                </button>
              ))}
              <button style={s.pageBtn} disabled={page === totalPages} onClick={() => setPage(p => p + 1)}>›</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function Card({ label, value, sub, color, small }) {
  return (
    <div style={s.card}>
      <p style={s.cardLabel}>{label}</p>
      <p style={{ ...s.cardValue, color: color || "#1A202C", fontSize: small ? 20 : 32 }}>{value}</p>
      <p style={s.cardSub}>{sub}</p>
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
  content: { maxWidth: 1200, margin: "0 auto", padding: "2rem 1.5rem" },
  pageHeader: { display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "1.5rem" },
  pageTitle: { fontSize: 32, fontWeight: 700, color: "#1A202C", marginBottom: 4 },
  pageMeta: { fontSize: 13, color: "#A0AEC0" },
  exportBtn: { padding: "0.6rem 1.2rem", borderRadius: 8, background: "#fff", border: "1px solid #E2E8F0", fontSize: 13, fontWeight: 600, color: "#4A5568", boxShadow: "0 1px 4px rgba(0,0,0,0.06)" },
  cards: { display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: "1rem", marginBottom: "1.5rem" },
  card: { background: "#fff", borderRadius: 10, padding: "1.25rem 1.5rem", border: "1px solid #E2E8F0", boxShadow: "0 1px 4px rgba(0,0,0,0.04)" },
  cardLabel: { fontSize: 12, color: "#A0AEC0", textTransform: "uppercase", letterSpacing: 0.5, marginBottom: 6 },
  cardValue: { fontWeight: 700, marginBottom: 4, lineHeight: 1.1 },
  cardSub: { fontSize: 11, color: "#A0AEC0" },
  charts: { display: "grid", gridTemplateColumns: "1.3fr 1fr", gap: "1rem", marginBottom: "1.5rem" },
  chartBox: { background: "#fff", borderRadius: 10, padding: "1.25rem 1.5rem", border: "1px solid #E2E8F0", boxShadow: "0 1px 4px rgba(0,0,0,0.04)" },
  chartTitle: { fontSize: 14, fontWeight: 600, color: "#2D3748", marginBottom: "1rem" },
  donutCenter: { position: "absolute", top: "50%", left: "50%", transform: "translate(-50%, -60%)", textAlign: "center", pointerEvents: "none" },
  donutPct: { display: "block", fontSize: 24, fontWeight: 700, color: "#1A202C" },
  donutLabel: { display: "block", fontSize: 11, color: "#A0AEC0" },
  filterBar: { display: "flex", gap: "0.6rem", marginBottom: "1rem", alignItems: "center", flexWrap: "wrap" },
  searchWrap: { display: "flex", alignItems: "center", background: "#fff", border: "1px solid #E2E8F0", borderRadius: 8, padding: "0.45rem 0.75rem", gap: 6, flex: 1, minWidth: 200 },
  searchIcon: { fontSize: 13, color: "#A0AEC0" },
  searchInput: { border: "none", outline: "none", fontSize: 13, color: "#4A5568", background: "transparent", width: "100%" },
  select: { padding: "0.5rem 0.75rem", borderRadius: 8, border: "1px solid #E2E8F0", fontSize: 13, background: "#fff", color: "#4A5568" },
  clearBtn: { padding: "0.5rem 0.85rem", borderRadius: 8, border: "1px solid #FED7D7", background: "#FFF5F5", color: "#E53E3E", fontSize: 13, fontWeight: 500 },
  tableWrap: { background: "#fff", borderRadius: 10, border: "1px solid #E2E8F0", overflow: "auto", boxShadow: "0 1px 4px rgba(0,0,0,0.04)" },
  table: { width: "100%", borderCollapse: "collapse" },
  thead: { background: "#F7FAFC" },
  th: { textAlign: "left", padding: "0.85rem 1rem", fontSize: 11, fontWeight: 700, color: "#A0AEC0", textTransform: "uppercase", letterSpacing: 0.5, borderBottom: "1px solid #E2E8F0" },
  tr: { borderBottom: "1px solid #F0F4F8", transition: "background 0.1s" },
  td: { padding: "0.85rem 1rem", fontSize: 13, color: "#2D3748", verticalAlign: "middle" },
  empty: { textAlign: "center", padding: 32, color: "#A0AEC0", fontSize: 14 },
  badge: { display: "inline-block", padding: "3px 10px", borderRadius: 999, fontSize: 11, fontWeight: 600 },
  sentBadge: { display: "inline-flex", alignItems: "center", gap: 4, padding: "3px 10px", borderRadius: 999, fontSize: 11, fontWeight: 600 },
  pagination: { display: "flex", justifyContent: "space-between", alignItems: "center", padding: "0.85rem 1rem", borderTop: "1px solid #F0F4F8" },
  pageInfo: { fontSize: 12, color: "#A0AEC0" },
  pageButtons: { display: "flex", gap: 4 },
  pageBtn: { width: 30, height: 30, borderRadius: 6, border: "1px solid #E2E8F0", background: "#fff", fontSize: 13, color: "#4A5568", display: "flex", alignItems: "center", justifyContent: "center" },
  pageBtnActive: { background: "#4299E1", color: "#fff", border: "1px solid #4299E1", fontWeight: 700 },
};
