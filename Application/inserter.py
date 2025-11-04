from sqlalchemy.dialects.mysql import insert
from models import Weather
from db_client import get_db


def insert_weather_data(db, weather_data):
    stmt = insert(Weather).values(**weather_data)
    stmt = stmt.on_duplicate_key_update(
    temperature=stmt.inserted.temperature,
    humidity=stmt.inserted.humidity,
    description=stmt.inserted.description,
    wind_speed=stmt.inserted.wind_speed,
    timestamp=stmt.inserted.timestamp
)
    db.execute(stmt)
    db.commit()