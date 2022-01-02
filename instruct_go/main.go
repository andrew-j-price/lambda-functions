package main

import (
	"context"
	"fmt"
	"os"
	"reflect"

	"github.com/aws/aws-lambda-go/lambda"
)

type apiPayload struct {
	Name string `json:"name"`
}

type structPayload struct {
	Name string
}

func handleRequest(ctx context.Context, payload apiPayload) (string, error) {
	message := fmt.Sprintf("Hello %s!", payload.Name)
	fmt.Printf("%s\n", message)
	return message, nil
}

func localJsonRequest(payload apiPayload) (string, error) {
	message := fmt.Sprintf("Hello %s!", payload.Name)
	fmt.Printf("%s\n", message)
	return message, nil
}

func localStructRequest(payload structPayload) (string, error) {
	message := fmt.Sprintf("Hello %s!", payload.Name)
	fmt.Printf("%s\n", message)
	return message, nil
}

func main() {
	localTesting, envVarSet := os.LookupEnv("LOCAL_TESTING")
	if !envVarSet {
		fmt.Printf("envVarSet: is of type: %v, with value: %v\n", reflect.TypeOf(envVarSet), envVarSet)
		// We can assume not local, and call the Lambda Handler
		lambda.Start(handleRequest)
	} else {
		fmt.Printf("localTesting: is of type: %v, with value: %v\n", reflect.TypeOf(localTesting), localTesting)
		localStructPayload := structPayload{"Lucas"}
		localStructRequest(localStructPayload)
		localJsonPayload := apiPayload{"Caroline"}
		localJsonRequest(localJsonPayload)
	}
}
