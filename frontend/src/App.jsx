import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import UploadScreen from "./UploadScreen";
import Dashboard from "./Dashboard";
import ThemeDetail from "./ThemeDetail";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<UploadScreen />} />
        <Route path="/dashboard/:uploadId" element={<Dashboard />} />
        <Route path="/theme/:uploadId/:theme" element={<ThemeDetail />} />
        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </BrowserRouter>
  );
}
