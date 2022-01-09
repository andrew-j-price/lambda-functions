# lambda-functions
This is an educational repo based primarily around AWS Lambda
* Serverless functions written in Golang and Python
  * With different styles on error-handling and response messages depending upon integrations
* Custom CloudWatch Logs, Metrics, and Dashboards for service insights
* SNS notification integrations
* API Gateway integration for web publishing
* Packaged as a Terraform module
  * Deployments are integrated with my private IaaS repo
* Testing via GitHub Actions

## module usage
```golang
module "lambda_functions" {
  source          = "github.com/andrew-j-price/lambda-functions//terraform"
  common_tags     = merge(local.common_tags, var.global_tags)
  sns_emails      = ["andrew@example.com"]
  sns_webhook_url = "https://api.example.com/sns"
  subnet_ids      = [data.terraform_remote_state.core.outputs.private_subnets[0], data.terraform_remote_state.core.outputs.private_subnets[1]]
  vpc_id          = data.terraform_remote_state.core.outputs.vpc_id
}
```

## functions
refer to `Makefile` for complete workflows

### health_check_py
```bash
# install packages
cd <dir>
python -m pip install --target . requests

# run locally (either command)
make health_check_py_run
python health_check_py/lambda_function.py
docker run -it --rm -v $(pwd):/git python:3.8-bullseye python /git/health_check_py/lambda_function.py

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

### pass_fail_py
```
# local
python pass_fail_py/lambda_function.py

# remote - success
aws lambda invoke --function-name pass_fail_py pass_fail_py.log && cat pass_fail_py.log

# remote - failure
aws lambda invoke --function-name pass_fail_py --payload '{"force_failure": true}' pass_fail_py.log && cat pass_fail_py.log

```

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
