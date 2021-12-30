# lambda-functions

## sample usage
```golang
module "lambda_functions" {
  source      = "github.com/andrew-j-price/lambda-functions"
  common_tags = merge(local.common_tags, var.global_tags)
  subnet_ids  = [data.terraform_remote_state.core.outputs.private_subnets[0], data.terraform_remote_state.core.outputs.private_subnets[1]]
  vpc_id      = data.terraform_remote_state.core.outputs.vpc_id
}
```

## python function

### health_check_py
```bash
# install packages
cd <dir>
python -m pip install --target . requests

# testing (either command)
python health_check_py/lambda_function.py
docker run -it --rm  -v $(pwd):/git python:3.8-bullseye python /git/health_check_py/lambda_function.py

# styling
black --line-length 120 health_check_py/lambda_function.py 
flake8 --max-line-length 120 health_check_py/lambda_function.py 

# cli v1
aws lambda list-functions
aws lambda invoke --function-name health_check_py health_check_py.log && cat health_check_py.log
aws lambda invoke --function-name health_check_py --payload '{"force_failure": true}' health_check_py.log && cat health_check_py.log

# cli v2 (WIP)
aws lambda invoke --function-name health_check_py --log-type Tail --query 'LogResult' --output text |  base64 -d

# logs
LOG_GROUP='/aws/lambda/health_check_py'
aws logs get-log-events --log-group-name $LOG_GROUP --log-stream-name `aws logs describe-log-streams --log-group-name $LOG_GROUP --max-items 1 --order-by LastEventTime --descending --query logStreams[].logStreamName --output text | head -n 1` --query events[].message --output text

```

### http_handler_py
```bash
# install packages
cd <dir>
# python -m pip install --target . requests

# testing (either command)
python http_handler_py/lambda_function.py
docker run -it --rm  -v $(pwd):/git python:3.8-bullseye python /git/http_handler_py/lambda_function.py

# styling
black --line-length 120 http_handler_py/lambda_function.py 
flake8 --max-line-length 120 http_handler_py/lambda_function.py 

# cli
aws lambda list-functions
aws lambda invoke --function-name http_handler_py http_handler_py.log && cat http_handler_py.log
aws lambda invoke --function-name http_handler_py --log-type Tail --query 'LogResult' --output text |  base64 -d
```

## CloudWatch
Log group
* formatted [/aws/lambda/<<<function_name>>](https://us-east-2.console.aws.amazon.com/cloudwatch/home?region=us-east-2#logsV2:log-groups) created by default with "Never expire" Retention policy
* logs append to unique id based upon deployment

## Terraform Module removal
When removing usage of resources in this module, those resources have to be cleaned up first.
```bash
│ Error: Provider configuration not present
│ 
│ To work with
│ module.lambda_functions.aws_lambda_permission.health_check_py
│ (orphan) its original provider configuration at
│ module.lambda_functions.provider["registry.terraform.io/hashicorp/aws"]
│ is required, but it has been removed. This occurs when a provider
│ configuration is removed while objects created by that provider
│ still exist in the state. Re-add the provider configuration to
│ destroy
│ module.lambda_functions.aws_lambda_permission.health_check_py
│ (orphan), after which you can remove the provider configuration
│ again.
```

```bash
# list all resources
terraform state list

# show resources for this module
for i in `terraform state list | grep module.lambda_function`; do echo $i; done

# delete resources (NOTE: -auto-approve switch not applied below)
terraform destroy -target module.lambda_functions

```
