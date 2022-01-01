SHELL := /bin/bash

start: build

# docker
build:
	docker-compose build && \
	docker-compose up -d

down:
	docker-compose down --remove-orphans

ci_build_pyfunctions:
	docker-compose build pyfunctions && \
	docker-compose up -d pyfunctions

ci_build_deployer:
	docker-compose build deployer && \
	docker-compose up -d deployer

rebuild_py:
	docker build --tag="pyfunctions" ./docker/pyfunctions/ && \
	docker-compose stop pyfunctions && \
	docker-compose build pyfunctions && \
	docker-compose up -d pyfunctions

exec_deployer:
	docker-compose exec deployer bash

exec_py:
	docker-compose exec pyfunctions bash


# function:health_check_py
function_health_check_py: run_health_check_py line_breaks1 test_health_check_py line_breaks2 black_check_health_check_py line_breaks3 flake8_health_check_py

run_health_check_py:
	docker-compose exec -T pyfunctions python /git/health_check_py/lambda_function.py

test_health_check_py:
	docker-compose exec -T pyfunctions pytest --verbose /git/health_check_py/test_lambda_function.py

black_apply_health_check_py:
	docker-compose exec -T pyfunctions black --line-length 120 /git/health_check_py/lambda_function.py && \
	docker-compose exec -T pyfunctions black --line-length 120 /git/health_check_py/test_lambda_function.py

black_check_health_check_py:
	docker-compose exec -T pyfunctions black --check --line-length 120 /git/health_check_py/lambda_function.py && \
	docker-compose exec -T pyfunctions black --check --line-length 120 /git/health_check_py/test_lambda_function.py

flake8_health_check_py:
	docker-compose exec -T pyfunctions flake8 --max-line-length 120 /git/health_check_py/lambda_function.py && \
	docker-compose exec -T pyfunctions flake8 --max-line-length 120 /git/health_check_py/test_lambda_function.py


# function:http_handler_py
function_http_handler_py: run_http_handler_py line_breaks1 test_http_handler_py line_breaks2 black_check_http_handler_py line_breaks3 flake8_http_handler_py

run_http_handler_py:
	docker-compose exec -T pyfunctions python /git/http_handler_py/lambda_function.py

test_http_handler_py:
	docker-compose exec -T pyfunctions pytest --verbose /git/http_handler_py/test_lambda_function.py

black_apply_http_handler_py:
	docker-compose exec -T pyfunctions black --line-length 120 /git/http_handler_py/lambda_function.py && \
	docker-compose exec -T pyfunctions black --line-length 120 /git/http_handler_py/test_lambda_function.py

black_check_http_handler_py:
	docker-compose exec -T pyfunctions black --check --line-length 120 /git/http_handler_py/lambda_function.py && \
	docker-compose exec -T pyfunctions black --check --line-length 120 /git/http_handler_py/test_lambda_function.py

flake8_http_handler_py:
	docker-compose exec -T pyfunctions flake8 --max-line-length 120 /git/http_handler_py/lambda_function.py && \
	docker-compose exec -T pyfunctions flake8 --max-line-length 120 /git/http_handler_py/test_lambda_function.py


# function:pass_fail_py
function_pass_fail_py: run_pass_fail_py line_breaks1 test_pass_fail_py line_breaks2 black_check_pass_fail_py line_breaks3 flake8_pass_fail_py

run_pass_fail_py:
	docker-compose exec -T pyfunctions python /git/pass_fail_py/lambda_function.py

test_pass_fail_py:
	docker-compose exec -T pyfunctions pytest --verbose /git/pass_fail_py/test_lambda_function.py

black_apply_pass_fail_py:
	docker-compose exec -T pyfunctions black --line-length 120 /git/pass_fail_py/lambda_function.py && \
	docker-compose exec -T pyfunctions black --line-length 120 /git/pass_fail_py/test_lambda_function.py

black_check_pass_fail_py:
	docker-compose exec -T pyfunctions black --check --line-length 120 /git/pass_fail_py/lambda_function.py && \
	docker-compose exec -T pyfunctions black --check --line-length 120 /git/pass_fail_py/test_lambda_function.py

flake8_pass_fail_py:
	docker-compose exec -T pyfunctions flake8 --max-line-length 120 /git/pass_fail_py/lambda_function.py && \
	docker-compose exec -T pyfunctions flake8 --max-line-length 120 /git/pass_fail_py/test_lambda_function.py


# terraform
terraform: terraform_init terraform_validate

terraform_init:
	docker-compose exec -T deployer terraform init

terraform_validate:
	docker-compose exec -T deployer terraform validate


# helpers
line_breaks1:
	printf "\n\n"

line_breaks2:
	printf "\n\n"

line_breaks3:
	printf "\n\n"

line_breaks4:
	printf "\n\n"
