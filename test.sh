#运行M次平均时间
numRuns="10"
#a为积分下限值  --03
a="0.0"
#b为积分上限值
b="3.1415296"
#N自变量切分量
#N="10000000"
N="10000"
#函数1 参数
n1="40"
#函数2 参数
n2="40"
#函数3 参数
n3="30"
a3="10"
#函数4 参数
n4="150"
w4="10"
#函数5 参数
n5="20"
#函数6 参数
n6="30"
a6="10"
#函数7 参数
n7="20"
for numCores in 4 #8 16 32 64
do


    sudo g++  -lm -o omp-mc -fopenmp omp-mc.cpp
    export OMP_NUM_THREADS=${numCores}
    ./omp-mc ${numCores} ${numRuns} ${a} ${b} ${N} ${n1} ${n2} ${n3} ${a3} ${n4} ${w4} ${n5} ${n6} ${a6} ${n7}>>mc-${numCores}.txt #${n4} ${w4}  ${n5}  ${n6} ${a6} ${n7}
    sleep 3
    go build go-mc.go
    export GOMAXPROCS=${numCores}
    ./go-mc ${numCores} ${numRuns} ${a} ${b} ${N} ${n1} ${n2}  ${n3} ${a3} ${n4} ${w4} ${n5} ${n6} ${a6} ${n7}>>mc-${numCores}.txt
    sleep 3
    export JULIA_NUM_THREADS=${numCores}
    julia jl-mc.jl ${numRuns} ${a} ${b} ${N} ${n1} ${n2}  ${n3} ${a3} ${n4} ${w4} ${n5} ${n6} ${a6} ${n7}>>mc-${numCores}.txt
: <<'COMMENT'
    export JULIA_NUM_THREADS=${numCores}
    julia jl-mc-threads.jl ${numCores} ${numRuns} ${a} ${b} ${N} ${n1} ${n2}  ${n3} ${a3}>>mc-${numCores}.txt
    julia a.jl  ${numRuns} ${a} ${b} ${N} ${n1} ${n2}  ${n3} ${a3} ${n4} ${w4} ${n5} ${n6} ${a6} ${n7}>>mc-${numCores}.txt
COMMENT
done
