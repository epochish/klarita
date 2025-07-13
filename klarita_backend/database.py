# database.py

import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

# ---------------------------------------------------------------------------
# STRICT Postgres-only configuration
# ---------------------------------------------------------------------------
# We’ve fully migrated – if DATABASE_URL is missing, fail fast so the developer
# knows to supply one (rather than silently falling back to a local SQLite file
# and wondering where their data went).

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise RuntimeError(
        "DATABASE_URL environment variable not set. Klarita now requires a "
        "PostgreSQL connection string (e.g. postgresql+psycopg2://user:pass@host/db)."
    )

# Create engine with a reasonable pool configuration.
engine = create_engine(
    DATABASE_URL,
    pool_size=20,
    max_overflow=0,
    pool_pre_ping=True,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Dependency to get a DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()