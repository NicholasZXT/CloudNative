// Package logger 提供统一的日志封装，支持结构化日志、日志级别、多输出目标。
// 基于标准库 log/slog 或第三方库（如 zap）进行封装。
package logger

// Logger 日志接口定义
type Logger interface {
	Debug(msg string, args ...any)
	Info(msg string, args ...any)
	Warn(msg string, args ...any)
	Error(msg string, args ...any)
}

// 示例：后续将实现具体的 Logger
// func New(level string) Logger { ... }
