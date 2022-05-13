package main

import (
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSayHello(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/?subject=abc", nil)
	w := httptest.NewRecorder()
	SayHello(w, req)

	res := w.Result()
	defer res.Body.Close()
	data, err := ioutil.ReadAll(res.Body)
	if err != nil {
		t.Errorf("expected error to be nil got %v", err)
	}

	assert.Equal(t, "Goodbye abc!", string(data))
}
