
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str = "postgresql://postgres:postgres@localhost:5432/instaclone"
    jwt_secret: str = "change-me-in-prod"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60

    aws_region: str = "ap-south-1"
    s3_bucket: str = "instaclone-dev-images"
    s3_endpoint_url: str | None = None
    aws_access_key_id: str = "minioadmin"
    aws_secret_access_key: str = "minioadmin"

    class Config:
        env_file = ".env"

settings = Settings()
