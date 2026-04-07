import { useNavigate, useLocation } from "react-router-dom";

export default function Navbar({ uploadId }) {
  const navigate = useNavigate();
  const location = useLocation();

  const links = [
    { label: "Dashboard", path: uploadId ? `/dashboard/${uploadId}` : "/" },
    { label: "Reviews", path: uploadId ? `/dashboard/${uploadId}` : "/" },
    { label: "Themes", path: uploadId ? `/dashboard/${uploadId}` : "/" },
  ];

  const isActive = (path) => location.pathname === path;

  return (
    <nav style={s.nav}>
      <div style={s.inner}>
        <span style={s.logo} onClick={() => navigate("/")} role="button">
          Review Intelligence
        </span>
        <div style={s.links}>
          {links.map(({ label, path }) => (
            <span
              key={label}
              style={{ ...s.link, ...(location.pathname.includes(label.toLowerCase()) ? s.linkActive : {}) }}
              onClick={() => navigate(path)}
            >
              {label}
            </span>
          ))}
        </div>
        <div style={s.right}>
          <div style={s.searchBox}>
            <span style={s.searchIcon}>🔍</span>
            <input style={s.searchInput} placeholder="Global search…" readOnly />
          </div>
          <span style={s.icon}>🔔</span>
          <div style={s.avatar}>U</div>
        </div>
      </div>
    </nav>
  );
}

const s = {
  nav: {
    background: "#fff",
    borderBottom: "1px solid #E2E8F0",
    position: "sticky",
    top: 0,
    zIndex: 100,
  },
  inner: {
    maxWidth: 1280,
    margin: "0 auto",
    padding: "0 2rem",
    height: 60,
    display: "flex",
    alignItems: "center",
    gap: "2rem",
  },
  logo: {
    fontWeight: 700,
    fontSize: 18,
    color: "#4299E1",
    cursor: "pointer",
    whiteSpace: "nowrap",
  },
  links: {
    display: "flex",
    gap: "0.25rem",
    flex: 1,
  },
  link: {
    padding: "0.4rem 0.85rem",
    borderRadius: 6,
    fontSize: 14,
    color: "#4A5568",
    cursor: "pointer",
    fontWeight: 500,
    transition: "background 0.15s",
  },
  linkActive: {
    color: "#4299E1",
    background: "#EBF8FF",
    fontWeight: 600,
  },
  right: {
    display: "flex",
    alignItems: "center",
    gap: "0.75rem",
  },
  searchBox: {
    display: "flex",
    alignItems: "center",
    background: "#F7FAFC",
    border: "1px solid #E2E8F0",
    borderRadius: 8,
    padding: "0.35rem 0.75rem",
    gap: 6,
  },
  searchIcon: { fontSize: 13 },
  searchInput: {
    border: "none",
    background: "transparent",
    outline: "none",
    fontSize: 13,
    color: "#718096",
    width: 140,
  },
  icon: { fontSize: 18, cursor: "pointer" },
  avatar: {
    width: 32,
    height: 32,
    borderRadius: "50%",
    background: "#4299E1",
    color: "#fff",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    fontSize: 13,
    fontWeight: 700,
    cursor: "pointer",
  },
};
