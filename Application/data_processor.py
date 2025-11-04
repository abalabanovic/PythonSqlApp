from typing import Dict
from logger_config import logger

class WeatherDataProcessor:
    """
    Processes raw weather data from OpenWeatherMap API
    and prepares it for insertion into the database.
    """

    def process(self, raw_data: Dict) -> Dict:
        """
        Transform and validate raw weather JSON from API.
        Returns a dictionary ready for database insertion.
        """
        try:
            processed = {
                "city": raw_data.get("name"),
                "lat": raw_data.get("coord", {}).get("lat"),
                "lon": raw_data.get("coord", {}).get("lon"),
                "temperature": raw_data.get("main", {}).get("temp"),
                "feels_like": raw_data.get("main", {}).get("feels_like"),
                "temp_min": raw_data.get("main", {}).get("temp_min"),
                "temp_max": raw_data.get("main", {}).get("temp_max"),
                "pressure": raw_data.get("main", {}).get("pressure"),
                "humidity": raw_data.get("main", {}).get("humidity"),
                "description": raw_data.get("weather", [{}])[0].get("description"),
                "wind_speed": raw_data.get("wind", {}).get("speed"),
                "wind_deg": raw_data.get("wind", {}).get("deg"),
                "clouds": raw_data.get("clouds", {}).get("all"),
                "timestamp": raw_data.get("dt")
            }

            for key, value in processed.items():
                if value is None:
                    logger.error(f"Missing value for '{key}' in weather data")
                    raise ValueError(f"Missing value for '{key}' in weather data")
                
            logger.info(f"Weather data processed successfully for {processed['city']}")
            return processed
    
        except (KeyError, TypeError, ValueError) as e:
            logger.error(f"Failed to process weather data: {e}")
            raise

