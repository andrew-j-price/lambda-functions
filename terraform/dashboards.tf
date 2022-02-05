# NOTE: CloudWatch allows 3 free dashboards

resource "aws_cloudwatch_dashboard" "lambda_dashboard" {
  dashboard_name = "LambdaDashboard"
  dashboard_body = <<EOF
{
    "widgets": [
        {
            "height": 6,
            "width": 24,
            "y": 0,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ { "expression": "FILL(METRICS(), LINEAR)", "label": "Trend of", "id": "e1", "region": "us-east-2" } ],
                    [ "LogMetrics", "LambdaHealthCheckPyReturnCode", { "id": "m1", "label": "Return Code" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-2",
                "stat": "Maximum",
                "period": 1,
                "title": "Lambda - HealthCheckPy - ReturnCode",
                "setPeriodToTimeRange": true,
                "yAxis": {
                    "left": {
                        "label": "Return Code"
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ { "expression": "FILL(METRICS(), LINEAR)", "label": "Trend of", "id": "e1" } ],
                    [ "AWS/Lambda", "Errors", "FunctionName", "pass_fail_py", { "id": "m1", "label": "Result" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-2",
                "stat": "Maximum",
                "period": 1,
                "yAxis": {
                    "left": {
                        "label": "Result",
                        "showUnits": false
                    }
                },
                "title": "Lambda - PassFailPy - Results"
            }
        }
    ]
}
EOF
}
