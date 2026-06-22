// Package model 定义领域模型/实体，是项目中最稳定的核心层。
// 包含数据结构定义、值对象、领域枚举等，不依赖任何外部包。
package model

// User 用户领域模型示例
type User struct {
	ID    int64  `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
}
