package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"reflect"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

var (
	loggerDebug *log.Logger
	loggerInfo  *log.Logger
)

// The input type and the output type are defined by the API Gateway.
func handleRequest(req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	loggerDebug.Printf("req: is of type: %v, with value: %v\n", reflect.TypeOf(req), req)
	name, ok := req.QueryStringParameters["name"]
	if !ok {
		res := events.APIGatewayProxyResponse{
			StatusCode: http.StatusBadRequest,
		}
		loggerDebug.Printf("RESPONSE: %v", res)
		return res, nil
	}

	res := events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Headers:    map[string]string{"Content-Type": "text/plain; charset=utf-8"},
		Body:       fmt.Sprintf("Hello, %s!\n", name),
	}
	loggerDebug.Printf("RESPONSE: %v", res)
	return res, nil
}

func main() {
	loggerDebug = log.New(os.Stdout, "[DEBUG]", log.Lshortfile)
	loggerInfo = log.New(os.Stdout, "[INFO]", log.Lshortfile)
	_, err := os.LookupEnv("_LAMBDA_SERVER_PORT")
	if !err {
		loggerDebug.Printf("err: is of type: %v, with value: %v\n", reflect.TypeOf(err), err)
		loggerInfo.Printf("Lambda environment variables not detected, nothing to do")
	} else {
		lambda.Start(handleRequest)
	}
}
