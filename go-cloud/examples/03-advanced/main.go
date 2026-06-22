// 03-advanced：Go 高级特性练习
// 包含：反射、unsafe、cgo、构建标签、代码生成、性能分析等
package main

import (
	"fmt"
	"reflect"
)

// ---- 1. 反射基础 ----

type Employee struct {
	Name   string `json:"name" validate:"required"`
	Age    int    `json:"age"`
	Salary float64
}

func reflectDemo() {
	e := Employee{Name: "李四", Age: 30, Salary: 15000.0}

	t := reflect.TypeOf(e)
	v := reflect.ValueOf(e)

	fmt.Printf("  类型: %v\n", t.Name())
	fmt.Printf("  字段数: %d\n", t.NumField())

	for i := 0; i < t.NumField(); i++ {
		field := t.Field(i)
		value := v.Field(i)
		jsonTag := field.Tag.Get("json")
		validateTag := field.Tag.Get("validate")
		fmt.Printf("    %s (%s) = %v  [json:%q validate:%q]\n",
			field.Name, field.Type, value, jsonTag, validateTag)
	}
}

// ---- 2. 反射动态调用 ----

func callMethod(obj any, methodName string, args ...any) {
	v := reflect.ValueOf(obj)
	m := v.MethodByName(methodName)
	if !m.IsValid() {
		fmt.Printf("  方法 %s 不存在\n", methodName)
		return
	}

	in := make([]reflect.Value, len(args))
	for i, arg := range args {
		in[i] = reflect.ValueOf(arg)
	}

	results := m.Call(in)
	fmt.Printf("  调用 %s 结果: %v\n", methodName, results[0])
}

type Calculator struct{}

func (c Calculator) Add(a, b int) int { return a + b }
func (c Calculator) Mul(a, b int) int { return a * b }

// ---- 3. 类型断言与类型 switch ----

func typeSwitchDemo(val any) {
	switch v := val.(type) {
	case int:
		fmt.Printf("  int: %d\n", v)
	case string:
		fmt.Printf("  string: %s\n", v)
	case []int:
		fmt.Printf("  []int: %v\n", v)
	case map[string]any:
		fmt.Printf("  map: %v\n", v)
	default:
		fmt.Printf("  unknown type: %T\n", v)
	}
}

// ---- 4. 函数式选项模式 (Functional Options) ----

type Server struct {
	host    string
	port    int
	timeout int
	maxConn int
}

type Option func(*Server)

func WithHost(host string) Option  { return func(s *Server) { s.host = host } }
func WithPort(port int) Option     { return func(s *Server) { s.port = port } }
func WithTimeout(t int) Option     { return func(s *Server) { s.timeout = t } }
func WithMaxConn(n int) Option     { return func(s *Server) { s.maxConn = n } }

func NewServer(opts ...Option) *Server {
	s := &Server{
		host:    "localhost",
		port:    8080,
		timeout: 30,
		maxConn: 100,
	}
	for _, opt := range opts {
		opt(s)
	}
	return s
}

func main() {
	fmt.Println("=== 1. 反射：结构体标签与字段遍历 ===")
	reflectDemo()

	fmt.Println("\n=== 2. 反射：动态方法调用 ===")
	calc := Calculator{}
	callMethod(calc, "Add", 3, 5)
	callMethod(calc, "Mul", 4, 7)

	fmt.Println("\n=== 3. 类型断言与类型 switch ===")
	typeSwitchDemo(42)
	typeSwitchDemo("hello")
	typeSwitchDemo([]int{1, 2, 3})
	typeSwitchDemo(map[string]any{"key": "value"})

	fmt.Println("\n=== 4. 函数式选项模式 ===")
	s1 := NewServer()
	fmt.Printf("  默认配置: host=%s port=%d timeout=%d maxConn=%d\n",
		s1.host, s1.port, s1.timeout, s1.maxConn)

	s2 := NewServer(WithHost("0.0.0.0"), WithPort(9090), WithTimeout(60))
	fmt.Printf("  自定义配置: host=%s port=%d timeout=%d maxConn=%d\n",
		s2.host, s2.port, s2.timeout, s2.maxConn)
}
