package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"

	_ "github.com/lib/pq"
)

const defaultGreeting = "Hello, world!"

func main() {
	if len(os.Args) < 2 {
		fmt.Println(defaultGreeting)
		return
	}
	switch os.Args[1] {
	case "serve":
		serve()
	case "initdb":
		initdb()
	default:
		fmt.Println(defaultGreeting)
	}
}

func dbConn() (*sql.DB, error) {
	host := os.Getenv("DB_HOST")
	name := os.Getenv("DB_NAME")
	user := os.Getenv("DB_USER")
	return sql.Open("postgres", fmt.Sprintf("host=%s dbname=%s user=%s sslmode=disable", host, name, user))
}

func dbEnabled() bool {
	enabled, _ := strconv.ParseBool(os.Getenv("DB_ENABLE"))
	return enabled
}

func initdb() {
	if !dbEnabled() {
		log.Println("initdb: DB_ENABLE=false, skipping")
		return
	}

	db, err := dbConn()
	if err != nil {
		log.Fatalf("initdb: connect: %v", err)
	}
	defer db.Close()

	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS greetings (
			id       SERIAL PRIMARY KEY,
			language TEXT NOT NULL,
			message  TEXT NOT NULL
		)
	`)
	if err != nil {
		log.Fatalf("initdb: create table: %v", err)
	}

	greetings := [][2]string{
		{"English", "Hello, world!"},
		{"Spanish", "¡Hola, mundo!"},
		{"French", "Bonjour, monde!"},
		{"German", "Hallo, Welt!"},
		{"Arabic", "مرحبا بالعالم!"},
		{"Portuguese", "Olá, mundo!"},

		{"Slovak", "Ahoj, svet!"},
		{"Hindi", "नमस्ते दुनिया!"},
	}

	for _, g := range greetings {
		_, err = db.Exec(
			`INSERT INTO greetings (language, message)
			 SELECT $1, $2 WHERE NOT EXISTS (SELECT 1 FROM greetings WHERE language = $1)`,
			g[0], g[1],
		)
		if err != nil {
			log.Fatalf("initdb: insert %s: %v", g[0], err)
		}
	}

	log.Println("initdb: done.")
}

func serve() {
	if !dbEnabled() {
		http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
			log.Printf("request: %s %s", r.Method, r.URL.Path)
			fmt.Fprint(w, defaultGreeting)
		})

		http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
			fmt.Fprint(w, "OK")
		})

		log.Println("Starting on port 5000 ...")
		log.Fatal(http.ListenAndServe(":5000", nil))
		return
	}

	db, err := dbConn()
	if err != nil {
		log.Fatalf("serve: database connect: %v", err)
	}
	if err := db.Ping(); err != nil {
		log.Fatalf("serve: database unreachable: %v", err)
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("request: %s %s", r.Method, r.URL.Path)
		var msg string
		if err := db.QueryRow(`SELECT message FROM greetings ORDER BY RANDOM() LIMIT 1`).Scan(&msg); err != nil {
			http.Error(w, "failed to fetch greeting from database", http.StatusInternalServerError)
			return
		}
		fmt.Fprint(w, msg)
	})

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		if err := db.Ping(); err != nil {
			http.Error(w, "database unreachable", http.StatusServiceUnavailable)
			return
		}
		fmt.Fprint(w, "OK")
	})

	log.Println("Starting on port 5000 ...")
	log.Fatal(http.ListenAndServe(":5000", nil))
}
