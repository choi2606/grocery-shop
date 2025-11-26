import sqlite3
from decimal import Decimal
import time


class GroceryItemRecommender:

    def __init__(self, db_path="recommendation1.sqlite3",
                 neighborhood_size=15, min_sim=0.0, max_candidates=100):
        self.db_path = db_path
        self.neighborhood_size = neighborhood_size
        self.min_sim = min_sim
        self.max_candidates = max_candidates

    def _connect(self):
        return sqlite3.connect(self.db_path)

    # -----------------------------
    # GET ALL USER RATINGS
    # -----------------------------
    def _get_user_ratings(self, user_id, limit=100):
        conn = self._connect()
        cur = conn.cursor()

        cur.execute("""
            SELECT product_id, rating
            FROM analytics_rating
            WHERE user_id = ?
            ORDER BY rating DESC
            LIMIT ?
        """, (user_id, limit))

        rows = cur.fetchall()
        conn.close()

        return {row[0]: float(row[1]) for row in rows}

    # -----------------------------
    # GET SIMILAR ITEMS FROM DB
    # -----------------------------
    def _get_candidate_items(self, rated_ids):
        conn = self._connect()
        cur = conn.cursor()

        q = f"""
            SELECT source, target, similarity
            FROM similarity
            WHERE source IN ({','.join(['?']*len(rated_ids))})
              AND similarity > ?
            ORDER BY similarity DESC
            LIMIT ?
        """

        params = list(rated_ids) + [self.min_sim, self.max_candidates]
        cur.execute(q, params)

        rows = cur.fetchall()
        conn.close()
        return rows

    # -----------------------------
    # MAIN API: Recommend items
    # -----------------------------
    def recommend_items(self, user_id, num=6):

        # Lấy danh sách user đã thích/mua/xem
        user_ratings = self._get_user_ratings(user_id)

        if len(user_ratings) == 0:
            return {}

        user_mean = sum(user_ratings.values()) / len(user_ratings)

        # Lấy candidate từ similarity
        candidates = self._get_candidate_items(user_ratings.keys())

        recs = {}

        for source, target, sim in candidates:

            # Không recommend lại item user đã tương tác
            if target in user_ratings:
                continue

            # Gom các item có cùng target để lấy neighborhood
            rated_items = [
                (s, t, sim_val) for (s, t, sim_val) in candidates
                if t == target
            ][:self.neighborhood_size]

            if len(rated_items) < 1:
                continue

            pre = 0
            sim_sum = 0

            for src, tgt, sim_val in rated_items:
                adjusted = Decimal(user_ratings[src] - user_mean)
                pre += Decimal(sim_val) * adjusted
                sim_sum += Decimal(sim_val)

            if sim_sum > 0:
                recs[target] = {
                    "prediction": Decimal(user_mean) + (pre / sim_sum),
                    "sim_items": [src for src, _, _ in rated_items]
                }

        # Sắp xếp giảm dần theo prediction
        sorted_items = sorted(
            recs.items(),
            key=lambda x: -float(x[1]["prediction"])
        )[:num]

        return sorted_items

    # -----------------------------
    # PREDICT A SCORE FOR 1 ITEM
    # -----------------------------
    def predict_score(self, user_id, product_id):

        user_ratings = self._get_user_ratings(user_id)

        # Bỏ chính item đó đi
        if product_id in user_ratings:
            user_ratings.pop(product_id)

        return self.predict_score_by_ratings(product_id, user_ratings)

    def predict_score_by_ratings(self, product_id, rated_ids_dict):

        if len(rated_ids_dict) == 0:
            return 0

        conn = self._connect()
        cur = conn.cursor()

        q = f"""
            SELECT source, similarity
            FROM similarity
            WHERE target = ?
              AND source IN ({','.join(['?']*len(rated_ids_dict))})
            ORDER BY similarity DESC
            LIMIT ?
        """

        params = [product_id] + list(rated_ids_dict.keys()) + [self.max_candidates]
        cur.execute(q, params)

        rows = cur.fetchall()
        conn.close()

        if len(rows) == 0:
            return 0

        top = Decimal(0)
        bottom = Decimal(0)

        for src, sim in rows:
            top += Decimal(sim) * Decimal(rated_ids_dict[src])
            bottom += Decimal(sim)

        if bottom == 0:
            return 0

        return float(top / bottom)
        

    def get_related_items(self, product_id: str, num: int = 6):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()

        cur.execute("""
            SELECT target
            FROM similarity
            WHERE source = ?
            ORDER BY similarity DESC
            LIMIT ?
        """, (product_id, num))

        rows = cur.fetchall()
        conn.close()

        return [r[0] for r in rows]
