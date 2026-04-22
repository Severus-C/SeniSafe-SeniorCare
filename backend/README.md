# SeniSafe Backend

## Run

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Core Routes

- `POST /medication/recognize`
- `POST /emergency/prepare_packet`
- `GET /health`
