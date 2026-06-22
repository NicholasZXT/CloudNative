// 01-basics：Go 基础语法练习
// 包含：变量、控制流、函数、数组/切片、Map、结构体、方法、接口等
package main

import "fmt"

// ---- 结构体与方法 ----

// Person 定义一个人员结构体
type Person struct {
	Name string
	Age  int
}

// Greet 值接收者方法
func (p Person) Greet() string {
	return fmt.Sprintf("Hi, I'm %s, %d years old.", p.Name, p.Age)
}

// Birthday 指针接收者方法（修改原值）
func (p *Person) Birthday() {
	p.Age++
}

// ---- 接口 ----

// Greeter 定义问候接口
type Greeter interface {
	Greet() string
}

// ---- 泛型 ----

// Find 在切片中查找元素，返回索引，未找到返回 -1
func Find[T comparable](slice []T, target T) int {
	for i, v := range slice {
		if v == target {
			return i
		}
	}
	return -1
}

func main() {
	// 变量声明
	var name string = "Go语言"
	version := 1.22
	fmt.Printf("学习 %s v%.2f\n\n", name, version)

	// 切片操作
	nums := []int{1, 2, 3, 4, 5}
	fmt.Println("切片操作:")
	fmt.Printf("  nums = %v, len=%d, cap=%d\n", nums, len(nums), cap(nums))
	fmt.Printf("  nums[1:3] = %v\n", nums[1:3])

	// Map 操作
	scores := map[string]int{"Alice": 95, "Bob": 87}
	fmt.Printf("  scores = %v\n\n", scores)

	// 结构体与方法
	p := Person{Name: "张三", Age: 25}
	fmt.Println("结构体与方法:")
	fmt.Printf("  %s\n", p.Greet())
	p.Birthday()
	fmt.Printf("  生日后: %s\n\n", p.Greet())

	// 接口
	var g Greeter = p
	fmt.Printf("接口调用: %s\n\n", g.Greet())

	// 泛型
	idx := Find(nums, 3)
	fmt.Printf("泛型 Find(nums, 3) = %d\n", idx)
	idx = Find(nums, 99)
	fmt.Printf("泛型 Find(nums, 99) = %d\n", idx)

	// defer 示例
	fmt.Println("\ndefer 示例:")
	defer fmt.Println("  [defer] 这句最后执行")
	fmt.Println("  [normal] 这句先执行")
}
