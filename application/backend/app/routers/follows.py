from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app import models

router = APIRouter()

@router.post("/{follower_id}/follow/{following_id}")
def follow_user(follower_id: int, following_id: int, db: Session = Depends(get_db)):
    if follower_id == following_id:
        raise HTTPException(status_code=400, detail="Cannot follow yourself")
    existing = db.query(models.Follow).filter_by(
        follower_id=follower_id, following_id=following_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Already following")
    db_follow = models.Follow(follower_id=follower_id, following_id=following_id)
    db.add(db_follow)
    db.commit()
    return {"status": "followed"}

@router.delete("/{follower_id}/unfollow/{following_id}")
def unfollow_user(follower_id: int, following_id: int, db: Session = Depends(get_db)):
    follow = db.query(models.Follow).filter_by(
        follower_id=follower_id, following_id=following_id
    ).first()
    if not follow:
        raise HTTPException(status_code=404, detail="Not following")
    db.delete(follow)
    db.commit()
    return {"status": "unfollowed"}