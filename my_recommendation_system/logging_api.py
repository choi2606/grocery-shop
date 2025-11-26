from fastapi import APIRouter
import sqlite3
from datetime import datetime

router = APIRouter()

DB_PATH = "recommendation1.sqlite3"

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS collector_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event TEXT,
            product_id TEXT,
            user_id TEXT,
            session_id TEXT,
            created TEXT
        )
    """)
    conn.commit()
    conn.close()

init_db()

@router.post("/log")
async def add_log(item: dict):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    event = item.get("event")
    product_id = item.get("product_id")
    user_id = item.get("user_id")
    session_id = item.get("session_id")

    cur.execute("""
        INSERT INTO collector_log (event, product_id, user_id, session_id, created)
        VALUES (?, ?, ?, ?, ?)
    """, (
        item.get("event"),
        item.get("product_id"),
        item.get("user_id"),
        item.get("session_id"),
        datetime.utcnow().isoformat()
    ))

    conn.commit()
    conn.close()

    return {"status": "ok"}
