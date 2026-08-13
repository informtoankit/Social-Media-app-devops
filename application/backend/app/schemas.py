from pydantic import BaseModel, EmailStr

class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str

class UserOut(BaseModel):
    id: int
    username: str
    email: EmailStr
    class Config:
        from_attributes = True

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class PostCreate(BaseModel):
    image_url: str
    caption: str = ""

class PostOut(BaseModel):
    id: int
    owner_id: int
    image_url: str
    caption: str
    class Config:
        from_attributes = True

class CommentCreate(BaseModel):
    post_id: int
    text: str

class CommentOut(BaseModel):
    id: int
    post_id: int
    user_id: int
    text: str
    class Config:
        from_attributes = True