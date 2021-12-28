import json
import logging
import os
from uuid import uuid4

logging.basicConfig(level=logging.INFO, format="[%(levelname)s][%(funcName)s] %(message)s")


def log_event_context(event, context):
    """Prints out information on lambda invoked functions"""
    print("FUNCTION: log_event_context")
    if event:
        print(f"EVENT: event is of type: {type(event)} and data: {event}")
    if context:
        print(f"CONTEXT: context is of type: {type(context)} and data: {context}")
        print("CONTEXT: CloudWatch log group name:", context.log_group_name)
        print("CONTEXT: CloudWatch log stream name:", context.log_stream_name)
        print("CONTEXT: Lambda function ARN:", context.invoked_function_arn)
        print("CONTEXT: Lambda Request ID:", context.aws_request_id)
        print("CONTEXT: Lambda function memory limits in MB:", context.memory_limit_in_mb)


def actions(event):
    """Perform the actual work here"""
    print("FUNCTION: actions")
    aws_region = os.environ.get("AWS_REGION", "us-fake-3")
    message_dict = {
        "region": aws_region,
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
    print("FUNCTION: response_generator")
    logging.debug(f"status_code is of type: {type(status_code)} and message_dict is of type: {type(message_dict)}")
    result = {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(message_dict),
        "isBase64Encoded": False,
    }
    return result


def main(event=None, context=None):
    """The main function that calls other functions

    Args:
        event (dict): Incoming payload
        context (...): AWS Lambda context

    Returns:
        dict: of response
    """
    print("FUNCTION: main")
    try:
        log_event_context(event, context)
        message_dict = actions(event)
        response = response_generator(200, message_dict)
    except Exception as e:
        print(f"Error: {repr(e)}")
        response = response_generator(500, {"error": f"{repr(e)}"})
    finally:
        if context:
            print(
                "CONTEXT: Lambda time remaining in MS:",
                context.get_remaining_time_in_millis(),
            )
        print(f"RESPONSE: {response}")
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
