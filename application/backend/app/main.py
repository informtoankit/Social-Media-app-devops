from fastapi import FastAPI
from app.routers import users, posts, comments, follows

app = FastAPI(title="InstaClone API")

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/ready")
def ready():
    # In real prod this would check DB connectivity too
    return {"status": "ready"}

app.include_router(users.router, prefix="/users", tags=["users"])
app.include_router(posts.router, prefix="/posts", tags=["posts"])
app.include_router(comments.router, prefix="/comments", tags=["comments"])
app.include_router(follows.router, prefix="/follows", tags=["follows"])