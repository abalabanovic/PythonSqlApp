from db_client import engine
from models import Base
from logger_config import logger

def initialize_database():
    try:
        Base.metadata.create_all(bind=engine)
        logger.info("Database schema ensured at startup")
    except Exception as e:
        logger.error(f"Failed to initilize database scehma: {e}")
        raise