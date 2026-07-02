package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

const message = "Hello, world!"

func main() {
	if len(os.Args) > 1 && os.Args[1] == "serve" {
		serve()
	} else {
		fmt.Println(message)
	}
}

func serve() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, message)
	})
	log.Println("Starting on port 5000 ...")
	log.Fatal(http.ListenAndServe(":5000", nil))
}
