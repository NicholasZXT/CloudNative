// Package config 提供配置加载功能，支持 YAML/TOML/JSON/ENV 等多种配置源。
// 基于 Viper 进行封装，提供类型安全的配置读取。
package config

// Config 应用配置顶层结构
type Config struct {
	Server   ServerConfig   `mapstructure:"server"`
	Database DatabaseConfig `mapstructure:"database"`
}

// ServerConfig HTTP/gRPC 服务配置
type ServerConfig struct {
	Host string `mapstructure:"host"`
	Port int    `mapstructure:"port"`
}

// DatabaseConfig 数据库连接配置
type DatabaseConfig struct {
	DSN          string `mapstructure:"dsn"`
	MaxOpenConns int    `mapstructure:"max_open_conns"`
	MaxIdleConns int    `mapstructure:"max_idle_conns"`
}

// 示例：后续将实现配置加载函数
// func Load(path string) (*Config, error) { ... }
