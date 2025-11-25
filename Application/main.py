from fastapi import FastAPI, HTTPException, Depends
from api_client import WeatherAPIClient
from data_processor import process
from db_client import get_db
from inserter import insert_weather_data
from sqlalchemy.orm import Session
from sqlalchemy import text
from logger_config import logger
from startup import initialize_database
from prometheus_client import Counter, generate_latest
from starlette.responses import Response

app = FastAPI()
api_client = WeatherAPIClient()

REQUEST_COUNT = Counter(
    "weather_requests_total",
    "Total number of external weather API calls"
)

@app.on_event("startup")
def startup_event():
    initialize_database()
    logger.info("Startup event finished")

@app.get("/fetch_weather/{city}")
def fetch_and_store_weather(city: str, db: Session = Depends(get_db)):
    try:
        REQUEST_COUNT.inc()
        logger.info(f"Increased connection number for {city}")
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
    
@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type="text/plain")