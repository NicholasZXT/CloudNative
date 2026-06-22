// Package main 是 go-cloud 项目的主 Web 服务入口。
// 提供 RESTful API 和 gRPC 服务，用于学习 Go Web 开发与云原生应用开发。
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	mux := http.NewServeMux()

	// 健康检查端点
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprint(w, `{"status":"ok"}`)
	})

	addr := ":8080"
	log.Printf("Server starting on %s", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
