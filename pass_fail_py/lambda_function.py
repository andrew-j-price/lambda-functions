import json
import logging
import os
from uuid import uuid4

logging.basicConfig(level=logging.INFO, format="[%(levelname)s][%(funcName)s] %(message)s", force=True)


def lambda_handler(event=None, context=None):
    """Entry point for lambda, simple if/else for returning exceptions testing"""
    print(f"EVENT: {json.dumps(event)}")
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


if __name__ == "__main__":
    """Entry point for local testing"""
    event = {"force_failure": False}
    lambda_handler(event)
