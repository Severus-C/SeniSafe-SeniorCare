from fastapi import FastAPI

from .routers import emergency, medication


app = FastAPI(
    title="SeniSafe API",
    version="0.1.0",
    description="颐安 SeniSafe Mock API for medication recognition and emergency packet preparation.",
)

app.include_router(medication.router)
app.include_router(emergency.router)


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
