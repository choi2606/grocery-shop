from fastapi import APIRouter
from neighborhood_based_recommender import GroceryItemRecommender

router = APIRouter()

rec = GroceryItemRecommender()

@router.get("/recommend")
def recommend(user_id: str, num: int = 6):
    results = rec.recommend_items(user_id, num=num)
    ids = [item[0] for item in results]
    return {"product_ids": ids}

@router.get("/recommend/related")
def recommend_related(product_id: str, num: int = 100):
    ids = rec.get_related_items(product_id, num=num)
    return {"product_ids": ids}