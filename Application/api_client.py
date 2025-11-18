import requests, time
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type
from config import API_BASE_URL, API_KEY, MAX_API_RETRIES, RETRY_BACKOFF_FACTOR, REQUEST_TIMEOUT
from logger_config import logger

class WeatherAPIClient:
    def __init__(self):
        self.base_url = API_BASE_URL
        self.api_key = API_KEY
        self.max_retries = int(MAX_API_RETRIES)
        self.backoff_factor = int(RETRY_BACKOFF_FACTOR)
        self.timeout = int(REQUEST_TIMEOUT)

    def fetch_weather(self, city: str):
        """Fetch weather data for a city from OpenWeatherMap"""
        params = {
            "q": city,
            "appid": API_KEY,
            "units": "metric"
        }

        retries = 1
        while retries <= self.max_retries:
            try: 
                response = requests.get(self.base_url, params=params, timeout=self.timeout)
                if response.status_code == 429:
                    wait_time = self.backoff_factor * (2 ** retries)
                    logger.info(f"Rate limited. Retrying in {wait_time} seconds....")
                    retries += 1
                    continue
                response.raise_for_status()
                logger.info(f"Weather data fetched successfully for {city}")
                return response.json()
            except (requests.RequestException, requests.Timeout) as e:
                wait_time = self.backoff_factor * (2 ** retries)
                logger.error(f"Request failed ({e}). Retrying in {wait_time} seconds...")
                time.sleep(wait_time)
                retries +=1
    
        raise RuntimeError(f"Failed to fetch weather data for {city} after {self.max_retries} retries")