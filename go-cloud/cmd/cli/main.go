// Package main 是 go-cloud 项目的命令行工具入口。
// 用于测试并发模式、算法和各类 Go 语言特性。
package main

import (
	"fmt"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: cli <command> [args...]")
		fmt.Println("Commands:")
		fmt.Println("  hello    - 打印问候信息")
		fmt.Println("  version  - 显示版本信息")
		os.Exit(1)
	}

	switch os.Args[1] {
	case "hello":
		fmt.Println("Hello from go-cloud CLI! 👋")
	case "version":
		fmt.Println("go-cloud CLI v0.1.0")
	default:
		fmt.Printf("Unknown command: %s\n", os.Args[1])
		os.Exit(1)
	}
}
