from fastapi import FastAPI, HTTPException
from api_client import WeatherAPIClient
from data_processor import process_weather_data
from db_client import get_db
from inserter import insert_weather_data
from sqlalchemy.orm import Session

app = FastAPI()
api_client = WeatherAPIClient()

@app.get("/fetch_weather/{city}")
def fetch_and_store_weather(city: str):
    raw_data = api_client.fetch_weather(city)
    processed_data = process_weather_data(raw_data)
    print(f"Weather data: {processed_data}")

@app.get("/health")
def health_check():
    return {"status": "alive"}
    