SHELL := /bin/bash

start: build

# docker
build:
	docker-compose build && \
	docker-compose up -d

down:
	docker-compose down --remove-orphans

ci_build_gofunctions:
	docker-compose build gofunctions && \
	docker-compose up -d gofunctions

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

exec_go:
	docker-compose exec gofunctions bash

exec_py:
	docker-compose exec pyfunctions bash


# function:instruct_go
function_instruct_go: instruct_go_docker_test line_breaks1 instruct_go_docker_build line_breaks2 instruct_go_docker_run_directory

instruct_go_docker_run_directory:
	docker-compose exec -T gofunctions bash -c "cd instruct_go && go run . --debug"

instruct_go_docker_build:
	docker-compose exec -T gofunctions bash -c "cd instruct_go && CGO_ENABLED=0 go build -o handler"

instruct_go_docker_run_artifact:
	docker-compose exec -T gofunctions bash -c "cd instruct_go && ./handler"

instruct_go_docker_test:
	docker-compose exec -T gofunctions bash -c "cd instruct_go && go test -v -cover"

instruct_go_local_run_directory:
	cd instruct_go && go run . --debug

instruct_go_local_build_artifact:
	cd instruct_go && CGO_ENABLED=0 go build -o handler

instruct_go_local_run_artifact:
	./instruct_go/handler

instruct_go_local_test:
	cd instruct_go && go test -v -cover


# function:health_check_py
function_health_check_py: health_check_py_run line_breaks1 health_check_py_test line_breaks2 health_check_py_black_check line_breaks3 health_check_py_flake8

health_check_py_run:
	docker-compose exec -T pyfunctions python /git/health_check_py/lambda_function.py

health_check_py_test:
	docker-compose exec -T pyfunctions pytest --verbose /git/health_check_py/test_lambda_function.py

health_check_py_black_apply:
	docker-compose exec -T pyfunctions black --line-length 120 /git/health_check_py/lambda_function.py && \
	docker-compose exec -T pyfunctions black --line-length 120 /git/health_check_py/test_lambda_function.py

health_check_py_black_check:
	docker-compose exec -T pyfunctions black --check --line-length 120 /git/health_check_py/lambda_function.py && \
	docker-compose exec -T pyfunctions black --check --line-length 120 /git/health_check_py/test_lambda_function.py

health_check_py_flake8:
	docker-compose exec -T pyfunctions flake8 --max-line-length 120 /git/health_check_py/lambda_function.py && \
	docker-compose exec -T pyfunctions flake8 --max-line-length 120 /git/health_check_py/test_lambda_function.py

health_check_py_debugpy:
	docker-compose exec -T pyfunctions python -m debugpy --listen 0.0.0.0:5678 --wait-for-client /git/health_check_py/lambda_function.py


# function:http_handler_go
function_http_handler_go: http_handler_go_docker_build line_breaks1 http_handler_go_docker_run_directory

http_handler_go_docker_run_directory:
	docker-compose exec -T gofunctions bash -c "cd http_handler_go && go run . --debug"

http_handler_go_docker_build:
	docker-compose exec -T gofunctions bash -c "cd http_handler_go && CGO_ENABLED=0 go build -o handler"

http_handler_go_api:
	cd ~/code/iaas/terraform/aws-integrations && curl "`terraform output -raw api_gw_base_url`/hi?name=jack"


# function:http_handler_py
function_http_handler_py: http_handler_py_run line_breaks1 http_handler_py_test line_breaks2 http_handler_py_black_check line_breaks3 http_handler_py_flake8

http_handler_py_run:
	docker-compose exec -T pyfunctions python /git/http_handler_py/lambda_function.py

http_handler_py_test:
	docker-compose exec -T pyfunctions pytest --verbose /git/http_handler_py/test_lambda_function.py

http_handler_py_black_apply:
	docker-compose exec -T pyfunctions black --line-length 120 /git/http_handler_py/lambda_function.py && \
	docker-compose exec -T pyfunctions black --line-length 120 /git/http_handler_py/test_lambda_function.py

http_handler_py_black_check:
	docker-compose exec -T pyfunctions black --check --line-length 120 /git/http_handler_py/lambda_function.py && \
	docker-compose exec -T pyfunctions black --check --line-length 120 /git/http_handler_py/test_lambda_function.py

http_handler_py_flake8:
	docker-compose exec -T pyfunctions flake8 --max-line-length 120 /git/http_handler_py/lambda_function.py && \
	docker-compose exec -T pyfunctions flake8 --max-line-length 120 /git/http_handler_py/test_lambda_function.py

http_handler_py_api:
	cd ~/code/iaas/terraform/aws-integrations && curl "`terraform output -raw api_gw_base_url`/hello?name=jack"


# function:pass_fail_py
function_pass_fail_py: pass_fail_py_run line_breaks1 pass_fail_py_test line_breaks2 pass_fail_py_black_check line_breaks3 pass_fail_py_flake8

pass_fail_py_run:
	docker-compose exec -T pyfunctions python /git/pass_fail_py/lambda_function.py

pass_fail_py_test:
	docker-compose exec -T pyfunctions pytest --verbose /git/pass_fail_py/test_lambda_function.py

pass_fail_py_black_apply:
	docker-compose exec -T pyfunctions black --line-length 120 /git/pass_fail_py/lambda_function.py && \
	docker-compose exec -T pyfunctions black --line-length 120 /git/pass_fail_py/test_lambda_function.py

pass_fail_py_black_check:
	docker-compose exec -T pyfunctions black --check --line-length 120 /git/pass_fail_py/lambda_function.py && \
	docker-compose exec -T pyfunctions black --check --line-length 120 /git/pass_fail_py/test_lambda_function.py

pass_fail_py_flake8:
	docker-compose exec -T pyfunctions flake8 --max-line-length 120 /git/pass_fail_py/lambda_function.py && \
	docker-compose exec -T pyfunctions flake8 --max-line-length 120 /git/pass_fail_py/test_lambda_function.py


# terraform
terraform_validation: terraform_init terraform_validate

terraform_init:
	docker-compose exec -T deployer bash -c "cd terraform && terraform init"

terraform_validate:
	docker-compose exec -T deployer bash -c "cd terraform && terraform validate"


# helpers
line_breaks1:
	printf "\n\n"

line_breaks2:
	printf "\n\n"

line_breaks3:
	printf "\n\n"

line_breaks4:
	printf "\n\n"
