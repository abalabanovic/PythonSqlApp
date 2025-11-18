import os
from dotenv import load_dotenv



API_BASE_URL = os.getenv("API_BASE_URL")
API_KEY = os.getenv("API_KEY")
DATABASE_URL = os.getenv("DATABASE_URL")
MAX_API_RETRIES = int(os.getenv("MAX_API_RETRIES"))
RETRY_BACKOFF_FACTOR = float(os.getenv("RETRY_BACKOFF_FACTOR"))
REQUEST_TIMEOUT = int(os.getenv("REQUEST_TIMEOUT"))
