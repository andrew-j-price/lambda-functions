import json
import sys
from lambda_function import actions, response_generator


def test_actions_success():
    event = {"queryStringParameters": {"something": "else"}}
    response = actions(event)
    assert isinstance(response, dict)
    assert response.get("name") == "lucas"
    assert response.get("region") == "us-fake-3"
    assert "region" in response
    assert "uuid" in response


def test_respoonse_generator_success():
    message_dict = {"name": "jack", "region": "unit-test-1"}
    response = response_generator(200, message_dict)
    assert isinstance(response, dict)
    assert response.get("statusCode") == 200
    assert response.get("isBase64Encoded") is False
    assert response.get("body") == json.dumps({"name": "jack", "region": "unit-test-1"})


def test_python_version():
    assert sys.version_info[0] == 3
    assert sys.version_info[1] == 8
