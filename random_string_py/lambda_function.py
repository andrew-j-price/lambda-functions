import boto3
import logging
import os
import random
from faker import Faker

logging.basicConfig(level=logging.INFO, format="[%(levelname)s][%(funcName)s] %(message)s", force=True)


def lambda_runtime_information():
    """Debug function to log information about Lambda configuration"""
    logging.debug("Get Lambda Function Configuration")
    lambda_client = boto3.client("lambda")
    lambda_config = lambda_client.get_function_configuration(FunctionName=os.environ["AWS_LAMBDA_FUNCTION_NAME"])
    logging.debug(f"lambda_config: {lambda_config}")
    logging.info(f"Using Lambda role: {lambda_config['Role']}")


def random_task_message():
    """Generate a random task message string"""
    random_number = random.randint(2, 7)
    word_list = Faker().words(random_number)
    task = " ".join(word_list)
    task = task.capitalize()
    logging.info(f"Message: {task}")
    return task


def lambda_handler(event=None, context=None):
    """Entry point for Lambda"""
    if context:  # context would exist in Lambda but not local testing.
        lambda_runtime_information()
    return random_task_message()


if __name__ == "__main__":
    """Entry point for local testing"""
    event = {}
    lambda_handler(event)
