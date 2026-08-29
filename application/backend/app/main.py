from fastapi import FastAPI
from app.routers import users, posts, comments, follows

app = FastAPI(title="InstaClone API")

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/ready")
def ready():
    return {"status": "ready"}

@app.get("/api/health")
def api_health():
    return {"status": "ok"}

app.include_router(users.router, prefix="/api/users", tags=["users"])
app.include_router(posts.router, prefix="/api/posts", tags=["posts"])
app.include_router(comments.router, prefix="/api/comments", tags=["comments"])
app.include_router(follows.router, prefix="/api/follows", tags=["follows"])
