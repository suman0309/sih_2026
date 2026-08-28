import "dotenv/config";
import crypto from "node:crypto";
import cors from "cors";
import express, { type Request, type Response } from "express";
import multer from "multer";
import { Pool } from "pg";
import { createClient } from "redis";

const port = Number(process.env.PORT ?? 3001);
const yoloUrl = process.env.YOLO_URL ?? "http://localhost:8000";
const yoloApiKey = process.env.YOLO_API_KEY ?? "sih-demo-key";
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const redis = createClient({ url: process.env.REDIS_URL });
const app = express();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });

type Detection = { label: string; confidence: number; box: number[] };
type DetectionResponse = { detections: Detection[]; duration_ms: number; cached?: boolean };

app.use(cors());
app.use(express.json());

// Redis is an optimisation for repeated image analysis, not a reason to take
// down civic reporting. Its client emits an error event unless we handle it.
redis.on("error", (error) => console.warn("Redis unavailable; continuing without cache:", error.message));

async function getCachedAnalysis(cacheKey: string): Promise<DetectionResponse | null> {
  if (!redis.isReady) return null;
  try {
    const cached = await redis.get(cacheKey);
    return cached ? JSON.parse(cached) as DetectionResponse : null;
  } catch (error) {
    console.warn("Redis cache read failed:", error instanceof Error ? error.message : error);
    return null;
  }
}

async function cacheAnalysis(cacheKey: string, analysis: DetectionResponse): Promise<void> {
  if (!redis.isReady) return;
  try {
    await redis.set(cacheKey, JSON.stringify(analysis), { EX: 3600 });
  } catch (error) {
    console.warn("Redis cache write failed:", error instanceof Error ? error.message : error);
  }
}

function severityOf(detections: Detection[]): "low" | "medium" | "high" {
  const confidence = Math.max(0, ...detections.map((d) => d.confidence));
  return confidence >= 0.7 ? "high" : confidence >= 0.5 ? "medium" : "low";
}

async function analyseImage(file: Express.Multer.File): Promise<DetectionResponse> {
  const cacheKey = `yolo:${crypto.createHash("sha256").update(file.buffer).digest("hex")}`;
  const cached = await getCachedAnalysis(cacheKey);
  if (cached) return { ...cached, cached: true };
  const form = new FormData();
  // Multer gives Node a Buffer; slice its backing store to a Web API-compatible ArrayBuffer.
  const imageBytes = file.buffer.buffer.slice(file.buffer.byteOffset, file.buffer.byteOffset + file.buffer.byteLength) as ArrayBuffer;
  form.append("file", new Blob([imageBytes], { type: file.mimetype }), file.originalname);
  const response = await fetch(`${yoloUrl}/detect`, { method: "POST", headers: { "x-api-key": yoloApiKey }, body: form });
  if (!response.ok) throw new Error(`YOLO service returned ${response.status}`);
  const result = await response.json() as DetectionResponse;
  await cacheAnalysis(cacheKey, result);
  return result;
}

async function initialiseDatabase() {
  await pool.query(`CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), description TEXT, latitude DOUBLE PRECISION, longitude DOUBLE PRECISION,
    image_name TEXT NOT NULL, hazard_type TEXT NOT NULL DEFAULT 'pothole', ai_confidence DOUBLE PRECISION NOT NULL DEFAULT 0,
    detections JSONB NOT NULL DEFAULT '[]'::jsonb, severity TEXT NOT NULL, risk_score INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'submitted', assigned_worker TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW())`);
}

app.get("/health", async (_req, res) => {
  try { await pool.query("SELECT 1"); res.json({ status: "ok", yolo_url: yoloUrl, redis_ready: redis.isReady }); }
  catch (error) { res.status(503).json({ status: "degraded", error: error instanceof Error ? error.message : "unknown" }); }
});

app.post("/api/reports", upload.fields([{ name: "image", maxCount: 1 }, { name: "file", maxCount: 1 }]), async (req: Request, res: Response) => {
  try {
    const files = req.files as Record<string, Express.Multer.File[]> | undefined;
    const image = files?.image?.[0] ?? files?.file?.[0];
    if (!image) return res.status(400).json({ error: "Send an image using the 'image' field." });
    const analysis = await analyseImage(image);
    const potholes = analysis.detections.filter((d) => d.label.toLowerCase() === "pothole" && d.confidence >= 0.3);
    if (!potholes.length) return res.status(422).json({ error: "No pothole detected in this image.", analysis });
    const confidence = Math.max(...potholes.map((d) => d.confidence));
    const severity = severityOf(potholes);
    const riskScore = Math.min(100, Math.round({ low: 25, medium: 50, high: 75 }[severity] + confidence * 25));
    const { description = "", latitude = null, longitude = null } = req.body;
    const saved = await pool.query(`INSERT INTO reports (description,latitude,longitude,image_name,ai_confidence,detections,severity,risk_score) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`, [description, latitude, longitude, image.originalname, confidence, JSON.stringify(potholes), severity, riskScore]);
    res.status(201).json({ report: saved.rows[0], analysis });
  } catch (error) { res.status(502).json({ error: "Image analysis failed", detail: error instanceof Error ? error.message : "unknown" }); }
});

app.get("/api/reports", async (_req, res) => {
  const reports = await pool.query("SELECT * FROM reports ORDER BY created_at DESC");
  res.json({ reports: reports.rows });
});

app.patch("/api/reports/:id", async (req, res) => {
  const updated = await pool.query(`UPDATE reports SET status=COALESCE($1,status), assigned_worker=COALESCE($2,assigned_worker), updated_at=NOW() WHERE id=$3 RETURNING *`, [req.body.status ?? null, req.body.assigned_worker ?? null, req.params.id]);
  if (!updated.rowCount) return res.status(404).json({ error: "Report not found" });
  res.json({ report: updated.rows[0] });
});

async function start() {
  try {
    await redis.connect();
  } catch (error) {
    console.warn("Redis did not connect at startup; cache is disabled:", error instanceof Error ? error.message : error);
  }
  await initialiseDatabase();
  app.listen(port, () => console.log(`Backend: http://localhost:${port}`));
}
start().catch((error) => { console.error(error); process.exit(1); });
