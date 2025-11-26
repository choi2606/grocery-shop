from fastapi import FastAPI
from logging_api import router as logging_router
from recommender_api import router as rec_router

app = FastAPI()

app.include_router(logging_router)
app.include_router(rec_router)


# uvicorn main:app --reload --port 6969