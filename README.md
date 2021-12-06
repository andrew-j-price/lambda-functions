# lambda-functions

## python function
```bash
# install packages
cd <dir>
python -m pip install --target . requests

# testing
python simple_check_py/lambda_function.py
docker run -it --rm  -v $(pwd):/git python:3.8-bullseye python /git/simple_check_py/lambda_function.py

# styling
black simple_check_py/lambda_function.py 
flake8 simple_check_py/lambda_function.py 

# cli
aws lambda list-functions
aws lambda invoke --function-name simple_check_py simple_check_py.log && cat simple_check_py.log
aws lambda invoke --function-name simple_check_py --log-type Tail --query 'LogResult' --output text |  base64 -d
```

## CloudWatch
Log group
* formatted [/aws/lambda/<<<function_name>>](https://us-east-2.console.aws.amazon.com/cloudwatch/home?region=us-east-2#logsV2:log-groups) created by default with "Never expire" Retention policy
* logs append to unique id based upon deployment
