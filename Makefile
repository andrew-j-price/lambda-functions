SHELL := /bin/bash

start: build

# docker
build:
	docker-compose build && \
	docker-compose up -d

down:
	docker-compose down --remove-orphans

rebuild_py:
	docker build --tag="pyfunctions" ./docker/pyfunctions/ && \
	docker-compose stop pyfunctions && \
	docker-compose build pyfunctions && \
	docker-compose up -d pyfunctions

exec_py:
	docker-compose exec pyfunctions bash


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
