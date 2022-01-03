import json
import logging
import os
from uuid import uuid4

logging.basicConfig(level=logging.INFO, format="[%(levelname)s][%(funcName)s] %(message)s", force=True)


def actions(event):
    """Simple if/else statement to raise exception or return dictionary"""
    condition = event.get("force_failure")
    if condition and isinstance(condition, bool):
        raise Exception("A failure from the force has occurred")
    else:
        response = {
            "region": os.environ.get("AWS_REGION", "us-fake-3"),
            "uuid": str(uuid4()),
        }
        print(f"RESPONSE: {json.dumps(response)}")
        return response


def lambda_handler(event=None, context=None):
    """Entry point for lambda, simple try/except/finally with return and raise values"""
    print(f"EVENT: {json.dumps(event)}")
    try:
        response = actions(event)
        return response
    except Exception as e:
        logging.debug(f"Exception: {e}")
        raise
    finally:
        pass


if __name__ == "__main__":
    """Entry point for local testing"""
    event = {"force_failure": False}
    lambda_handler(event)
