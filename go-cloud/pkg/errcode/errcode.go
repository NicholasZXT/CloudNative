// Package errcode 定义统一错误码体系，支持错误码、错误消息、HTTP 状态码映射。
// 用于规范化 API 错误响应，便于前端统一处理。
package errcode

// ErrCode 统一错误码
type ErrCode struct {
	Code    int    `json:"code"`    // 业务错误码
	Message string `json:"message"` // 错误描述
	HTTP    int    `json:"-"`       // 对应的 HTTP 状态码
}

// Error 实现 error 接口
func (e *ErrCode) Error() string {
	return e.Message
}

// 预定义通用错误码
var (
	OK           = &ErrCode{Code: 0, Message: "success", HTTP: 200}
	ErrInternal  = &ErrCode{Code: 10001, Message: "internal server error", HTTP: 500}
	ErrBadRequest = &ErrCode{Code: 10002, Message: "bad request", HTTP: 400}
	ErrNotFound  = &ErrCode{Code: 10003, Message: "not found", HTTP: 404}
)
