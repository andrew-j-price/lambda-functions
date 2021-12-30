import pytest
import sys
from lambda_function import actions, lambda_handler


def test_actions_success():
    event = {"something": "random"}
    response = actions(event)
    assert isinstance(response, dict)
    assert "region" in response
    assert "uuid" in response


def test_actions_failure():
    event = {"force_failure": True}
    with pytest.raises(Exception):
        response = actions(event)
        assert isinstance(response, None)


def test_handler_success():
    event = {"something": "random"}
    response = lambda_handler(event)
    assert isinstance(response, dict)
    assert "region" in response
    assert "uuid" in response


def test_handler_failure():
    event = {"force_failure": True}
    with pytest.raises(Exception):
        response = lambda_handler(event)
        assert isinstance(response, None)


def test_python_version():
    assert sys.version_info[0] == 3
    assert sys.version_info[1] == 8
