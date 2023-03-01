// @Title	mc.go
// @Description	基于fork-jion模式的Golang实现蒙特卡洛积分的并行计算
// @Author	张奥男
// @Update	张奥男
package main

import (
	"fmt"
	"math"
	"math/rand"
	"os"
	"runtime"
	"strconv"
	"time"
)

// Integration	积分接口  定义了 Func 函数
type Integration interface {
	Func(x float64, para Parameter) float64
}

// Parameter  函数所需变量结构体
type Parameter struct {
	a float64
	b float64
	N int
	n int
	A float64 //函数中的参数-α
}

// struct-1，实现了Integration接口
type Calc1 struct {
}

func (ti Calc1) Func(x float64, para Parameter) float64 {
	result := 0.0
	for j := 0; j <= para.n; j++ {
		result += math.Pow(x, float64(j))
	}
	return result
}

// struct-2，实现了Integration接口
type Calc2 struct {
}

func (ti Calc2) Func(x float64, para Parameter) float64 {
	result := 0.0
	for j := 0; j <= para.n; j++ {
		result += math.Pow(float64(-1), float64(j)) * math.Pow(x, float64(j+1)) / float64(j+1)
	}
	return result
}

// struct-3，实现了Integration接口
type Calc3 struct {
}

func (ti Calc3) Func(x float64, para Parameter) float64 {
	result := 1.0
	var num_1 float64
	for j := 1; j <= para.n; j++ {
		num_1 = 1.0
		for k := 1; k <= j; k++ {
			num_1 *= (para.A - float64(k) + 1)
		}
		result += float64(num_1) * math.Pow(x, float64(j)) / jc(float64(j))
	}
	return result
}

// struct-4，实现了Integration接口
type Calc4 struct {
}

func (ti Calc4) Func(x float64, para Parameter) float64 {
	result := 0.0
	for j := 1; j <= para.n; j++ {
		result += math.Cos(float64(j)*para.A*x) * math.Pow(-1, float64(j)) / float64(j) * 4 / 3.1415926
	}
	return result
}

// struct-5，实现了Integration接口
type Calc5 struct {
}

func (ti Calc5) Func(x float64, para Parameter) float64 {
	result := 0.0
	for j := 1; j <= para.n; j++ {
		//result += math.Cos(float64(j)*para.A*x) * math.Pow(-1, float64(j)) / float64(j) * 4 / 3.1415926
		result += math.Pow(-1, float64(j)) * math.Sin(float64(j)*x) * math.Sin(x) / (math.Sin(x) + math.Cos(x))
	}
	return result
}

// struct-6，实现了Integration接口
type Calc6 struct {
}

func (ti Calc6) Func(x float64, para Parameter) float64 {
	result := 0.0
	for j := 1; j <= para.n; j++ {
		if j%2 == 1 {
			result += math.Pow(para.A, float64(j)) * math.Sin(float64(j)*x) / float64(j)
		}
	}
	return result
}

// struct-7，实现了Integration接口
type Calc7 struct {
}

func (ti Calc7) Func(x float64, para Parameter) float64 {
	result := 0.0
	for j := 1; j <= para.n; j++ {

		//result += math.Cos(float64(j)*para.A*x) * math.Pow(-1, float64(j)) / float64(j) * 4 / 3.1415926
		result += math.Pow(float64(-1), float64(j+1)) * math.Cos(float64(j)*x) / float64(j)
	}
	return (3.1415926 * 3.1415926 / 3) - result
}

// @title	parallelMC
// @descroption	 基于fork-jion模式的Golang实现蒙特卡洛积分的并行计算
//
//	根据设定的线程数，将任务平均分配给各个线程处理
//
// @auth	张奥男	（2022/09/27）
// @param	n	int		"任务总数"
// @param	ig Integration	"积分对象"
// @param	a, b float64 	"积分区间"
// @param 	 numWorkers	int		"轻量级线程数"
// @return	float64 "积分结果" error "函数执行信息"
func parallelMC(ig Integration, X []float64, numWorkers int, para Parameter) float64 {
	//设置具有 numWorkers 大小缓冲区的通道
	outCh := make(chan float64, numWorkers)
	// Divide tasks into subtasks of roughly equal size
	chunkSizes, err := splitInt(len(X), numWorkers)
	//fmt.Print(chunkSizes)
	if err != nil {
		return 0
	}
	// create goroutine
	var startIdx, endIdx int
	endIdx = -1
	for _, p := range chunkSizes {
		//计算 每个线程需要处理的区间
		startIdx = endIdx + 1
		endIdx = startIdx + p - 1
		go computeFunc(startIdx, endIdx, outCh, ig, X, para)
	}
	// collect the tasks results-收集任务结果
	result := 0.0
	for i := 0; i < numWorkers; i++ {
		result += <-outCh
	}
	yMean := result / float64(len(X))
	//fmt.Printf("go-mc-1积分结果=%f \n", integral)
	return (para.b - para.a) * yMean
}

// @title computeFunc
// @descroption  轻量级线程实现函数
// @auth 	zhangaonan	(2022/09/27)
// @param	a1 int "子任务积分上限"
// @param	b1   int "子任务积分下限"
// @param	a int "任务积分上限"
// @param	b   int "任务积分下限"
// @param	c 		"通道"
// @param	ig Integration  "积分结构体"
// @param	n1  	"f(x)函数1的参数n"
func computeFunc(a1 int, b1 int, c chan float64, ig Integration, X []float64, para Parameter) {
	result := 0.0
	for i := a1; i <= b1; i++ {
		result = result + ig.Func(X[i], para)
	}
	c <- result
}

// @title splitInt
// @descroption 根据给定任务总数和设置的cpu核数 进行任务分配，返回任务分配int[]数组
// @auth	张奥男	（2022/09/27）
// @param	numPoints	int		"任务总数"
// @param	numChunks	int		"设置的cpu核数"
// @return 	split	[]int		"任务分配表"
//
//	error     			"函数调用信息"
func splitInt(numPoints int, numChunks int) ([]int, error) {
	if numPoints < numChunks {
		return nil, fmt.Errorf("x must be < n - given values are x=%d, n=%d", numPoints, numChunks)
	}
	split := make([]int, numChunks)
	if numPoints%numChunks == 0 {
		for i := 0; i < numChunks; i++ {
			split[i] = numPoints / numChunks
		}
	} else {
		limit := numPoints % numChunks
		for i := 0; i < limit; i++ {
			split[i] = numPoints/numChunks + 1
		}
		for i := limit; i < numChunks; i++ {
			split[i] = numPoints / numChunks
		}
	}
	return split, nil
}

// @title jc
// @description  递归计算n的阶乘函数
// @auth 	张奥男
// @param n   "参数n" float64 "考虑数据过大溢出问题，所以用float64"
// @return  float64 n阶乘结果
func jc(n float64) float64 {
	if n == 0.0 {
		return 1
	} else {
		return n * jc(n-1)
	}

}

// @title 	GenRandomX
// @description 		根据给定区间，生成一个变量数组
// @auth 	张奥男
// @param 	a,b 	float64		"区间上下限"	N int "数组长度"
// return 	X[]		float64		"变量数组"
func GenRandomX(a float64, b float64, N int) []float64 {
	X := make([]float64, N)

	rand.Seed(time.Now().UnixNano())
	for i := 0; i < N; i++ {
		xi := a + rand.Float64()*(b-a)
		X[i] = xi
	}
	return X
}
func main() {
	//命令行参数说明
	/*
	* Args[1]--运行核数
	* Args[2]--指定运行次数，即求运行 numRuns 次的平均值
	* a b 积分上下限
	* Args[5]--N自变量切分量
	 */
	var a float64
	var b float64
	var N int
	var n1 int
	var n2 int
	var n3 int
	var a3 float64
	var n4 int
	var w4 float64
	var n5 int
	var n6 int
	var a6 float64
	var n7 int
	numCores, _ := strconv.Atoi(os.Args[1])
	numRuns, _ := strconv.Atoi(os.Args[2])
	// Args[12]--a为积分下限值
	a, _ = strconv.ParseFloat(os.Args[3], 64)
	b, _ = strconv.ParseFloat(os.Args[4], 64)
	N, _ = strconv.Atoi(os.Args[5])
	//函数1 参数
	n1, _ = strconv.Atoi(os.Args[6])
	//函数2 参数
	n2, _ = strconv.Atoi(os.Args[7])
	//函数3 参数
	n3, _ = strconv.Atoi(os.Args[8])
	a3, _ = strconv.ParseFloat(os.Args[9], 64)
	//函数4 参数
	n4, _ = strconv.Atoi(os.Args[10])
	w4, _ = strconv.ParseFloat(os.Args[11], 64)
	//函数5 参数
	n5, _ = strconv.Atoi(os.Args[12])
	//函数6 参数
	n6, _ = strconv.Atoi(os.Args[13])
	a6, _ = strconv.ParseFloat(os.Args[14], 64)
	//函数7 参数
	n7, _ = strconv.Atoi(os.Args[15])
	// 设置使用多少个线程*/
	//print(numCores, "  ", numRuns, "  ", a, "  ", b, "  ", N, "  ", n1, "  ", n2, "  ", n3, "  ", a3)
	runtime.GOMAXPROCS(numCores)
	// 积分函数都放到一个数组中，Integration接口类型
	integrates := []Integration{Calc1{}, Calc2{}, Calc3{}, Calc4{}, Calc5{}, Calc6{}, Calc7{}}
	// 每个积分函数对应的参数。例如，Calc1{}实例的积分  a=0.0, b=1.0, N=10000
	parameters := []Parameter{{a, b, N, n1, -1}, {a, b, N, n2, -1}, {a, b, N, n3, a3}, {a, b, N, n4, w4}, {a, b, N, n5, -1}, {a, b, N, n6, a6}, {a, b, N, n7, -1}}
	var totalTime int64
	totalTime = 0
	totalResult := 0.0
	for i := 0; i < len(integrates); i++ {
		para := parameters[i]
		X := GenRandomX(para.a, para.b, para.N)
		for j := 0; j < numRuns; j++ {
			timeStart := time.Now()
			result := parallelMC(integrates[i], X, numCores, para)
			totalResult += result
			duration := time.Since(timeStart)
			costTime := duration.Microseconds()
			totalTime += costTime
		}
		fmt.Printf("go-mc-%d核-积分函数%d运行%d次,平均运行时间 =%f秒,积分计算平均结果=%f\n",
			numCores, i+1, numRuns, float64(totalTime)/float64(numRuns*1000000), totalResult/float64(numRuns))
		// 计算完一个积分函数后，清零
		totalTime = 0
		totalResult = 0.0
	}
}
