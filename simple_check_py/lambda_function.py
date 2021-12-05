import os
import json
import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def lambda_handler(event, context):
    print(f"EVENT: {event}")
    print(f"CONTEXT: {context}")
    aws_region = os.environ.get("AWS_REGION", "us-fake-3")
    '''
    response = requests.get(
        "https://attest.linecas.com/default", verify=False, timeout=30.0
    )
    print(f"STATUS_CODE: {response.status_code}")
    data = json.loads(response.text)
    '''
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
