from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from jose import jwt
from datetime import datetime, timezone, timedelta
from app.database import get_db
from app import models, schemas
from app.config import settings

router = APIRouter()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

@router.post("/register", response_model=schemas.UserOut)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    existing = db.query(models.User).filter(models.User.email == user.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    hashed = pwd_context.hash(user.password)
    db_user = models.User(username=user.username, email=user.email, hashed_password=hashed)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@router.post("/login")
def login(credentials: schemas.LoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == credentials.email).first()
    if not user or not pwd_context.verify(credentials.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.jwt_expire_minutes)
    token = jwt.encode(
        {"sub": str(user.id), "exp": expire},
        settings.jwt_secret,
        algorithm=settings.jwt_algorithm,
    )
    return {"access_token": token, "token_type": "bearer"}