# Urban Hazard Backend

Receives hazard images, calls the YOLO detector, caches results in Redis, and stores reports in PostgreSQL.

Run the YOLO service on port 8000, then run `docker compose up --build`.
