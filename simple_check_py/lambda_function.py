import os
import json
import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


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


def actions():
    """Perform the actual work here"""
    print("FUNCTION: actions")
    # raise Exception("A forced error")
    aws_region = os.environ.get("AWS_REGION", "us-fake-3")
    response = requests.get("https://attest.linecas.com/default", verify=False, timeout=5.0)
    print(f"STATUS_CODE: {response.status_code}")
    data = json.loads(response.text)
    message_dict = {
        "attest_container ": data["host_name"],
        "ipv4": get_ipv4(),
        "ipv6": get_ipv6(),
        "region ": aws_region,
        "remote_ip ": data["remote_ip"],

    }
    return message_dict

def get_ipv4():
    print("FUNCTION: get_ipv4")
    try:
        response = requests.get("http://whatismyip.akamai.com/", verify=False, timeout=2.0)
        if response.status_code == 200:
            return response.text
    except Exception as e:
        print(f"Error: {repr(e)}")
        return None

def get_ipv6():
    print("FUNCTION: get_ipv6")
    try:
        response = requests.get("http://ipv6.whatismyip.akamai.com/", verify=False, timeout=2.0)
        if response.status_code == 200:
            return response.text
    except Exception as e:
        print(f"Error: {repr(e)}")
        return None

def result_generator(status_code, message_dict):
    """Returns the response to the lambda call

    Args:
        status_code (int): of HTTP status code, either 200 or 500
        message_dict (dict): of the resulting response

    Returns:
        dict: of response
    """
    print("FUNCTION: result_generator")
    print(f"ANALYSIS: status_code is of type: {type(status_code)} and message_dict is of type: {type(message_dict)}")
    result = {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": message_dict,
    }
    print(f"RESULT: {result}")
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
        message_dict = actions()
        response = result_generator(200, message_dict)
    except Exception as e:
        print(f"Error: {repr(e)}")
        response = result_generator(500, {"error": f"{repr(e)}"})
    finally:
        if context:
            print(
                "CONTEXT: Lambda time remaining in MS:",
                context.get_remaining_time_in_millis(),
            )
        return response


def lambda_handler(event, context):
    """Entry point for lambda"""
    response = main(event, context)
    return response


if __name__ == "__main__":
    """Entry point for local testing"""
    main()
