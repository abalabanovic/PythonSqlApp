from fastapi import FastAPI, HTTPException, Depends
from api_client import WeatherAPIClient
from data_processor import process
from db_client import get_db
from inserter import insert_weather_data
from sqlalchemy.orm import Session
from sqlalchemy import text
from logger_config import logger
from startup import initialize_database
app = FastAPI()
api_client = WeatherAPIClient()


@app.on_event("startup")
def startup_event():
    initialize_database()
    logger.info("Startup event finished")

@app.get("/fetch_weather/{city}")
def fetch_and_store_weather(city: str, db: Session = Depends(get_db)):
    try:
        raw_data = api_client.fetch_weather(city)
        processed_data = process(raw_data)
        insert_weather_data(db, processed_data)
        return {"status": "success", "city": city, "data": processed_data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
@app.get("/health")
def health_check():
    logger.info("Health check endpoint called")
    return {"status": "alive"}
    
@app.get("/ready")
def readiness_check(db: Session = Depends(get_db)):
    try:
        logger.info("Readiness check endpoint called")
        db.execute(text("SELECT 1"))
        logger.info("Database connection OK")
        return {"status": "ready"}
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        raise HTTPException(status_code=503, detail= "Database not ready")