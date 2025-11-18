from typing import Dict, Any
from logger_config import logger
from datetime import datetime


def process(raw_data: Dict[str, Any]) -> Dict[str, Any]:
    try:

        raw_timestamp = raw_data.get("dt")

        processed = {
            "city": raw_data.get("name"),
            "temperature": raw_data.get("main", {}).get("temp"),
            "humidity": raw_data.get("main", {}).get("humidity"),
            "description": raw_data.get("weather", [{}])[0].get("description"),
            "wind_speed": raw_data.get("wind", {}).get("speed"),
            "timestamp": datetime.fromtimestamp(raw_timestamp) if raw_timestamp is not None else None
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

