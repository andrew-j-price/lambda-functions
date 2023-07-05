import os
import sys
from unittest.mock import patch, MagicMock
from lambda_function import lambda_handler, lambda_runtime_information, random_task_message


def test_lambda_handler():
    response = lambda_handler()
    assert isinstance(response, str)


@patch("logging.info")
@patch("random.randint")
def test_random_task_message(mock_randint, mock_info):
    mock_logging_info = MagicMock()
    mock_randint.return_value = 3
    mock_info.side_effect = mock_logging_info
    result = random_task_message()
    mock_info.assert_called()
    assert isinstance(result, str)


@patch.dict(os.environ, {"AWS_REGION": "eu-fake-3", "AWS_LAMBDA_FUNCTION_NAME": "mock_name"})
@patch("logging.info")
@patch("logging.debug")
@patch("boto3.client")
def test_lambda_runtime_information(mock_client, mock_debug, mock_info):
    mock_logging_info = MagicMock()
    mock_logging_debug = MagicMock()
    mock_boto3_client = MagicMock()
    mock_info.side_effect = mock_logging_info
    mock_debug.side_effect = mock_logging_debug
    mock_client.return_value = mock_boto3_client
    mock_boto3_client.get_function_configuration.return_value = {"Role": "mock_role"}
    lambda_runtime_information()
    mock_client.assert_called_once_with("lambda")
    mock_boto3_client.get_function_configuration.assert_called_once_with(
        FunctionName=os.environ["AWS_LAMBDA_FUNCTION_NAME"]
    )
    mock_debug.assert_called_with("lambda_config: {'Role': 'mock_role'}")


def test_python_version():
    assert sys.version_info[0] == 3
