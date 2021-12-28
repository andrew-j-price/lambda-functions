import json
import logging
import os
import requests
import sys
import urllib3

logging.basicConfig(level=logging.INFO, format="[%(levelname)s][%(funcName)s] %(message)s")
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class LambdaHandler:
    def __init__(self):
        self.system_exit = 0

    def log_event_context(self, event, context):
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

    def get_attest(self):
        """Health check to API endpoint

        Returns:
            string: of container name, otherwise None
        """
        print("FUNCTION: get_attest")
        try:
            # TODO: get URL from environment variable
            response = requests.get("https://attest.linecas.com/default", verify=True, timeout=3.0)
            print(f"STATUS_CODE: {response.status_code}")
            if response.status_code == 200 and "host_name" in response.text:
                data = json.loads(response.text)
                return data["host_name"]
            else:
                print(f"RESPONSE_TEXT: {response.text}")
                self.system_exit = 2
        except Exception as e:
            print(f"Error: {repr(e)}")
            self.system_exit = 3
        return None

    def get_ipv4(self):
        """Gets IPv4 source address

        Returns:
            string: of IP address, otherwise None
        """
        print("FUNCTION: get_ipv4")
        try:
            response = requests.get("http://whatismyip.akamai.com/", verify=False, timeout=3.0)
            print(f"STATUS_CODE: {response.status_code}")
            if response.status_code == 200:
                return response.text
            else:
                print(f"RESPONSE_TEXT: {response.text}")
                self.system_exit = 4
        except Exception as e:
            print(f"Error: {repr(e)}")
            self.system_exit = 4
        return None

    # NOTE: could combine with above function, but decided not to for now
    def get_ipv6(self):
        """Gets IPv6 source address

        Returns:
            string: of IP address, otherwise None
        """
        print("FUNCTION: get_ipv6")
        try:
            response = requests.get("http://ipv6.whatismyip.akamai.com/", verify=False, timeout=3.0)
            print(f"STATUS_CODE: {response.status_code}")
            if response.status_code == 200:
                return response.text
            else:
                print(f"RESPONSE_TEXT: {response.text}")
                # self.system_exit = 6
        except Exception as e:
            print(f"Error: {repr(e)}")
            # NOTE: expected to fail, therefore commenting out
            # self.system_exit = 6
        return None

    def actions(self):
        """Calls other functions and logs desired task output"""
        print("FUNCTION: actions")
        aws_region = os.environ.get("AWS_REGION", "us-fake-3")
        all_results = {
            "attest_container": self.get_attest(),
            "ipv4": self.get_ipv4(),
            "ipv6": self.get_ipv6(),
            "region": aws_region,
        }
        print(all_results)
        return all_results

    def main(self, event=None, context=None):
        """The main function that controls flow and error handling

        Args:
            event (dict): Incoming payload
            context (...): AWS Lambda context
        """
        print("FUNCTION: main")
        try:
            self.log_event_context(event, context)
            response = self.actions()
        except Exception as e:
            print(f"Error: {repr(e)}")
            self.system_exit = 1
            response = f"Error: {repr(e)}"
        finally:
            if context:
                print(
                    "CONTEXT: Lambda time remaining in MS:",
                    context.get_remaining_time_in_millis(),
                )
            print(f"EXIT_CODE: {self.system_exit}")
            return response
            # sys.exit(self.system_exit)


def lambda_handler(event, context):
    """Entry point for lambda"""
    lh = LambdaHandler()
    response = lh.main(event, context)
    return response


if __name__ == "__main__":
    """Entry point for local testing"""
    lh = LambdaHandler()
    lh.main()
