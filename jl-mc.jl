using Distributed
using Base.Threads
#------------------------基于Julia 多线程实现 montecarlo积分运算----------------------------

#获取命令行参数说明：
numCores = Threads.nthreads() #cores nums
#print("线程数==",numCores,"\n")
numRuns = parse(Int,ARGS[1])
#积分上下限
a = parse(Float64,ARGS[2])
b = parse(Float64,ARGS[3])
#自变量个数
N = parse(Int,ARGS[4])
#函数1 参数
n1 = parse(Int,ARGS[5])
#函数2 参数
n2 = parse(Int,ARGS[6])
#函数3 参数
n3 = parse(Int,ARGS[7])
a3 = parse(Float64,ARGS[8])
#函数4 参数
n4 = parse(Int,ARGS[9])
w4 = parse(Float64,ARGS[10])
#函数5 参数
n5 = parse(Int,ARGS[11])
#函数6 参数
n6 = parse(Int,ARGS[12])
a6 = parse(Float64,ARGS[13])
#函数7 参数
n7 = parse(Int,ARGS[14])
# @title myfactorial
# @descroption  计算n的阶乘函数//由于类型内存限制 可计算170以内的阶乘
# @auth 	zhangaonan	(2022/10/27)
# @param	N  	Int "自变量个数"
@everywhere function myfactorial(t)
    fact = one(t)
    for m in 1:t
       fact *= m
    end
    fact
end
# @title 	GenRandomX
# @description 		生成一个随机变量数组
# @auth 	张奥男
# @param 	a,b 	float64		"区间上下限"	N int "数组长度"
# return 	randomX[]		float64		"变量数组"
function GenRandomX()
    randomX = Array{Float64}(undef, N)
    for i = 1:length(randomX)
        randomX[i] = a + (b-a) * rand()
    end
    return randomX
end
# @title splitInt
# @descroption 根据给定任务总数和设置的cpu核数 进行任务分配，返回任务分配int[]数组
# @auth	张奥男	（2022/09/27）
# @param	numPoints	int		"任务总数"
# @param	numChunks	int		"设置的cpu核数"
# @return 	split	[]int		"任务分配表: index1的位置存1,index=i，存每段的结尾下标"
#	error     			"函数调用信息"
function splitInt(numPoints::Int, numChunks::Int)
	#split := make([]int, numChunks)
    #split[] = {0,0,0,0}array = Array{Int64}(undef, 3)
    split = Array{Int64}(undef, numChunks+1)
    split[1]=0
	if numPoints%numChunks == 0 

        for i in 1: numChunks
			split[i+1] = (numPoints ÷ numChunks)*i
        end
	else
		limit = numPoints % numChunks
		for j in 1: limit
			split[j+1] = split[j] + numPoints÷numChunks + 1
        end
		for k in limit+1: numChunks 
			split[k+1] = split[k] +numPoints ÷ numChunks
        end
    end
    return split
end
#-----------------------------函数1------------------------------
@everywhere function Calc1(randomX::Array{Float64},split::Array{Int64},i::Int64,a::Float64,b::Float64,n1::Int64)
    result::Float64 = 0.0
    for m in split[i]+1:split[i+1]
        for j in 0:n1
            #result += randomX[m]^j 
        end
        result=result+1
    end
    result
end
function parallelMC1(randomX::Array{Float64})
    split =Array{Int64}(undef, numCores+1)
    split =splitInt(N,numCores)
    
    atomic = Atomic{Float64}(0) #定义原子变量 #则当前线程在对acc进行操作时，别的线程是不能操作的
    
    @threads for i in 1:numCores
        result::Float64 = Calc1(randomX,split,i,a,b,n1)
    atomic_add!(atomic,result)
    end
    ySum::Float64 =  0.0
    ySum = atomic[]
    print("yysunn===========",ySum,"\n")
    yMean::Float64 = ySum / Float64(N)
    result1::Float64 = (b-a)  * yMean
    result1
end
#-----------------------------函数2------------------------------
@everywhere function Calc2(randomX::Array{Float64},split::Array{Int64},i::Int64,a::Float64,b::Float64,n2::Int64)
    result::Float64 = 0.0
        for m in split[i]+1:split[i+1]
            for j in 0:n2
                result += (((-1)^j) * (randomX[m]^(j+1)))/(j+1)
            end
        end
    result
end
function parallelMC2(randomX::Array{Float64})
    split =Array{Int64}(undef, numCores+1)
    split =splitInt(N,numCores)

    atomic = Atomic{Float64}(0) #定义原子变量 #则当前线程在对acc进行操作时，别的线程是不能操作的
    
    @threads for i in 1:numCores
        result::Float64 = Calc2(randomX,split,i,a,b,n2)
    atomic_add!(atomic,result)
    end
    ySum::Float64 =  0.0
    ySum = atomic[]
    yMean::Float64 = ySum / Float64(N)
    result1::Float64 = (b-a)  * yMean
    result1
end
#-----------------------------函数3------------------------------
@everywhere function Calc3(randomX::Array{Float64},split::Array{Int64},i::Int64,a::Float64,b::Float64,n3::Int64,a3::Float64)
    result::Float64 = 0.0
    for m in split[i]+1:split[i+1]
        y::Float64 = 1.0
        for j in 1:n3
            num_1::Float64 = 1
            for k in 1:j
                num_1 *= (a3 - k + 1)
            end
            y += (num_1 * (randomX[m]^j))/myfactorial(j)
        end
        result +=y
    end
    result
end
function parallelMC3(randomX::Array{Float64})
    split =Array{Int64}(undef, numCores+1)
    split =splitInt(N,numCores)
    atomic = Atomic{Float64}(0) #定义原子变量 #则当前线程在对acc进行操作时，别的线程是不能操作的
    @threads for i in 1:numCores
        result::Float64 = Calc3(randomX,split,i,a,b,n3,a3)
    atomic_add!(atomic,result)
    end
    ySum::Float64 =  0.0
    ySum = atomic[]
    yMean::Float64 = ySum / Float64(N)
    result1::Float64 = (b-a)  * yMean
    result1
end
#-----------------------------函数4------------------------------
@everywhere function Calc4(randomX::Array{Float64},split::Array{Int64},i::Int64,a::Float64,b::Float64,n4::Int64,w4::Float64)
    result::Float64 = 0.0
        for m in split[i]+1:split[i+1]
            for j in 1:n4
                result +=cos(randomX[m]*w4*j)*((-1)^j)/j*4/(b-a)
            end
        end
    result
end
function parallelMC4(randomX::Array{Float64})
    split =Array{Int64}(undef, numCores+1)
    split =splitInt(N,numCores)
    atomic = Atomic{Float64}(0) #定义原子变量 #则当前线程在对acc进行操作时，别的线程是不能操作的
    @threads for i in 1:numCores
        result::Float64 = Calc4(randomX,split,i,a,b,n4,w4)
    atomic_add!(atomic,result)
    end
    ySum::Float64 =  0.0
    ySum = atomic[]
    yMean::Float64 = ySum / Float64(N)
    result1::Float64 = (b-a)  * yMean
    result1
end
#-----------------------------函数5------------------------------
@everywhere function Calc5(randomX::Array{Float64},split::Array{Int64},i::Int64,a::Float64,b::Float64,n5::Int64)
    result::Float64 = 0.0
        for m in split[i]+1:split[i+1]
            for j in 1:n5
				result +=((-1)^j)*sin(randomX[m]*j)*sin(randomX[m])/(sin(randomX[m])+cos(randomX[m]))
            end
        end
    result
end
function parallelMC5(randomX::Array{Float64})
    split =Array{Int64}(undef, numCores+1)
    split =splitInt(N,numCores)
    atomic = Atomic{Float64}(0) #定义原子变量 #则当前线程在对acc进行操作时，别的线程是不能操作的
    @threads for i in 1:numCores
        result::Float64 = Calc5(randomX,split,i,a,b,n5)
    atomic_add!(atomic,result)
    end
    ySum::Float64 =  0.0
    ySum = atomic[]
    yMean::Float64 = ySum / Float64(N)
    result1::Float64 = (b-a)  * yMean
    result1
end
#-----------------------------函数6------------------------------
@everywhere function Calc6(randomX::Array{Float64},split::Array{Int64},i::Int64,a::Float64,b::Float64,n6::Int64,a6::Float64)
    result::Float64 = 0.0
        for m in split[i]+1:split[i+1]
            for j in 1:n6
                if  j%2 == 1
                    result +=(a6^j)*sin(j*randomX[m])/j
                end
            end
        end
    result
end
function parallelMC6(randomX::Array{Float64})
    split =Array{Int64}(undef, numCores+1)
    split =splitInt(N,numCores)
    atomic = Atomic{Float64}(0) #定义原子变量 #则当前线程在对acc进行操作时，别的线程是不能操作的
    @threads for i in 1:numCores
        result::Float64 = Calc6(randomX,split,i,a,b,n6,a6)
    atomic_add!(atomic,result)
    end
    ySum::Float64 =  0.0
    ySum = atomic[]
    yMean::Float64 = ySum / Float64(N)
    result1::Float64 = (b-a)  * yMean
    result1
end
#-----------------------------函数7------------------------------
@everywhere function Calc7(randomX::Array{Float64},split::Array{Int64},i::Int64,a::Float64,b::Float64,n7::Int64)
    result::Float64 = 0.0
        for m in split[i]+1:split[i+1]
            for j in 1:n7
				result +=((-1)^(j+1))* cos(j*randomX[m])/j
            end
        end
    result
end
function parallelMC7(randomX::Array{Float64})
    split =Array{Int64}(undef, numCores+1)
    split =splitInt(N,numCores)
    atomic = Atomic{Float64}(0) #定义原子变量 #则当前线程在对acc进行操作时，别的线程是不能操作的
    @threads for i in 1:numCores
        result::Float64 = Calc7(randomX,split,i,a,b,n7)
    atomic_add!(atomic,result)
    end
    ySum::Float64 =  0.0
    ySum = atomic[]
    yMean::Float64 = ySum / Float64(N)
    result1::Float64 = (b-a)  * yMean
    result1
end
random = Array{Float64}(undef, N)
#函数-1-时间测试
function test01()
    sumResult_1 = 0.0
    random = GenRandomX()
    sumTime_1 = @elapsed for i = 1:numRuns
        sumResult_1 +=parallelMC1(random)
    end
    print("jl-mc-",numCores,"核-积分函数1运行",numRuns,"次,平均运行时间 =",sumTime_1/numRuns,"秒,积分计算平均结果=",sumResult_1/numRuns,"\n")
end
#函数-2-时间测试
function test02()
    sumResult_2 = 0.0
    random = GenRandomX()
    sumTime_2 = @elapsed for i = 1:numRuns
        sumResult_2 +=parallelMC2(random)
    end
    print("jl-mc-",numCores,"核-积分函数2运行",numRuns,"次,平均运行时间 =",sumTime_2/numRuns,"秒,积分计算平均结果=",sumResult_2/numRuns,"\n")
end
#函数-3-时间测试
function test03()
    sumResult_3 = 0.0
    random = GenRandomX()
    sumTime_3 = @elapsed for i = 1:numRuns
        sumResult_3 +=parallelMC3(random)
    end
    print("jl-mc-",numCores,"核-积分函数3运行",numRuns,"次,平均运行时间 =",sumTime_3/numRuns,"秒,积分计算平均结果=",sumResult_3/numRuns,"\n")
end
#函数-4-时间测试
function test04()
    sumResult_4 = 0.0
    random = GenRandomX()
    sumTime_4 = @elapsed for i = 1:numRuns
        sumResult_4 +=parallelMC4(random)
    end
    print("jl-mc-",numCores,"核-积分函数4运行",numRuns,"次,平均运行时间 =",sumTime_4/numRuns,"秒,积分计算平均结果=",sumResult_4/numRuns,"\n")
end
#函数-5-时间测试
function test05()
    sumResult_5 = 0.0
    random = GenRandomX()
    #randomX = Array{Float64}(undef, N)
    sumTime_5 = @elapsed for i = 1:numRuns
        sumResult_5 +=parallelMC5(random)
    end
    print("jl-mc-",numCores,"核-积分函数5运行",numRuns,"次,平均运行时间 =",sumTime_5/numRuns,"秒,积分计算平均结果=",sumResult_5/numRuns,"\n")
end
#函数-6-时间测试
function test06()
    sumResult_6 = 0.0
    random = GenRandomX()
    #randomX = Array{Float64}(undef, N)
    sumTime_6 = @elapsed for i = 1:numRuns
        sumResult_6 +=parallelMC6(random)
    end
    print("jl-mc-",numCores,"核-积分函数6运行",numRuns,"次,平均运行时间 =",sumTime_6/numRuns,"秒,积分计算平均结果=",sumResult_6/numRuns,"\n")
end
#函数-7-时间测试
function test07()
    sumResult_7 = 0.0
    random = GenRandomX()
    #randomX = Array{Float64}(undef, N)
    sumTime_7 = @elapsed for i = 1:numRuns
        sumResult_7 +=parallelMC7(random)
    end
    print("jl-mc-",numCores,"核-积分函数7运行",numRuns,"次,平均运行时间 =",sumTime_7/numRuns,"秒,积分计算平均结果=",sumResult_7/numRuns,"\n")
end
test01()
test02()
test03()
test04()
test05()
test06()
test07()