import datetime
from collections import defaultdict
import math
import sqlite3

DB_PATH = "recommendation1.sqlite3"

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()


cursor.execute("""
CREATE TABLE IF NOT EXISTS analytics_rating (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT,
    product_id TEXT,
    rating REAL,
    rating_type TEXT,
    created TEXT
)
""")
conn.commit()

WEIGHTS = {
    "purchase": 100,
    "add_to_cart": 50,
    #"wishlist_add": 30,
    "prod_details": 15,
    #"categoryView": 5,
}


def query_all_users():
    cursor.execute("SELECT DISTINCT user_id FROM collector_log WHERE user_id IS NOT NULL")
    rows = cursor.fetchall()
    return [r[0] for r in rows]


def query_logs_for_user(user_id):
    cursor.execute("""
        SELECT product_id, event, created
        FROM collector_log
        WHERE user_id = ?
    """, (user_id,))
    return cursor.fetchall()

def calculate_decay(timestamp_string):
    created = datetime.datetime.fromisoformat(timestamp_string)
    now = datetime.datetime.now()
    days = (now - created).days

    if days <= 0:
        days = 1

    return 1 / days


def calculate_implicit_ratings(user_id):
    rows = query_logs_for_user(user_id)
    agg = defaultdict(lambda: defaultdict(int))

    for product_id, event, created in rows:
        if event in WEIGHTS:
            agg[product_id][event] += 1

    ratings = {}
    max_rating = 0

    for pid, events in agg.items():
        score = sum(WEIGHTS[e] * events[e] for e in events)
        ratings[pid] = score
        max_rating = max(max_rating, score)

    if max_rating > 0:
        for pid in ratings:
            ratings[pid] = 10 * ratings[pid] / max_rating

    return ratings


def calculate_implicit_ratings_with_decay(user_id):
    rows = query_logs_for_user(user_id)
    ratings = defaultdict(float)

    for product_id, event, created in rows:
        if event not in WEIGHTS:
            continue

        weight = WEIGHTS[event]
        decay = calculate_decay(created)
        ratings[product_id] += weight * decay

    return dict(ratings)



def save_ratings(user_id, rating_dict, rating_type):
    now = datetime.datetime.now().isoformat()

    for product_id, rating in rating_dict.items():
        cursor.execute("""
            INSERT INTO analytics_rating (user_id, product_id, rating, rating_type, created)
            VALUES (?, ?, ?, ?, ?)
        """, (user_id, product_id, rating, rating_type, now))

    conn.commit()



def main():
    print("Calculating implicit ratings...")
    users = query_all_users()
    print(f"Found {len(users)} users")

    for user_id in users:
        r1 = calculate_implicit_ratings(user_id)
        save_ratings(user_id, r1, "implicit")

        r2 = calculate_implicit_ratings_with_decay(user_id)
        save_ratings(user_id, r2, "implicit_w")

    print("DONE.")


if __name__ == "__main__":
    main()
