package main

import "testing"

func TestLocalJsonRequest(t *testing.T) {
	localJsonPayload := apiPayload{"Bill"}
	got, _ := localJsonRequest(localJsonPayload)
	want := "Hello Bill!"

	if got != want {
		t.Errorf("got %v, wanted %v", got, want)
	}
}

func TestLocalStructRequest(t *testing.T) {
	localStructPayload := structPayload{"Bob"}
	got, _ := localStructRequest(localStructPayload)
	want := "Hello Bob!"

	if got != want {
		t.Errorf("got %v, wanted %v", got, want)
	}
}
