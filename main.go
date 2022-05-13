package main

import (
	"fmt"
	"net/http"
	"net/url"
)

func main() {
	handler := http.NewServeMux()
	handler.HandleFunc("/", SayHello)
	http.ListenAndServe(":8080", handler)
}

func SayHello(w http.ResponseWriter, r *http.Request) {
	query, err := url.ParseQuery(r.URL.RawQuery)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		fmt.Fprintf(w, "invalid request")
		return
	}
	subject := query.Get("subject")
	if len(subject) == 0 {
		subject = "world"
	}

	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Hello %s!", subject)
}
