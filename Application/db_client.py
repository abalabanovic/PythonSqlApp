from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from config import DATABASE_URL
from logger_config import logger

engine = create_engine(DATABASE_URL, pool_pre_ping= True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
        db.commit()
        logger.info("Transaction was succesfull (commit).")
    except Exception as e:
        db.rollback()
        logger.error(f"Transaction failed (rollback) because of error: {e}")
        raise e
    finally:
        db.close()
        