import axios from "axios";

const api = axios.create({ baseURL: "http://localhost:8000" });

export const uploadCsv = (file) => {
  const form = new FormData();
  form.append("file", file);
  return api.post("/upload", form);
};

export const analyzeUpload = (uploadId) =>
  api.post(`/analyze/${uploadId}`, null, { timeout: 120000 });

export const getResults = (uploadId) => api.get(`/results/${uploadId}`);

export const getAnalytics = (uploadId) => api.get(`/analytics/${uploadId}`);
