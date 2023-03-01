//@Title	omp-mc.cpp 
//@Description	基于OpenMP模式的C++实现蒙特卡洛积分的并行计算
//@Author	张奥男
//@Update	张奥男
#include <iostream>
#include <omp.h>
#include <math.h>
#include <random> 
#include <cmath>
#include <stdlib.h>
using namespace std;
/* 全局变量 */
static double jc(double n); 
// 积分抽象接口 定义了 Func 函数和积分区间
class Integration 
{
public:
   // 提供接口框架的纯虚函数
   virtual double Func(double x) = 0;
   /*double Func(double x){
	cout<<"-----积累-------------";
	return 0;};*/
	double Func1(double x){
		return Func(x);
	}
	
   void seta(double startPiont)
   {
      a = startPiont;
   }
   void setb(double endPiont)
   {
      b = endPiont;
   }
   void setn(int  fn)
   {
      n = fn;
   }
public:
   double a;//积分上限
   double b;//积分下限
   int n;
};
// Calc1 实现了Integration接口-函数1计算器
class Calc1: public Integration
{
public:
	Calc1(double startPiont,double endPiont,int  fn){
 		a = startPiont;
		b = endPiont;
		n = fn;
	}
   double Func(double x)
   { 
		//cout<<1<<endl;
		double result = 0.0;
		for(int j=0;j<=n;j++){
				result += pow(x,j);
		}
		return result;
   }
};
//Calc2 实现了Integration接口-函数2计算器
class Calc2: public Integration
{
public:
	Calc2(double startPiont,double endPiont,int  fn){
 		a = startPiont;
		b = endPiont;
		n = fn;
	}
   double Func(double x)
   { 
		//cout<<2<<endl;
		//cout<<"a="<<a<<"b="<<b<<"n="<<n<<endl;
		double result = 0.0;
		for(int j=0;j<=n;j++){
			result +=pow(-1,j)*pow(x,j+1)/(j+1);
		}
		return result;
   }
};
// Calc3 实现了Integration接口-函数3计算器
class Calc3: public Integration
{
public:
	double A;
public:
	Calc3(double startPiont,double endPiont,int  fn,double a3){
 		a = startPiont;
		b = endPiont;
		n = fn;
		A = a3;
	}
   double Func(double x)
   {
		double result = 1;
		double num_1;
			for(int j=1;j<=n;j++){
				num_1 = 1;
				for(int k=1;k<=j;k++){
					num_1 *= (A-k+1);
				}
				result +=num_1*pow(x,j)/jc(j);
			}
		return result;
   }
};
// Calc4 实现了Integration接口-函数4计算器
class Calc4: public Integration
{
public:
	double w4;
public:
	Calc4(double startPiont,double endPiont,int  fn,double w){
 		a = startPiont;
		b = endPiont;
		n = fn;
		w4 = w;
	}
   double Func(double x)
   { 
		//cout<<4<<endl;
		double result = 0.0;
		for(int i=1;i<=n;i++){
			result +=cos(i*w4*x)*pow(-1,i)/i*4/3.1415926;
		}
		
		return result;
   }
};
//Calc5 实现了Integration接口-函数5计算器
class Calc5: public Integration
{
public:
	Calc5(double startPiont,double endPiont,int  fn){
 		a = startPiont;
		b = endPiont;
		n = fn;
	}
   double Func(double x)
   { 
		//cout<<5<<endl;
		double result = 0.0;
		for(int i=1;i<=n;i++){
			result +=pow(-1,i)*sin(i*x)*sin(x)/(sin(x)+cos(x));
		}
		return result;
   }
};
// Calc6 实现了Integration接口-函数6计算器
class Calc6: public Integration
{
public:
	double a6;
public:
	Calc6(double startPiont,double endPiont,int  fn,double aa){
 		a = startPiont;
		b = endPiont;
		n = fn;
		a6 = aa;
	}
   double Func(double x)
   { 
		//cout<<6<<endl;
		double result = 0.0;
		for(int i=1;i<=n;i++){
			if(i%2==1){
				result +=pow(a6,i)*sin(i*x)/i;
			}
		}
		return result;
   }
};
//Calc7 实现了Integration接口-函数7计算器
class Calc7: public Integration
{
public:
	Calc7(double startPiont,double endPiont,int  fn){
 		a = startPiont;
		b = endPiont;
		n = fn;
	}
   double Func(double x)
   { 
		//cout<<7<<endl;
		double result = 0.0;
		for(int i=1;i<=n;i++){
			result +=pow(-1,i+1)*cos(i*x)/i;
		}
		return (3.1415926*3.1415926/3)-result;
   }
};
//@title 	parallelMC
//@description 		OpenMP模式实现积分值的并行计算--函数1
//@auth 	张奥男
//@param 	calc  Integration "积分对象地址" 	N int64 "数组长度"  n1 int “函数1 参数n1”
//return 	xp		double		"变量数组指针"
double parallelMC(int N,double * xp,Integration * calc) {
	double ySum = 0.0;
	//cout<<calc->b<<endl;//
	#pragma omp parallel for schedule(dynamic) reduction(+:ySum) 
	for(int i=0;i<N;i++){
		ySum += calc->Func(xp[i]);
	}
	double yMean = ySum / (double)N;
	double integral = (calc->b - calc->a) * yMean;
	//printf("omp-mc-1积分结果=%f\n",integral);
	return integral;
}
//@title jc
//@description  递归计算n的阶乘函数
//@auth 	张奥男
//@param n int  "参数n"
//@return  int n阶乘结果
double jc(double n){
	if(n==0)
	return 1;
	else
	return n*jc(n-1);
}
//@title 	GenRandom
//@description 		根据给定区间，生成一个变量数组
//@auth 	张奥男
//@param 	Integration * calc		"积分对象地址"
//return 	X[]		double		"自变量数组名(指针)"
void GenRandomX(double * X,Integration * calc,int N){
	//uniform_real_distribution<double> u(calc->a, calc->b);
    //default_random_engine e(time(NULL));
	std::random_device rd;  //Will be used to obtain a seed for the random number engine
	std::mt19937 gen(rd()); //Standard mersenne_twister_engine seeded with rd()
	std::uniform_real_distribution<> distrib(calc->a, calc->b); // 指定范围
	for( int i = 0; i < N; i++ ){
		X[i] = distrib(gen);
		//X[i] = (calc->b - calc->a)*(rand()%10000)/10000;
		//X[i] = u(e);
	}
}
int main(int argc,char * argv[])
{
	//命令行参数说明
	/*
	*argv[1]--运行核数
	*argv[2]--指定运行次数，即求运行 numRuns 次的平均值
	 */
	//核数
	int numCores = atoi(argv[1]);
	//函数1 参数
	int numRuns = atoi(argv[2]);
	//积分上下限
	double a= atof(argv[3]);
	double b= atof(argv[4]);
	//自变量个数
	int N = atoi(argv[5]);
	//函数1 参数
	int n1 = atoi(argv[6]);
	//函数2 参数
	int n2 = atoi(argv[7]);
	//函数3 参数
	int n3 = atoi(argv[8]);
	int a3 = atof(argv[9]);
	
	//函数4 参数
	int n4 = atoi(argv[10]);
	double w4 = atof(argv[11]);
	//函数5 参数
	int n5 = atoi(argv[12]);
	//函数6 参数
	int n6 = atoi(argv[13]);
	double a6 = atof(argv[14]);
	//函数7 参数
	int n7 = atoi(argv[15]);
	//定义自变量数组和指针
	/*double X[10000000];
	double *xp  = X;*/
	double *xp  = new double[N];
	//初始化类
	Integration *calc1 = new Calc1(a,b,n1);
	Integration *calc2 = new Calc2(a,b,n2);
	Integration *calc3 = new Calc3(a,b,n3,a3);
	Integration *calc4 = new Calc4(a,b,n4,w4);
	Integration *calc5 = new Calc5(a,b,n5);
	Integration *calc6 = new Calc6(a,b,n6,a6);
	Integration *calc7 = new Calc5(a,b,n7);
	//积分函数都放到一个数组中，Integration接口类型
	//Integration * integrates[] = {calc1,calc2};
	Integration * integrates[] = {calc1,calc2,calc3,calc4,calc5,calc6,calc7};
	//Integration * integrates[] = {calc4,calc5,calc6,calc7};
	//Integration * integrates[] = {calc1,calc4};
	double totalTime= 0;
	double totalResult= 0;
	//cout<<sizeof(integrates) / sizeof(* integrates)<<endl;
	for(int i=0;i<sizeof(integrates) / sizeof(* integrates);i++){
		GenRandomX(xp,integrates[i],N);
		Integration * integrate = integrates[i];
		for(int i=0;i<numRuns;i++) {
			double timeStart = -omp_get_wtime();
			totalResult += parallelMC(N,xp,integrate);
			timeStart += omp_get_wtime();
			totalTime += timeStart; 
		}
		printf("omp-mc-%d核-积分函数%d运行%d次,平均运行时间 =%lf 秒,积分计算平均结果=%lf\n",numCores,i+1, numRuns,totalTime/numRuns,totalResult/numRuns);
		totalTime = 0;
		totalResult = 0.0;
		//cout<<"totalTime=="<<totalTime<<endl;
		//cout<<"totalResult=="<<totalResult<<endl;
	}
    return 0;
}
