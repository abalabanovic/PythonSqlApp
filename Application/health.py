from fastapi import FastAPI
from sqlalchemy import create_engine
from logger_config import logger
from config import DATABASE_URL

app = FastAPI(title="Weather App Health Check")

def check_db():
    
    try:
        engine = create_engine(DATABASE_URL)
        with engine.connect() as conn:
            conn.execute("SELECT 1")
        return True
    except Exception as e:
        print(f"Database not ready: {e}")
        return False
    
@app.get("/health")
def health_check():
    logger.info("Liveness health check request")
    return {"status": "healthy"}

@app.get("/ready")
def readiness_check():
    logger.info("Readiness health check requested")
    if check_db():
        return {"ready": True}
    return{"ready": False}
