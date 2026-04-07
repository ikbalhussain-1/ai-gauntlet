import { useState, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { uploadCsv, analyzeUpload } from "./api";
import Navbar from "./Navbar";

const STEPS = [
  { label: "Integrity Check", sub: "Ensures dataset follows agency standard" },
  { label: "Column Mapping", sub: "Detected: 'review', 'date', 'rating'" },
  { label: "Analysing Sentiment", sub: "3,421 rows processed…" },
];

export default function UploadScreen() {
  const [file, setFile] = useState(null);
  const [dragging, setDragging] = useState(false);
  const [status, setStatus] = useState("idle"); // idle | uploading | analysing | error
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState(null);
  const inputRef = useRef();
  const navigate = useNavigate();

  const handleFile = (f) => {
    if (!f) return;
    if (!f.name.endsWith(".csv")) {
      setError("Please select a CSV file.");
      setFile(null);
      return;
    }
    setError(null);
    setFile(f);
  };

  const handleDrop = (e) => {
    e.preventDefault();
    setDragging(false);
    handleFile(e.dataTransfer.files[0]);
  };

  const handleAnalyse = async () => {
    try {
      setStatus("uploading");
      setProgress(30);
      setError(null);
      const { data: uploadData } = await uploadCsv(file);
      const uploadId = uploadData.upload_id;

      setStatus("analysing");
      setProgress(65);
      await analyzeUpload(uploadId);

      // Poll until analysis is complete (themes populated)
      const { getResults } = await import("./api");
      for (let i = 0; i < 45; i++) {
        await new Promise((r) => setTimeout(r, 2000));
        const { data } = await getResults(uploadId);
        if (Array.isArray(data) && data.length > 0 && data[0].theme) {
          setProgress(100);
          navigate(`/dashboard/${uploadId}`);
          return;
        }
        setProgress(65 + Math.min(i * 0.7, 30));
      }
      throw new Error("Analysis timed out. Please try again.");
    } catch (err) {
      setError(err.response?.data?.error || err.message || "Something went wrong. Please try again.");
      setStatus("error");
      setProgress(0);
    }
  };

  const busy = status === "uploading" || status === "analysing";
  const currentStep = status === "uploading" ? 0 : status === "analysing" ? 2 : -1;

  return (
    <div style={s.page}>
      <Navbar />

      <div style={s.hero}>
        <h1 style={s.heroTitle}>Refine Your Insights</h1>
        <p style={s.heroSub}>
          Upload your weekly reviews CSV to get instant insights. We'll use<br />
          our curated neural models to extract key sentiment themes and architectural patterns.
        </p>
      </div>

      <div style={s.panels}>
        {/* Left — drop zone */}
        <div style={s.left}>
          <div
            style={{ ...s.dropzone, ...(dragging ? s.dropzoneDrag : {}) }}
            onClick={() => !busy && inputRef.current.click()}
            onDragOver={(e) => { e.preventDefault(); setDragging(true); }}
            onDragLeave={() => setDragging(false)}
            onDrop={handleDrop}
          >
            <input
              ref={inputRef}
              type="file"
              accept=".csv"
              style={{ display: "none" }}
              onChange={(e) => handleFile(e.target.files[0])}
            />
            <div style={s.uploadIcon}>☁️</div>
            {file ? (
              <>
                <p style={s.dropTitle}>{file.name}</p>
                <p style={s.dropSub}>Click to change file</p>
              </>
            ) : (
              <>
                <p style={s.dropTitle}>Drag and drop dataset</p>
                <p style={s.dropSub}>Or click to browse your local filesystem</p>
                <p style={s.dropHint}>Supports: CSV, XLSX (Max 50MB)</p>
              </>
            )}
          </div>

          {error && <p style={s.error}>{error}</p>}

          {busy && (
            <div style={s.progressWrap}>
              <div style={s.progressBar}>
                <div style={{ ...s.progressFill, width: `${progress}%` }} />
              </div>
              <div style={s.progressRow}>
                <span style={s.progressFile}>{file?.name}</span>
                <span style={s.progressPct}>{progress}%</span>
              </div>
            </div>
          )}
        </div>

        {/* Right — summary panel */}
        <div style={s.right}>
          <p style={s.summaryTitle}>Upload Summary</p>
          <div style={s.steps}>
            {STEPS.map((step, i) => {
              const done = busy && i < currentStep;
              const active = busy && i === currentStep;
              return (
                <div key={step.label} style={s.step}>
                  <div style={{ ...s.stepDot, background: done ? "#48BB78" : active ? "#4299E1" : "#E2E8F0" }}>
                    {done ? "✓" : active ? <Spinner small /> : <span style={{ color: "#718096" }}>{i + 1}</span>}
                  </div>
                  <div>
                    <p style={{ ...s.stepLabel, color: active ? "#4299E1" : done ? "#48BB78" : "#2D3748" }}>
                      {step.label}
                    </p>
                    <p style={s.stepSub}>{step.sub}</p>
                  </div>
                </div>
              );
            })}
          </div>

          <div style={s.divider} />

          <button
            style={{ ...s.btn, ...(!file || busy ? s.btnDisabled : {}) }}
            disabled={!file || busy}
            onClick={handleAnalyse}
          >
            {busy
              ? status === "uploading" ? "Uploading…" : "Analysing…"
              : "Analyse Reviews ✦"}
          </button>

          {file && !busy && (
            <button style={s.cancelBtn} onClick={() => { setFile(null); setError(null); }}>
              Cancel Upload
            </button>
          )}

          <p style={s.secure}>🔒 Secured with AES-256 Encryption</p>
        </div>
      </div>

      <footer style={s.footer}>
        <span>© 2024 Review Intelligence. All rights reserved.</span>
        <div style={s.footerLinks}>
          {["Privacy Policy", "Security Architecture", "API Support"].map((l) => (
            <span key={l} style={s.footerLink}>{l}</span>
          ))}
        </div>
      </footer>
    </div>
  );
}

function Spinner({ small }) {
  const size = small ? 14 : 28;
  return (
    <div style={{
      width: size, height: size,
      border: `${small ? 2 : 3}px solid rgba(255,255,255,0.4)`,
      borderTop: `${small ? 2 : 3}px solid #fff`,
      borderRadius: "50%",
      animation: "spin 0.8s linear infinite",
    }} />
  );
}

const s = {
  page: { minHeight: "100vh", background: "#F7F9FC", display: "flex", flexDirection: "column" },
  hero: { textAlign: "center", padding: "3rem 1rem 1.5rem" },
  heroTitle: { fontSize: 42, fontWeight: 700, color: "#1A202C", marginBottom: "0.75rem" },
  heroSub: { fontSize: 15, color: "#718096", lineHeight: 1.7 },
  panels: {
    display: "flex",
    flexDirection: "column",
    gap: "1.5rem",
    maxWidth: 520,
    margin: "0 auto",
    padding: "0 1.5rem 3rem",
    width: "100%",
    alignItems: "stretch",
  },
  left: {},
  dropzone: {
    background: "#fff",
    border: "2px dashed #CBD5E0",
    borderRadius: 12,
    padding: "3rem 2rem",
    textAlign: "center",
    cursor: "pointer",
    transition: "border-color 0.2s, background 0.2s",
    marginBottom: "1rem",
  },
  dropzoneDrag: { borderColor: "#4299E1", background: "#EBF8FF" },
  uploadIcon: { fontSize: 48, marginBottom: "1rem" },
  dropTitle: { fontSize: 17, fontWeight: 600, color: "#2D3748", marginBottom: 6 },
  dropSub: { fontSize: 13, color: "#718096", marginBottom: 4 },
  dropHint: { fontSize: 12, color: "#A0AEC0" },
  error: { color: "#E53E3E", fontSize: 13, marginBottom: "0.75rem", padding: "0.5rem 0.75rem", background: "#FFF5F5", borderRadius: 6, border: "1px solid #FED7D7" },
  progressWrap: { background: "#fff", borderRadius: 10, padding: "1rem 1.25rem", border: "1px solid #E2E8F0" },
  progressBar: { background: "#EDF2F7", borderRadius: 999, height: 6, marginBottom: 8, overflow: "hidden" },
  progressFill: { background: "#4299E1", height: "100%", borderRadius: 999, transition: "width 0.4s ease" },
  progressRow: { display: "flex", justifyContent: "space-between", alignItems: "center" },
  progressFile: { fontSize: 12, color: "#718096" },
  progressPct: { fontSize: 13, fontWeight: 700, color: "#4299E1" },
  right: {
    flex: 1,
    background: "#fff",
    borderRadius: 12,
    padding: "1.5rem",
    border: "1px solid #E2E8F0",
    boxShadow: "0 2px 12px rgba(0,0,0,0.06)",
  },
  summaryTitle: { fontSize: 15, fontWeight: 700, color: "#1A202C", marginBottom: "1.25rem" },
  steps: { display: "flex", flexDirection: "column", gap: "1rem", marginBottom: "1.25rem" },
  step: { display: "flex", alignItems: "flex-start", gap: "0.75rem" },
  stepDot: {
    width: 26, height: 26, borderRadius: "50%",
    color: "#fff", fontSize: 11, fontWeight: 700,
    display: "flex", alignItems: "center", justifyContent: "center",
    flexShrink: 0, marginTop: 2,
  },
  stepLabel: { fontSize: 13, fontWeight: 600, marginBottom: 2 },
  stepSub: { fontSize: 11, color: "#A0AEC0" },
  divider: { borderTop: "1px solid #E2E8F0", margin: "1.25rem 0" },
  btn: {
    width: "100%", padding: "0.8rem", borderRadius: 8,
    background: "#4299E1", color: "#fff", border: "none",
    fontSize: 15, fontWeight: 600, marginBottom: "0.5rem",
    transition: "background 0.2s",
  },
  btnDisabled: { background: "#A0AEC0", cursor: "not-allowed" },
  cancelBtn: {
    width: "100%", padding: "0.6rem", borderRadius: 8,
    background: "transparent", color: "#718096",
    border: "1px solid #E2E8F0", fontSize: 13,
    marginBottom: "1rem",
  },
  secure: { fontSize: 11, color: "#A0AEC0", textAlign: "center" },
  footer: {
    marginTop: "auto", borderTop: "1px solid #E2E8F0",
    background: "#fff", padding: "1rem 2rem",
    display: "flex", justifyContent: "space-between", alignItems: "center",
    fontSize: 12, color: "#A0AEC0",
  },
  footerLinks: { display: "flex", gap: "1.5rem" },
  footerLink: { cursor: "pointer", color: "#718096" },
};
