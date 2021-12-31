import os
import sys
import unittest
from unittest.mock import MagicMock, patch
from lambda_function import lambda_handler, LambdaHandler


@patch.dict(os.environ, {"AWS_REGION": "unit-test-1"})
class TestLambdaHandlerClass(unittest.TestCase):
    def test_class_init(self):
        lh = LambdaHandler()
        assert lh.return_code == 0

    @patch("requests.get")
    def test_get_attest_success(self, mock_req):
        # requests response
        mock_obj = MagicMock()
        mock_obj.status_code = 200
        mock_obj.text = '{"host_name": "abc123", "uri": "/default"}'
        mock_req.return_value = mock_obj
        response = LambdaHandler().get_attest()
        mock_req.assert_called_once()
        assert response == "abc123"

    @patch("requests.get")
    def test_get_attest_failure(self, mock_req):
        mock_req.status_code = 404
        response = LambdaHandler().get_attest()
        mock_req.assert_called_once()
        assert response is None

    def test_get_force_failure_false(self):
        event = {"something": "else"}
        response = LambdaHandler().get_force_failure(event)
        assert response is False

    def test_get_force_failure_true(self):
        event = {"force_failure": True}
        lh = LambdaHandler()
        response = lh.get_force_failure(event)
        assert lh.return_code == 13
        assert response is True

    @patch("lambda_function.LambdaHandler.get_ipv6")
    @patch("lambda_function.LambdaHandler.get_ipv4")
    @patch("lambda_function.LambdaHandler.get_force_failure")
    @patch("lambda_function.LambdaHandler.get_attest")
    def test_actions(self, mock_attest, mock_force, mock_ipv4, mock_ipv6):
        mock_attest.return_value = "abc123"
        mock_force.return_value = False
        mock_ipv4.return_value = "1.2.3.4"
        mock_ipv6.return_value = None
        event = {"unit": "test"}
        response = LambdaHandler().actions(event)
        assert isinstance(response, dict)
        assert response.get("region") == "unit-test-1"
        assert response.get("return_code") == 0
        assert response == {
            "attest_container": "abc123",
            "force_failure": False,
            "ipv4": "1.2.3.4",
            "ipv6": None,
            "region": "unit-test-1",
            "return_code": 0,
        }

    @patch("lambda_function.LambdaHandler.actions")
    def test_main(self, mock_actions):
        mock_actions.return_value = {
            "attest_container": "abc123",
            "force_failure": False,
            "ipv4": "1.2.3.4",
            "ipv6": None,
            "region": "unit-test-1",
            "return_code": 0,
        }
        response = LambdaHandler().main()
        assert isinstance(response, dict)
        assert response.get("region") == "unit-test-1"
        assert response.get("return_code") == 0
        assert response == {
            "attest_container": "abc123",
            "force_failure": False,
            "ipv4": "1.2.3.4",
            "ipv6": None,
            "region": "unit-test-1",
            "return_code": 0,
        }

    @patch("lambda_function.LambdaHandler")
    def test_lambda_handler_entry(self, mock_class):
        lambda_handler(event=None, context=None)
        assert mock_class.called_once_with()

    def test_python_version(self):
        assert sys.version_info[0] == 3
        assert sys.version_info[1] == 8
