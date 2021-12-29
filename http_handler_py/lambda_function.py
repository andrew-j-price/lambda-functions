import json
import logging
import os
from uuid import uuid4

logging.basicConfig(level=logging.INFO, format="[%(levelname)s][%(funcName)s] %(message)s", force=True)


def log_event_context(event, context):
    """Logs information on invoked Lambda function"""
    if event:
        logging.info(f"EVENT: event is of type: {type(event)} and data: {event}")
    if context:
        logging.info(f"CONTEXT: context is of type: {type(context)} and data: {context}")
        logging.info(f"CONTEXT: CloudWatch log group name: {context.log_group_name}")
        logging.info(f"CONTEXT: CloudWatch log stream name: {context.log_stream_name}")
        logging.info(f"CONTEXT: Lambda function ARN: {context.invoked_function_arn}")
        logging.info(f"CONTEXT: Lambda Request ID: {context.aws_request_id}")
        logging.info(f"CONTEXT: Lambda function memory limits in MB: {context.memory_limit_in_mb}")


def actions():
    """Perform the actual work here"""
    message_dict = {
        "region": os.environ.get("AWS_REGION", "us-fake-3"),
        "uuid": str(uuid4()),
    }
    # raise Exception("A forced error")
    return message_dict


def response_generator(status_code, message_dict):
    """Generates the AWS expected response to the Lambda call

    Args:
        status_code (int): of HTTP status code, either 2xx,4xx,5xx
        message_dict (dict): of the resulting response

    Returns:
        dict: of response
    """
    logging.debug(f"status_code is of type: {type(status_code)} and message_dict is of type: {type(message_dict)}")
    result = {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(message_dict),
        "isBase64Encoded": False,
    }
    return result


def main(event=None, context=None):
    """The main function that controls flow and error handling

    Args:
        event (dict): Incoming payload
        context (LambdaContext): AWS Lambda context

    Returns:
        dict: of response
    """
    try:
        log_event_context(event, context)
        message_dict = actions()
        response = response_generator(200, message_dict)
    except Exception as e:
        logging.error(f"EXCEPTION: {str(e)}")
        response = response_generator(500, {"exception": f"{str(e)}"})
    finally:
        if context:
            logging.info(f"CONTEXT: Lambda time remaining in MS: {context.get_remaining_time_in_millis()}")
        logging.info(f"RESPONSE: {response}")
        return response


def lambda_handler(event, context):
    """Entry point for lambda

    Returns:
        dict: of AWS expected HTTP response
    """
    response = main(event, context)
    return response


if __name__ == "__main__":
    """Entry point for local testing"""
    main()
