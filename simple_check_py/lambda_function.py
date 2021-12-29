import json
import logging
import os
import requests
import sys
import urllib3

logging.basicConfig(level=logging.INFO, format="[%(levelname)s][%(funcName)s] %(message)s", force=True)
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class LambdaHandler:
    def __init__(self):
        self.return_code = 0

    def log_event_context(self, event, context):
        """Logs information on lambda invoked functions"""
        if event:
            logging.info(f"EVENT: event is of type: {type(event)} and data: {event}")
        if context:
            logging.info(f"CONTEXT: context is of type: {type(context)} and data: {context}")
            logging.info(f"CONTEXT: CloudWatch log group name: {context.log_group_name}")
            logging.info(f"CONTEXT: CloudWatch log stream name: {context.log_stream_name}")
            logging.info(f"CONTEXT: Lambda function ARN: {context.invoked_function_arn}")
            logging.info(f"CONTEXT: Lambda Request ID: {context.aws_request_id}")
            logging.info(f"CONTEXT: Lambda function memory limits in MB: {context.memory_limit_in_mb}")

    def get_attest(self):
        """Health check to API endpoint

        Returns:
            string: of container name, otherwise None
        """
        try:
            # TODO: get URL from environment variable
            response = requests.get("https://attest.linecas.com/default", verify=True, timeout=3.0)
            logging.info(f"STATUS_CODE: {response.status_code}")
            if response.status_code == 200 and "host_name" in response.text:
                data = json.loads(response.text)
                return data["host_name"]
            else:
                logging.error(f"RESPONSE_TEXT: {response.text}")
                self.return_code = 2
        except Exception as e:
            logging.error(f"Exception: {repr(e)}")
            self.return_code = 3
        return None

    def get_ipv4(self):
        """Gets IPv4 source address

        Returns:
            string: of IP address, otherwise None
        """
        try:
            response = requests.get("http://whatismyip.akamai.com/", verify=False, timeout=3.0)
            logging.info(f"STATUS_CODE: {response.status_code}")
            if response.status_code == 200:
                return response.text
            else:
                logging.error(f"RESPONSE_TEXT: {response.text}")
                self.return_code = 4
        except Exception as e:
            logging.error(f"Exception: {repr(e)}")
            self.return_code = 4
        return None

    # NOTE: could combine with above function, but decided not to for now
    def get_ipv6(self):
        """Gets IPv6 source address

        Returns:
            string: of IP address, otherwise None
        """
        try:
            response = requests.get("http://ipv6.whatismyip.akamai.com/", verify=False, timeout=3.0)
            logging.info(f"STATUS_CODE: {response.status_code}")
            if response.status_code == 200:
                return response.text
            else:
                logging.error(f"RESPONSE_TEXT: {response.text}")
                # NOTE: expected to fail, therefore commenting out
                # self.return_code = 6
        except Exception as e:
            logging.error(f"Exception: {repr(e)}")
            # NOTE: expected to fail, therefore commenting out
            # self.return_code = 6
        return None

    def actions(self):
        """Calls other functions and logs desired task output"""
        aws_region = os.environ.get("AWS_REGION", "us-fake-3")
        all_results = {
            "attest_container": self.get_attest(),
            "ipv4": self.get_ipv4(),
            "ipv6": self.get_ipv6(),
            "region": aws_region,
            "return_code": self.return_code,
        }
        return all_results

    def main(self, event=None, context=None):
        """The main function that controls flow and error handling

        Args:
            event (dict): Incoming payload
            context (...): AWS Lambda context
        """
        try:
            self.log_event_context(event, context)
            response = self.actions()
        except Exception as e:
            logging.error(f"Exception: {repr(e)}")
            self.return_code = 1
            response = f"Error: {repr(e)}"
        finally:
            if context:
                logging.info(f"CONTEXT: Lambda time remaining in MS: {context.get_remaining_time_in_millis()}")
            logging.info(f"return_code: {self.return_code}")
            logging.info(f"response: {response}")
            return response


def lambda_handler(event, context):
    """Entry point for lambda"""
    lh = LambdaHandler()
    response = lh.main(event, context)
    return response


if __name__ == "__main__":
    """Entry point for local testing"""
    lh = LambdaHandler()
    lh.main()
