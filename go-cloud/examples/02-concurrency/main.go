// 02-concurrency：Go 并发模式练习
// 包含：goroutine、channel、select、sync 包、context、常见并发模式
package main

import (
	"context"
	"fmt"
	"sync"
	"time"
)

// ---- 1. 基础 goroutine + channel ----

func basicGoroutine() {
	ch := make(chan string)

	go func() {
		time.Sleep(100 * time.Millisecond)
		ch <- "Hello from goroutine!"
	}()

	msg := <-ch
	fmt.Printf("  收到消息: %s\n", msg)
}

// ---- 2. 带缓冲的 channel ----

func bufferedChannel() {
	ch := make(chan int, 3)

	ch <- 1
	ch <- 2
	ch <- 3
	// 缓冲区满，再发送会阻塞（除非有接收者）

	close(ch) // 关闭后仍可读取

	for v := range ch {
		fmt.Printf("  %d ", v)
	}
	fmt.Println()
}

// ---- 3. select 多路复用 ----

func selectDemo() {
	ch1 := make(chan string)
	ch2 := make(chan string)

	go func() {
		time.Sleep(50 * time.Millisecond)
		ch1 <- "from ch1"
	}()
	go func() {
		time.Sleep(100 * time.Millisecond)
		ch2 <- "from ch2"
	}()

	for i := 0; i < 2; i++ {
		select {
		case msg := <-ch1:
			fmt.Printf("  ch1: %s\n", msg)
		case msg := <-ch2:
			fmt.Printf("  ch2: %s\n", msg)
		case <-time.After(200 * time.Millisecond):
			fmt.Println("  timeout!")
		}
	}
}

// ---- 4. sync.WaitGroup ----

func waitGroupDemo() {
	var wg sync.WaitGroup
	results := make([]int, 5)

	for i := 0; i < 5; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			time.Sleep(time.Duration(id*20) * time.Millisecond)
			results[id] = id * id
		}(i)
	}

	wg.Wait()
	fmt.Printf("  并发计算结果: %v\n", results)
}

// ---- 5. sync.Mutex ----

type SafeCounter struct {
	mu    sync.Mutex
	value int
}

func (c *SafeCounter) Inc() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.value++
}

func (c *SafeCounter) Value() int {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.value
}

func mutexDemo() {
	counter := &SafeCounter{}
	var wg sync.WaitGroup

	for i := 0; i < 100; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			counter.Inc()
		}()
	}

	wg.Wait()
	fmt.Printf("  安全计数器: %d\n", counter.Value())
}

// ---- 6. Context 超时控制 ----

func contextDemo() {
	ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancel()

	done := make(chan string)

	go func() {
		time.Sleep(200 * time.Millisecond) // 模拟慢操作
		done <- "work done"
	}()

	select {
	case result := <-done:
		fmt.Printf("  结果: %s\n", result)
	case <-ctx.Done():
		fmt.Printf("  超时取消: %v\n", ctx.Err())
	}
}

// ---- 7. Worker Pool 模式 ----

func workerPoolDemo() {
	const numJobs = 10
	const numWorkers = 3

	jobs := make(chan int, numJobs)
	results := make(chan int, numJobs)

	// 启动 workers
	var wg sync.WaitGroup
	for w := 1; w <= numWorkers; w++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			for job := range jobs {
				fmt.Printf("    worker-%d 处理 job-%d\n", id, job)
				time.Sleep(30 * time.Millisecond)
				results <- job * 2
			}
		}(w)
	}

	// 发送任务
	for j := 1; j <= numJobs; j++ {
		jobs <- j
	}
	close(jobs)

	// 等待 workers 完成
	go func() {
		wg.Wait()
		close(results)
	}()

	// 收集结果
	var output []int
	for r := range results {
		output = append(output, r)
	}
	fmt.Printf("  Worker Pool 结果: %v\n", output)
}

func main() {
	fmt.Println("=== 1. 基础 goroutine + channel ===")
	basicGoroutine()

	fmt.Println("\n=== 2. 带缓冲的 channel ===")
	bufferedChannel()

	fmt.Println("\n=== 3. select 多路复用 ===")
	selectDemo()

	fmt.Println("\n=== 4. sync.WaitGroup ===")
	waitGroupDemo()

	fmt.Println("\n=== 5. sync.Mutex 安全计数器 ===")
	mutexDemo()

	fmt.Println("\n=== 6. Context 超时控制 ===")
	contextDemo()

	fmt.Println("\n=== 7. Worker Pool 模式 ===")
	workerPoolDemo()
}
