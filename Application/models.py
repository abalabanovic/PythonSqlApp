from sqlalchemy import Column, Integer, String, DateTime, Numeric, Index
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

class Weather(Base):
    __tablename__ = "weather_data"

    id = Column(Integer, primary_key=True, autoincrement=True)
    city = Column(String(100), nullable=False)
    temperature = Column(Numeric(5,2), nullable=False)
    humidity = Column(Integer, nullable=False)
    description = Column(String(255))
    wind_speed = Column(Numeric(5,2))
    timestamp = Column(DateTime, nullable=False)

    __table_args__ = (
        Index('idx_unique_weather', city, timestamp, unique=True),
    )