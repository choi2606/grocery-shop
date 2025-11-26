import sqlite3
import pandas as pd
import logging
from tqdm import tqdm
from sklearn.metrics.pairwise import cosine_similarity
from scipy.sparse import coo_matrix
from datetime import datetime

DB_PATH = "recommendation1.sqlite3"   # giống implicit_ratings

logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s',
                    level=logging.DEBUG)
logger = logging.getLogger("Grocery Item Similarity")


# ==========================================
# CONNECT SQLITE
# ==========================================
conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

# similarity table
cursor.execute("""
CREATE TABLE IF NOT EXISTS similarity (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created TEXT,
    source TEXT,
    target TEXT,
    similarity REAL
)
""")
conn.commit()


# ==========================================
# LOAD RATINGS (FROM SQLITE)
# ==========================================
def load_all_ratings(min_ratings=1):
    query = """
        SELECT user_id, product_id, rating
        FROM analytics_rating
    """
    df = pd.read_sql_query(query, conn)

    # bỏ user nào có quá ít interaction
    user_count = df.groupby("user_id").count()
    valid_users = user_count[user_count["product_id"] > min_ratings].index
    df = df[df["user_id"].isin(valid_users)]

    df["rating"] = df["rating"].astype(float)
    return df


# ==========================================
# NORMALIZATION
# ==========================================
def normalize(x):
    x = x.astype(float)
    x_sum = x.sum()
    x_num = x.astype(bool).count()
    x_mean = x_sum / x_num

    if x_num == 1 or x.std() == 0:
        return 0.0

    return (x - x_mean) / (x.max() - x.min())


# ==========================================
# SAVE SIMILARITY TO SQLITE
# ==========================================
def save_similarity(sm, index_dict, min_sim, min_overlap):
    logger.info("Saving similarities to SQLite...")

    cursor.execute("DELETE FROM similarity")
    conn.commit()

    coo = coo_matrix(sm)
    csr = coo.tocsr()

    xs, ys = coo.nonzero()
    total = len(xs)

    batch = []
    saved = 0
    created = datetime.now().isoformat()

    for x, y in tqdm(zip(xs, ys), total=total):
        if x == y:
            continue

        sim = float(csr[x, y])

        if sim < min_sim:
            continue

        batch.append((created, index_dict[x], index_dict[y], sim))
        saved += 1

        if len(batch) >= 10000:
            cursor.executemany(
                "INSERT INTO similarity (created, source, target, similarity) VALUES (?, ?, ?, ?)",
                batch
            )
            conn.commit()
            batch = []

    if batch:
        cursor.executemany(
            "INSERT INTO similarity (created, source, target, similarity) VALUES (?, ?, ?, ?)",
            batch
        )
        conn.commit()

    logger.info(f"Saved {saved} similarity rows.")


# ==========================================
# BUILD SIMILARITY
# ==========================================
def build_item_similarity(min_overlap=20, min_sim=0.0):
    logger.info("Loading ratings...")
    ratings = load_all_ratings()

    if ratings.empty:
        logger.error("No ratings found!")
        return

    logger.info(f"Calculating similarity using {len(ratings)} ratings")

    ratings["avg"] = ratings.groupby("user_id")["rating"].transform(normalize)

    ratings["user_id"] = ratings["user_id"].astype("category")
    ratings["product_id"] = ratings["product_id"].astype("category")

    coo_m = coo_matrix(
        (
            ratings["avg"].astype(float),
            (ratings["product_id"].cat.codes, ratings["user_id"].cat.codes)
        )
    )

    logger.info("Calculating overlap...")
    overlap_matrix = (
        coo_m.astype(bool).astype(int)
        .dot(coo_m.transpose().astype(bool).astype(int))
    )

    logger.info("Calculating cosine similarity...")
    cor = cosine_similarity(coo_m, dense_output=False)

    cor = cor.multiply(cor > min_sim)
    cor = cor.multiply(overlap_matrix > min_overlap)

    index_dict = dict(enumerate(ratings["product_id"].cat.categories))

    logger.info("Saving similarity...")
    save_similarity(cor, index_dict, min_sim, min_overlap)

    logger.info("DONE.")
    return cor, index_dict


# ==========================================
# MAIN
# ==========================================
if __name__ == "__main__":
    build_item_similarity(min_overlap=3, min_sim=0.2)
