from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.database import Base, engine
from app.routers import auth, companies, dashboard, deals, members, sponsors
from app.seed import seed


@asynccontextmanager
async def lifespan(_: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    await seed()
    yield


settings = get_settings()
app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    lifespan=lifespan,
    docs_url="/docs",
    openapi_url="/openapi.json",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

prefix = settings.api_prefix
app.include_router(auth.router, prefix=prefix)
app.include_router(members.router, prefix=prefix)
app.include_router(sponsors.router, prefix=prefix)
app.include_router(companies.router, prefix=prefix)
app.include_router(deals.router, prefix=prefix)
app.include_router(dashboard.router, prefix=prefix)


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
