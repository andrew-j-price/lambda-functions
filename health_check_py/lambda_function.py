import debugpy
import json
import logging
import os
import requests
import urllib3

logging.basicConfig(level=logging.INFO, format="[%(levelname)s][%(funcName)s] %(message)s", force=True)
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class LambdaHandler:
    def __init__(self):
        self.return_code = 0

    def log_event_context(self, event, context):
        """Logs information on invoked Lambda function"""
        if event:
            logging.info(f"EVENT: event is of type: {type(event)} and data: {event}")
        if context:
            logging.info(f"CONTEXT: context is of type: {type(context)} and data: {context}")
            logging.info(f"CONTEXT: Client context: {context.client_context}")
            logging.info(f"CONTEXT: CloudWatch log group name: {context.log_group_name}")
            logging.info(f"CONTEXT: CloudWatch log stream name: {context.log_stream_name}")
            logging.info(f"CONTEXT: Function ARN: {context.invoked_function_arn}")
            logging.info(f"CONTEXT: Function memory limits in MB: {context.memory_limit_in_mb}")
            logging.info(f"CONTEXT: Function name: {context.function_name}")
            logging.info(f"CONTEXT: Function version: {context.function_version}")
            logging.info(f"CONTEXT: Request ID: {context.aws_request_id}")

    def get_attest(self):
        """Health check to API endpoint

        Returns:
            string: of container name, otherwise None
        """
        try:
            attest_base_url = os.environ.get("ATTEST_BASE_URL", "http://127.0.0.1:5005")
            response = requests.get(f"{attest_base_url}/default", verify=True, timeout=3.0)
            logging.info(f"STATUS_CODE: {response.status_code}")
            if response.status_code == 200 and "host_name" in response.text:
                data = json.loads(response.text)
                return data["host_name"]
            else:
                logging.error(f"RESPONSE_TEXT: {response.text}")
                self.return_code = 2
        except Exception as e:
            logging.error(f"EXCEPTION: {str(e)}")
            self.return_code = 3
        return None

    def get_force_failure(self, event):
        """Used for testing purposes to send a payload and trigger a failure

        Args:
            event (dict): Incoming payload

        Returns:
            bool: if event payload was set
        """
        condition = event.get("force_failure")
        if condition and isinstance(condition, bool):
            self.return_code = 13
            return True
        else:
            return False

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
            logging.error(f"EXCEPTION: {str(e)}")
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
            logging.error(f"EXCEPTION: {str(e)}")
            # NOTE: expected to fail, therefore commenting out
            # self.return_code = 6
        return None

    def actions(self, event):
        """Calls other functions and aggregates results

        Args:
            event (dict): Incoming payload

        Returns:
            dict: of desired output
        """
        all_results = {
            "attest_container": self.get_attest(),
            "force_failure": self.get_force_failure(event),
            "ipv4": self.get_ipv4(),
            "ipv6": self.get_ipv6(),
            "region": os.environ.get("AWS_REGION", "us-fake-3"),
            "return_code": self.return_code,
        }
        debugpy.breakpoint()
        return all_results

    def main(self, event=None, context=None):
        """The main function that controls flow and error handling

        Args:
            event (dict): Incoming payload
            context (LambdaContext): AWS Lambda context
        """
        try:
            self.log_event_context(event, context)
            response = self.actions(event)
        except Exception as e:
            logging.error(f"EXCEPTION: {str(e)}")
            self.return_code = 1
            response = {"exception": str(e), "return_code": self.return_code}
        finally:
            if context:
                logging.info(f"CONTEXT: Lambda time remaining in MS: {context.get_remaining_time_in_millis()}")
            if self.return_code == 0:
                logging.info(f"RETURN_CODE: {self.return_code}")
                logging.info(f"RESPONSE: {json.dumps(response)}")
            else:
                logging.error(f"RETURN_CODE: {self.return_code}")
                logging.error(f"RESPONSE: {json.dumps(response)}")
            # print(json.dumps(response))
            # NOTE: need double quotes from json.dumps
            # NOTE: printing only response not necessary for JSON CloudWatch Filter Patterns
            # NOTE: return does not have to use json.dumps
            debugpy.breakpoint()
            return response


def lambda_handler(event, context):
    """Entry point for lambda"""
    lh = LambdaHandler()
    response = lh.main(event, context)
    return response


if __name__ == "__main__":
    """Entry point for local testing"""
    lh = LambdaHandler()
    event = {"force_failure": False}
    lh.main(event)
