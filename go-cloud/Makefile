.PHONY: help run-server run-cli test lint build clean examples

# 默认目标：显示帮助
help:
	@echo "go-cloud 项目 Makefile"
	@echo ""
	@echo "用法: make <target>"
	@echo ""
	@echo "开发相关:"
	@echo "  run-server    启动 Web 服务"
	@echo "  run-cli       运行 CLI 工具"
	@echo "  test          运行所有测试"
	@echo "  test-cover    运行测试并生成覆盖率报告"
	@echo "  lint          代码静态检查"
	@echo "  build         编译所有二进制"
	@echo "  clean         清理构建产物"
	@echo ""
	@echo "学习沙盒:"
	@echo "  example-basics       运行基础语法示例"
	@echo "  example-concurrency  运行并发模式示例"
	@echo "  example-advanced     运行高级特性示例"
	@echo "  examples             运行所有示例"

# ---- 开发命令 ----

run-server:
	@echo "启动 Web 服务..."
	go run ./cmd/server

run-cli:
	@echo "运行 CLI..."
	go run ./cmd/cli $(ARGS)

test:
	go test ./...

test-cover:
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "覆盖率报告: coverage.html"

lint:
	golangci-lint run ./...

build:
	go build -o bin/server ./cmd/server
	go build -o bin/cli ./cmd/cli
	@echo "构建完成: bin/server, bin/cli"

clean:
	rm -rf bin/ coverage.out coverage.html
	@echo "清理完成"

# ---- 学习沙盒 ----

example-basics:
	go run ./examples/01-basics

example-concurrency:
	go run ./examples/02-concurrency

example-advanced:
	go run ./examples/03-advanced

examples: example-basics example-concurrency example-advanced

# ---- 工具安装 ----

tools:
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@echo "开发工具安装完成"
