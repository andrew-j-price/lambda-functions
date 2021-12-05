import os
import json
import requests
import time
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def lambda_handler(event, context):
    print("Lambda function ARN:", context.invoked_function_arn)
    print("CloudWatch log stream name:", context.log_stream_name)
    print("CloudWatch log group name:", context.log_group_name)
    print("Lambda Request ID:", context.aws_request_id)
    print("Lambda function memory limits in MB:", context.memory_limit_in_mb)
    # We have added a 1 second delay so you can see the time remaining in get_remaining_time_in_millis.
    time.sleep(1)
    print("Lambda time remaining in MS:", context.get_remaining_time_in_millis())
    print(f"event is of type: {type(event)} and data: {event}")
    print(f"context is of type: {type(context)} and data: {context}")

    aws_region = os.environ.get("AWS_REGION", "us-fake-3")
    """
    response = requests.get(
        "https://attest.linecas.com/default", verify=False, timeout=30.0
    )
    print(f"STATUS_CODE: {response.status_code}")
    data = json.loads(response.text)
    """
    result = {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "result": json.dumps(
            {
                # "attest_container ": data["host_name"],
                "region ": aws_region,
                # "remote_ip ": data["remote_ip"],
            }
        ),
    }
    print(f"RESULT: {result}")
    return result


if __name__ == "__main__":
    lambda_handler("SOME_EVENT", "SOME_CONEXT")
